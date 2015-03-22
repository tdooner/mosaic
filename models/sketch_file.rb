class SketchFile < ActiveRecord::Base
  has_many :slices, dependent: :destroy

  scope :in_sync, -> { where(in_sync: true) }

  def self.sync_all
    find_each do |sketch_file|
      Threaded.enqueue(SyncWorker, sketch_file.id)
    end
  end

  private

  class SyncWorker
    def self.call(id)
      sfile = SketchFile.find(id)

      $logger.info 'fetching ' + sfile.dropbox_path

      local_parent_dir = File.join(
        File.expand_path('../../images', __FILE__),
        sfile.dropbox_path.gsub(/\.sketch$/, '').scan(/\w+/)
      )

      $logger.info '  into ' + local_parent_dir

      FileUtils.mkdir_p(local_parent_dir)

      Dir.mktmpdir do |tmp|
        File.open("#{tmp}/download.sketch", 'w') do |f|
          SketchSyncDropbox.with_client do |client|
            sleep Random.rand(10)
            # f.write client.get_file(dropbox_path)
          end
        end

        # TODO: Make this actually do stuff (on mac)
        # `cd #{tmp} && #{APP_PATH}/vendor/sketchtool/bin/sketchtool export slices download.sketch`

        sfile.transaction do
          sfile.slices.delete_all

          # TODO: Uncomment this too
          # files = Dir["**/*.png"]
          files = Dir["/mnt/ssd/tom/dev/ruby/sketch-sync/images/**/*.png"].sample(10)

          files.map do |f|
            # TODO: Uncomment on Mac
            # new_filename = File.join(new_files_path, tokens.join('-') + '.png')
            # FileUtils.mv(file, new_filename)
            new_filename = f.gsub('/mnt/ssd/tom/dev/ruby/sketch-sync', '')
            sfile.slices.create(path: new_filename, layer: f)
          end

          sfile.update_attribute(:in_sync, true)
        end
      end
    rescue => ex
      $logger.error "Syncing image #{sfile.dropbox_path}: #{ex.message}. Retrying..."
      retry
    end
  end
end
