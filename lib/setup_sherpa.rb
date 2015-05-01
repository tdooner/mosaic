class SetupSherpa
  class << self
    def guide_the_user_along_the_dark_mac_os_path!
      make_sure_that_random_setting_is_disabled
    end

    def make_sure_that_random_setting_is_disabled
      setting = `defaults read NSGlobalDomain NSTextShowsControlCharacters`.chomp
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
