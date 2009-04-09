
require 'branch_db/switcher'
require 'branch_db/real_db_switchers_common'

module BranchDb # :nodoc:

  class MysqlSwitcher < Switcher
    include RealDbSwitchersCommon
    
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

    def create_database(branch)
      ### TODO when copying a database, determine charset and collation from original
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
    
    def existing_databases
      @existing_databases ||=
        begin
          raw_dbs = `mysql #{command_options(@config)} -e 'SHOW DATABASES'`
          if $? == 0
            existing_dbs = raw_dbs.split("\n").drop(1)
            existing_dbs -= %w( information_schema )
          else
            raise Error, "Cannot determine existing databases."
          end
        end
    end
    
    def dump_command(config, dump_file)
      %{mysqldump #{command_options(config)} #{config["database"]} > #{dump_file}}
    end
    
    def load_command(config, dump_file)
      %{mysql #{command_options(config)} #{config["database"]} < #{dump_file}}
    end
    
    def command_options(config)
      returning opts = '' do
        %w( user username password password host host).each_slice(2) do |o, k|
          opts << " --#{o} #{config[k]}" if config[k]
        end
      end
    end
  end
end
