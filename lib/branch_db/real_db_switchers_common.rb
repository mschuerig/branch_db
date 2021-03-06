
module BranchDb # :nodoc:

  module RealDbSwitchersCommon
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def branch_dbs
        existing_databases.grep
      end

      def find_existing_databases
        raise Error, "Classes including RealDbSwitchersCommon must implement #find_existing_databases."
      end

      def existing_databases
        @existing_databases ||= find_existing_databases
      end

      def reset_existing_databases
        @existing_databases = nil
      end

      def show_branches(rails_env, config)
        case per_branch = config['per_branch']
        when true
          master_db = config['database']
          pat = master_db.split(/[_-]/).join('(?:(?:[-_]+)|(?:[-_]+[-_\w]+?[-_]+))')
          dbs = existing_databases.grep(/^#{pat}$/)
          puts "#{rails_env}: #{dbs.join(', ')}."
        end
      end
    end

    protected

    def branch_db(branch)
      if branch == 'master'
        @config['database']
      else
        @config['database'].sub(/(_.+?)??(_?(#{@rails_env}))?$/, "_#{branch}\\2")
      end
    end

    def branch_db_exists?(branch)
      self.class.existing_databases.include?(branch_db(branch))
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
      cmd = dump_command(config, dump_file.path)
      puts cmd if verbose?
      %x{#{cmd}}
      raise Error, "Unable to dump database #{config['database']}." unless $? == 0
      dump_file.path
    ensure
      File.umask(old_umask)
    end

    def load_branch_db(branch, dump_file)
      config = branch_config(branch)
      cmd = load_command(config, dump_file)
      puts cmd if verbose?
      silence_stderr do
        %x{#{cmd}}
      end
      raise Error, "Unable to load database #{config['database']}." unless $? == 0
    end
  end
end
