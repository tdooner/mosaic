class SetupSherpa
  class << self
    def guide!
      make_sure_that_random_setting_is_disabled
      make_sure_dropbox_credentials_are_good
      check_for_sketchtool
    end

    def check_for_sketchtool
      unless File.executable?(File.expand_path('../../../vendor/sketchtool/bin/sketchtool', __FILE__))
        puts 'You need sketchtool for mosaic to work. Please see the instructions in the readme for installation instructions.'
      end
    end

    def make_sure_dropbox_credentials_are_good
      if !ENV['DROPBOX_APP_KEY'] || ENV['DROPBOX_APP_KEY'] == 'abc1234'
        puts 'You must configure environment variables DROPBOX_APP_KEY and DROPBOX_APP_SECRET.'
        puts ''
        puts 'You can get these credentials by clicking "Create App" here:'
        puts '  https://www.dropbox.com/developers/apps'
        puts ''
        puts "Once you have them, a good place to put them is in your ~/.bashrc, e.g.:"
        puts ''
        puts 'export DROPBOX_APP_KEY=[aaaaaaaaaaaaaaa]'
        puts 'export DROPBOX_APP_SECRET=[bbbbbbbbbbbbbbb]'
        exit 1
      end
    end

    def make_sure_that_random_setting_is_disabled
      setting = `defaults read NSGlobalDomain NSTextShowsControlCharacters 2>/dev/null`.chomp
      if setting == '1'
        $stderr.puts 'WARNING: Your system is configured in a way known to cause sketchtool to hang.'
        $stderr.puts '         Please run the command:'
        $stderr.puts ''
        $stderr.puts '         defaults delete NSGlobalDomain NSTextShowsControlCharacters'
        $stderr.puts ''
        $stderr.puts 'Hit enter to continue:'
        $stdin.gets
      end
    end
  end
end
