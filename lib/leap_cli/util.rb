require 'digest/md5'

module LeapCli

  module Util
    extend self

    ##
    ## QUITTING
    ##

    #
    # quit and print help
    #
    def help!(message=nil)
      ENV['GLI_DEBUG'] = "false"
      help_now!(message)
      #say("ERROR: " + message)
    end

    #
    # quit with a message that we are bailing out.
    #
    def bail!(message="")
      puts(message)
      puts("Bailing out.")
      raise SystemExit.new
      #ENV['GLI_DEBUG'] = "false"
      #exit_now!(message)
    end

    #
    # quit with no message
    #
    def quit!(message='')
      puts(message)
      raise SystemExit.new
    end

    #
    # bails out with message if assertion is false.
    #
    def assert!(boolean, message)
      bail!(message) unless boolean
    end

    #
    # assert that the command is available
    #
    def assert_bin!(cmd_name)
      assert! `which #{cmd_name}`.strip.any?, "Sorry, bailing out, the command '%s' is not installed." % cmd_name
    end

    #
    # assert that the command is run without an error.
    # if successful, return output.
    #
    def assert_run!(cmd, message)
      log2(" * run: #{cmd}")
      cmd = cmd + " 2>&1"
      output = `#{cmd}`
      assert!($?.success?, message)
      return output
    end

    ##
    ## FILES AND DIRECTORIES
    ##

    def relative_path(path)
      path.sub(/^#{Regexp.escape(Path.provider)}\//,'')
    end

    def progress_created(path)
      progress 'created %s' % relative_path(path)
    end

    def progress_updated(path)
      progress 'updated %s' % relative_path(path)
    end

    def progress_nochange(path)
      progress2 'no change %s' % relative_path(path)
    end

    def progress_removed(path)
      progress 'removed %s' % relative_path(path)
    end

    #
    # creates a directory if it doesn't already exist
    #
    def ensure_dir(dir)
      unless File.directory?(dir)
        if File.exists?(dir)
          bail! 'Unable to create directory "%s", file already exists.' % dir
        else
          FileUtils.mkdir_p(dir)
          unless dir =~ /\/$/
            dir = dir + '/'
          end
          progress_created dir
        end
      end
    end

    ##
    ## FILE READING, WRITING, DELETING, and MOVING
    ##

    #
    # All file read and write methods support using named paths in the place of an actual file path.
    #
    # To call using a named path, use a symbol in the place of filepath, like so:
    #
    #   read_file(:known_hosts)
    #
    # In some cases, the named path will take an argument. In this case, set the filepath to be an array:
    #
    #   write_file!([:user_ssh, 'bob'], ssh_key_str)
    #
    # To resolve a named path, use the shortcut helper 'path()'
    #
    #   path([:user_ssh, 'bob'])  ==>   files/users/bob/bob_ssh_pub.key
    #

    def read_file!(filepath)
      filepath = Path.named_path(filepath)
      if !File.exists?(filepath)
        bail!("File '%s' does not exist." % filepath)
      else
        File.read(filepath)
      end
    end

    def read_file(filepath)
      filepath = Path.named_path(filepath)
      if !File.exists?(filepath)
        nil
      else
        File.read(filepath)
      end
    end

    def remove_file!(filepath)
      filepath = Path.named_path(filepath)
      if File.exists?(filepath)
        File.unlink(filepath)
        progress_removed(filepath)
      end
    end

    def write_file!(filepath, contents)
      filepath = Path.named_path(filepath)
      ensure_dir File.dirname(filepath)
      existed = File.exists?(filepath)
      if existed
        if file_content_equals?(filepath, contents)
          progress_nochange filepath
          return
        end
      end

      File.open(filepath, 'w') do |f|
        f.write contents
      end

      if existed
        progress_updated filepath
      else
        progress_created filepath
      end
    end

    #def rename_file(filepath)
    #end

    #private

    ##
    ## PRIVATE HELPER METHODS
    ##

    #
    # compares md5 fingerprints to see if the contents of a file match the string we have in memory
    #
    def file_content_equals?(filepath, contents)
      filepath = Path.named_path(filepath)
      output = `md5sum '#{filepath}'`.strip
      if $?.to_i == 0
        return output.split(" ").first == Digest::MD5.hexdigest(contents).to_s
      else
        return false
      end
    end

  end
end
