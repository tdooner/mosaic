require 'mixlib/shellout'

class ProcessSketchWorker
  def self.call(id)
    sfile = SketchFile.find(id)

    sfile_directory = sfile.dropbox_path.gsub(/\.sketch$/, '').scan(/\w+/).join('-')
    FileUtils.mkdir_p(File.join('images', sfile_directory))

    $logger.info "[#{id}] fetching #{sfile.dropbox_path} into #{sfile_directory}"

    tmp = Dir.mktmpdir
    metadata = {}

    File.open("#{tmp}/download.sketch", 'w') do |f|
      DropboxWrapper.with_client do |client|
        metadata = client.metadata(sfile.dropbox_path)
        f.write client.get_file(sfile.dropbox_path)
      end
    end

    sketchtool_path = File.expand_path('../../../vendor/sketchtool', __FILE__)
    command_env = { cwd: tmp, timeout: 10 * 60 }

    $logger.info "[#{id}] attempting to determine number of pages/artboards..."
    slice_info = Mixlib::ShellOut.new("#{sketchtool_path}/bin/sketchtool list artboards download.sketch", command_env)
    slice_info.run_command
    slice_info = JSON.parse(slice_info.stdout)

    $logger.info "[#{id}] Exporting #{slice_info['pages'].length} pages"

    pages_export = Mixlib::ShellOut.new("#{sketchtool_path}/bin/sketchtool export pages --formats=png --output=./pages/ download.sketch", command_env)
    pages_export.run_command

    pages_base_path = File.join('images', sfile_directory, 'pages')
    FileUtils.mkdir_p(pages_base_path)
    thumbnail_paths = []

    slice_info['pages'].each do |page_config|
      old_path = File.join(command_env[:cwd], 'pages', page_config['name'] + '.png')
      safe_page_name = page_config['name'].scan(/\w+/).join('-') + '.png'
      new_path = File.join(pages_base_path, safe_page_name)

      unless File.exist?(old_path)
        # TODO: Save this warning into some place that a web-browsing user can
        # see it
        $logger.warn "[#{id}] Duplicate page name in file #{sfile.dropbox_path}: \"#{page_config['name']}\""
        next 
      end

      if page_config['artboards'].length == 0
        $logger.info "[#{id}] No artboards on page #{page_config['name']}. Skipping."
        next
      end
      $logger.info "[#{id}] Exporting #{page_config['artboards'].length} artboards from page #{page_config['name']}"

      artboard_ids = page_config['artboards'].map { |a| a['id'] }
      artboard_export_cmd = "#{sketchtool_path}/bin/sketchtool export artboards --formats=png --items=#{artboard_ids.join(',')} --output=./artboards/ download.sketch"
      $logger.debug 'running export command: ' + artboard_export_cmd

      artboard_export = Mixlib::ShellOut.new(artboard_export_cmd, command_env)
      artboard_export.run_command

      p = SketchPage.new_from_path(page_config, command_env[:cwd])
      p.sketch_file = sfile
      p.sketch_artboards = page_config['artboards'].map do |artboard_config|
        SketchArtboard.new_from_path(artboard_config, command_env[:cwd])
      end

      $logger.debug "[#{id}] moving #{old_path} -> #{new_path}"
      FileUtils.mv(old_path, new_path)
      thumbnail_paths << new_path

      page_config['artboards'].each do |artboard_config|
        old_filename = File.join(command_env[:cwd], 'artboards', artboard_config['name'] + '.png')
        new_filename = artboard_config['name'].scan(/\w+/).join('-') + '.png'
        new_filename_with_path = File.join('images', sfile_directory, new_filename)

        unless File.exist?(old_filename)
          # TODO: Save this warning into some place that a web-browsing user can
          # see it
          $logger.warn "[#{id}] Duplicate artboard name detected on page #{page_config['name']}: \"#{artboard_config['name']}\""
          next 
        end

        FileUtils.mv(old_filename, new_filename_with_path)
        thumbnail_paths << new_filename_with_path
      end

      p.save
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
  rescue => ex
    $logger.error "[#{id}] Error while syncing image #{sfile.dropbox_path}: #{ex.message}."
    require 'pry'; binding.pry
    Threaded.enqueue(self, id)
  ensure
    FileUtils.remove_entry(tmp)
  end
end
