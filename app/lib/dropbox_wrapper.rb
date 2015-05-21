require 'dropbox_sdk'

class DropboxWrapper
  class << self
    def with_client
      @client_mutex.synchronize { yield @client }
    end

    def authenticate!(app_key, app_secret)
      if credentials_saved?
        access_token, uid = load_credentials
      end

      while !valid_credentials?(access_token, uid)
        flow = DropboxOAuth2FlowNoRedirect.new(app_key, app_secret)
        auth_url = flow.start
        $stderr.puts 'Go to this URL to authenticate Dropbox:'
        $stderr.puts auth_url
        $stderr.puts ''
        $stderr.write 'Code: '
        code = gets.chomp
        access_token, uid = flow.finish(code)
      end

      @client = DropboxClient.new(access_token)
      @client_mutex = Mutex.new

      save_credentials(access_token, uid)
    end

    private

    def save_credentials(access_token, uid)
      File.open('.dropbox-credentials', 'w', 0600) do |f|
        f.write "#{access_token}\t#{uid}"
      end
    end

    def credentials_saved?
      File.exist?('.dropbox-credentials')
    end

    def load_credentials
      File.read('.dropbox-credentials').split("\t")
    end

    def valid_credentials?(access_token, uid)
      client = DropboxClient.new(access_token)
      client.metadata('/design')
      true
    rescue
      false
    end
  end
end
