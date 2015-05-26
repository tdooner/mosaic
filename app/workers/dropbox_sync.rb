class DropboxSyncWorker
  def self.call
    $logger.info 'Syncronizing with Dropbox...'

    MosaicFile.file_types.each do |extension, klass|
      results = DropboxWrapper.with_client do |client|
        client.search('/design', extension)
      end

      results = results.first(ENV['LIMIT_SYNC'].to_i) if ENV['LIMIT_SYNC']

      $logger.info "found #{results.length} *#{extension} files in Dropbox"
      existing = klass.where(dropbox_path: results.map { |r| r['path'].downcase }).pluck(:id)
      dead = klass.where.not(id: existing)
      $logger.info "Mosaic contains #{dead.length} files that no longer exist"
      dead.destroy_all

      MosaicFile.transaction do
        results.each do |res|
          next if res['bytes'] == 0
          next if res['is_dir']
          next if res['path'] =~ /conflicted copy/

          sfile = klass.where(dropbox_path: res['path'].downcase).first_or_create(dropbox_rev: 'unknown')

          if sfile.dropbox_rev == res['rev']
            sfile.update_attribute(:in_sync, true)
          else
            sfile.enqueue_sync!
          end
        end
      end
    end

    sleep 60

    Threaded.enqueue(self)
  rescue => ex
    $logger.error "Dropbox sync process crashed: #{ex} #{ex.backtrace.join "\n"}"
  end
end
