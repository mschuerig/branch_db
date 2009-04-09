
require 'branch_db/switcher'
require 'branch_db/real_db_switchers_common'

module BranchDb # :nodoc:

  class PostgresqlSwitcher < Switcher
    include RealDbSwitchersCommon
    
    def self.can_handle?(config)
      config['adapter'] == 'postgresql'
    end
    
    def current
      current_branch = branch_db_exists?(@branch) ? @branch : 'master'
      puts "#{@rails_env}: #{branch_db(current_branch)} (PostgreSQL)"
    end
    
    protected
    
    def self.show_branches(rails_env, config)
      super
    end

    def create_database(branch)
      config = branch_config(branch).merge(
        'encoding' => @config['encoding'] || ENV['CHARSET'] || 'utf8')
      ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
      ActiveRecord::Base.connection.create_database(config['database'], config)
      ActiveRecord::Base.establish_connection(config)
      nil
    end
    
    def drop_database(branch)
      config = branch_config(branch)
      ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
      ActiveRecord::Base.connection.drop_database(config['database'])
      @existing_databases = nil
      nil
    end
    
    def existing_databases
      @existing_databases ||=
        begin
          raw_dbs = `psql -l`
          if $? == 0
            existing_dbs = raw_dbs.split("\n").drop_while { |l| l !~ /^-/ }.drop(1).take_while { |l| l !~ /^\(/ }.map { |l| l.split('|')[0].strip }
            existing_dbs.reject { |db| db =~ /^template/ }
          else
            raise Error, "Cannot determine existing databases."
          end
        end
    end
    
    def dump_command(config, dump_file)
      %{pg_dump --clean -U "#{config['username']}" --host="#{config['host']}" --port=#{config['port']} #{config['database']} > #{dump_file}}
    end
    
    def load_command(config, dump_file)
      %{psql -U "#{config['username']}" -f "#{dump_file}" --host="#{config['host']}" --port=#{config['port']} #{config['database']}}
    end
  end
end
