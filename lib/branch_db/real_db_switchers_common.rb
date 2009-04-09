module BranchDb # :nodoc:

  module RealDbSwitchersCommon
    protected
    
    def branch_db(branch)
      if branch == 'master'
        @config['database']
      else
        @config['database'].sub(/(_.+?)??(_?(#{@rails_env}))?$/, "_#{branch}\\2")
      end
    end

    def branch_db_exists?(branch)
      existing_databases.include?(branch_db(branch))
    end
    
    def copy_database(from_branch, to_branch)
      dump_file = dump_branch_db(from_branch)
      load_branch_db(to_branch, dump_file)
    end
    
    def dump_branch_db(branch)
      require 'tempfile'
      config = branch_config(branch)
      old_umask = File.umask(0077) # make created files readable only to the user
      dump_file = Tempfile.new('branchdb')
      %x{#{dump_command(config, dump_file.path)}}
      raise Error, "Unable to dump database #{config['database']}." unless $? == 0
      dump_file.path
    ensure
      File.umask(old_umask)
    end
    
    def load_branch_db(branch, dump_file)
      config = branch_config(branch)
      silence_stderr do
        %x{{load_command(config, dump_file)}}
      end
      raise Error, "Unable to load database #{config['database']}." unless $? == 0
    end
  end
end
