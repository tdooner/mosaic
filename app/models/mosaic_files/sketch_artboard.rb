require 'mixlib/shellout'

class SketchArtboard < ActiveRecord::Base
  belongs_to :sketch_file

private

  class StartSyncManagerThread
    def self.call
      $logger.info 'Syncronizing with Dropbox...'
      results = SketchSyncDropbox.with_client do |client|
        client.search('/design', '.sketch')
      end

      $logger.info "found #{results.length} *.sketch files in Dropbox"
      alive_files = SketchFile.with_paths(results.map { |r| r['path'] }).pluck(:id)
      dead_files = SketchFile.where.not(id: alive_files)
      $logger.info "Mosaic contains #{dead_files.length} files that no longer exist"
      dead_files.destroy_all

      results.each do |res|
        next if res['bytes'] == 0
        next if res['is_dir']
        next if res['path'] =~ /conflicted copy/

        sfile = SketchFile
                 .with_path(res['path'])
                 .first_or_create(dropbox_rev: 'unknown')

        if sfile.dropbox_rev == res['rev']
          sfile.update_attribute(:in_sync, true)
        else
          Threaded.enqueue(SyncWorker, sfile.id)
        end
      end

      sleep 60

      Threaded.enqueue(self)
    end
  end

  class SyncWorker
    def self.call(id)
      sfile = SketchFile.find(id)

      sfile_directory = sfile.dropbox_path.gsub(/\.sketch$/, '').scan(/\w+/).join('-')
      FileUtils.mkdir_p(File.join('images', sfile_directory))

      $logger.info "[#{id}] fetching #{sfile.dropbox_path} into #{sfile_directory}"

      Dir.mktmpdir do |tmp|
        metadata = {}

        File.open("#{tmp}/download.sketch", 'w') do |f|
          SketchSyncDropbox.with_client do |client|
            metadata = client.metadata(sfile.dropbox_path)
            f.write client.get_file(sfile.dropbox_path)
          end
        end

        sketchtool_path = File.expand_path('../../vendor/sketchtool', __FILE__)
        command_env = { cwd: tmp, timeout: 10 * 60 }

        $logger.info "[#{id}] attempting to determine number of slices..."
        slice_info = Mixlib::ShellOut.new("#{sketchtool_path}/bin/sketchtool list slices download.sketch", command_env)
        slice_info = JSON.parse(slice_info.tap(&:run_command).stdout)
        num_slices = slice_info['pages'].inject(0) do |sum, page|
          sum += page['slices'].length
        end

        $logger.info "[#{id}] ...found #{num_slices} slices"
        if num_slices > 0
          $logger.info "[#{id}] exporting #{num_slices} slices"
          export = Mixlib::ShellOut.new("#{sketchtool_path}/bin/sketchtool export slices download.sketch", command_env)
          export.run_command
        else
          $logger.info "[#{id}] no slices, so exporting the artboard instead"
          export = Mixlib::ShellOut.new("#{sketchtool_path}/bin/sketchtool export artboards download.sketch", command_env)
          export.run_command
        end

        sfile.transaction do
          sfile.slices.delete_all

          files = Dir["#{tmp}/**/*.png"]

          files.map do |f|
            # TODO: Refactor this, there's way too much path munging happening
            # here.
            layer_name = f.gsub("#{tmp}/", '').gsub(/\.png$/, '')
            new_filename = layer_name.scan(/\w+/).join('-') + '.png'
            new_filename_with_path = File.join('images', sfile_directory, new_filename)

            FileUtils.mv(f, new_filename_with_path)

            sfile.slices.create(
              path: '/' + new_filename_with_path,
              layer: layer_name
            )
          end

          sfile.update_attributes(
            in_sync: true,
            dropbox_rev: metadata['rev'],
            last_modified: Time.parse(metadata['modified'])
          )
        end
      end
    rescue => ex
      $logger.error "[#{id}] Error while syncing image #{sfile.dropbox_path}: #{ex.message}."
      Threaded.enqueue(SyncWorker, id)
    end
  end
end
