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
      export = Mixlib::ShellOut.new("#{sketchtool_path}/bin/sketchtool export artboards --formats=png --output=./artboards/ download.sketch", command_env)
      export.run_command

      $logger.info "[#{id}] exporting #{num_pages} pages"
      export = Mixlib::ShellOut.new("#{sketchtool_path}/bin/sketchtool export pages --formats=png --output=./pages/ download.sketch", command_env)
      export.run_command

      slice_info['pages'].each do |page_config|
        p = SketchPage.new_from_path(page_config, command_env[:cwd])

        p.sketch_artboards = page_config['artboards'].map do |artboard_config|
          SketchArtboard.new_from_path(artboard_config, command_env[:cwd])
        end

        p.save
      end

      thumbnail_paths = []

      pages_base_path = File.join('images', sfile_directory, 'pages')
      FileUtils.mkdir_p(pages_base_path)
      slice_info['pages'].each do |page_config|
        old_path = File.join(command_env[:cwd], 'pages', page_config['name'] + '.png')
        safe_page_name = page_config['name'].scan(/\w+/).join('-') + '.png'
        new_path = File.join(pages_base_path, safe_page_name)

        FileUtils.mv(old_path, new_path)
        thumbnail_paths << new_path

        page_config['artboards'].each do |artboard_config|
          old_filename = File.join(command_env[:cwd], 'artboards', artboard_config['name'] + '.png')
          new_filename = artboard_config['name'].scan(/\w+/).join('-') + '.png'
          new_filename_with_path = File.join('images', sfile_directory, new_filename)

          FileUtils.mv(old_filename, new_filename_with_path)
          thumbnail_paths << new_filename_with_path
        end
      end

      thumbnail_paths.each do |path|
        full_path = File.expand_path("../../../#{path}", __FILE__)
        $logger.info 'Creating thumbnail for ' + full_path
        `convert -thumbnail 300 -extent 300x600 #{full_path} #{full_path.gsub('.png', '.thumb.jpg')}`
      end

      sfile.update_attributes(
        in_sync: true,
        dropbox_rev: metadata['rev'],
        last_modified: Time.parse(metadata['modified'])
      )
    end
  rescue => ex
    $logger.error "[#{id}] Error while syncing image #{sfile.dropbox_path}: #{ex.message}."
    Threaded.enqueue(self, id)
  end
end
