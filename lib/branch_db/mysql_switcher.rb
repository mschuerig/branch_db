
require 'branch_db/switcher'

module BranchDb # :nodoc:

  class MysqlSwitcher < Switcher
    def self.can_handle?(config)
      config['adapter'] == 'mysql'
    end
    
    def current
      current_branch = branch_db_exists?(@branch) ? @branch : 'master'
      puts "#{@rails_env}: #{branch_db(current_branch)} (MySQL)"
    end
    
    protected
    
    def self.show_branches(rails_env, config)
      super
    end

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
    
    def create_database(branch)
      config = branch_config(branch)
      charset   = ENV['CHARSET']   || 'utf8'
      collation = ENV['COLLATION'] || 'utf8_general_ci'
      ActiveRecord::Base.establish_connection(config.merge('database' => nil))
      ActiveRecord::Base.connection.create_database(config['database'], :charset => (config['charset'] || charset), :collation => (config['collation'] || collation))
      ActiveRecord::Base.establish_connection(config)
    end
    
    def drop_database(branch)
      config = branch_config(branch)
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection.drop_database config['database']
      @existing_databases = nil
      nil
    end
    
    def copy_database(from_branch, to_branch)
      dump_file = dump_branch_db(from_branch)
      load_branch_db(to_branch, dump_file)
    end
    
    private
    
    def existing_databases
      @existing_databases ||=
        begin
          raw_dbs = `mysql -e 'SHOW DATABASES'`
          if $? == 0
            existing_dbs = raw_dbs.split("\n").drop(1)
            existing_dbs -= %w( information_schema )
          else
            raise Error, "Cannot determine existing databases."
          end
        end
    end
    
    def dump_branch_db(branch)
      require 'tempfile'
      config = branch_config(branch)
      old_umask = File.umask(0077) # make created files readable only to the user
      dump_file = Tempfile.new('branchdb')
      `mysqldump --user "#{config["username"]}" --host "#{config["host"]}" #{config["database"]} > #{dump_file.path}`
      raise Error, "Unable to dump database #{config['database']}." unless $? == 0
      dump_file.path
    ensure
      File.umask(old_umask)
    end
    
    def load_branch_db(branch, dump_file)
      config = branch_config(branch)
      silence_stderr do
        `mysql --user "#{config["username"]}" --host "#{config["host"]}" #{config["database"]} < #{dump_file}`
      end
      raise Error, "Unable to load database #{config['database']}." unless $? == 0
    end
  end
end
