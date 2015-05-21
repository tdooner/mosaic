require 'mixlib/shellout'

class ProcessSketchWorker
  def self.call(id)
    sfile = SketchFile.find(id)

    sfile_directory = sfile.dropbox_path.gsub(/\.sketch$/, '').scan(/\w+/).join('-')
    FileUtils.mkdir_p(File.join('images', sfile_directory))

    $logger.info "[#{id}] fetching #{sfile.dropbox_path} into #{sfile_directory}"

    Dir.mktmpdir do |tmp|
      metadata = {}

      File.open("#{tmp}/download.sketch", 'w') do |f|
        DropboxWrapper.with_client do |client|
          metadata = client.metadata(sfile.dropbox_path)
          f.write client.get_file(sfile.dropbox_path)
        end
      end

      sketchtool_path = File.expand_path('../../../vendor/sketchtool', __FILE__)
      command_env = { cwd: tmp, timeout: 10 * 60 }

      $logger.info "[#{id}] attempting to determine number of artboards..."
      slice_info = Mixlib::ShellOut.new("#{sketchtool_path}/bin/sketchtool list artboards download.sketch", command_env)
      slice_info.run_command
      slice_info = JSON.parse(slice_info.stdout)

      num_pages = slice_info['pages'].length
      num_artboards = slice_info['pages'].inject(0) do |sum, page|
        sum += page['artboards'].length
      end

      $logger.info "[#{id}] ...found #{num_artboards} artboards in #{num_pages} pages"
      $logger.info "[#{id}] exporting #{num_artboards} artboards"
      export = Mixlib::ShellOut.new("#{sketchtool_path}/bin/sketchtool export artboards --output=./artboards/ download.sketch", command_env)
      export.run_command

      $logger.info "[#{id}] exporting #{num_pages} pages"
      export = Mixlib::ShellOut.new("#{sketchtool_path}/bin/sketchtool export pages --output=./pages/ download.sketch", command_env)
      export.run_command

      slice_info['pages'].each do |page_config|
        p = SketchPage.new_from_path(page_config, command_env[:cwd])

        p.sketch_artboards = page_config['artboards'].map do |artboard_config|
          SketchArtboard.new_from_path(artboard_config, command_env[:cwd])
        end

        p.save
      end

      slice_info['pages'].each do |page_config|
        # TODO: Process the images here
      end

      # sfile.transaction do
      #   sfile.slices.delete_all

      #   files = Dir["#{tmp}/**/*.png"]

      #   files.map do |f|
      #     # TODO: Refactor this, there's way too much path munging happening
      #     # here.
      #     layer_name = f.gsub("#{tmp}/", '').gsub(/\.png$/, '')
      #     new_filename = layer_name.scan(/\w+/).join('-') + '.png'
      #     new_filename_with_path = File.join('images', sfile_directory, new_filename)

      #     FileUtils.mv(f, new_filename_with_path)

      #     sfile.slices.create(
      #       path: '/' + new_filename_with_path,
      #       layer: layer_name
      #     )
      #   end

      #   sfile.update_attributes(
      #     in_sync: true,
      #     dropbox_rev: metadata['rev'],
      #     last_modified: Time.parse(metadata['modified'])
      #   )
      # end
    end
  rescue => ex
    $logger.error "[#{id}] Error while syncing image #{sfile.dropbox_path}: #{ex.message}."
    Threaded.enqueue(self, id)
  end
end
