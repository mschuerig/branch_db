
require 'branch_db/switcher'

module BranchDb # :nodoc:

  class PostgresqlSwitcher < Switcher
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
      config = branch_config(branch).merge(
        'encoding' => @config[:encoding] || ENV['CHARSET'] || 'utf8')
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
    
    def copy_database(from_branch, to_branch)
      dump_file = dump_branch_db(from_branch)
      load_branch_db(to_branch, dump_file)
    end
    
    private
    
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
    
    def dump_branch_db(branch)
      require 'tempfile'
      config = branch_config(branch)
      old_umask = File.umask(0077) # make created files readable only to the user
      dump_file = Tempfile.new('branchdb')
      `pg_dump --clean -U "#{config['username']}" --host="#{config['host']}" --port=#{config['port']} #{config['database']} > #{dump_file.path}`
      raise Error, "Unable to dump database #{config['database']}." unless $? == 0
      dump_file.path
    ensure
      File.umask(old_umask)
    end
    
    def load_branch_db(branch, dump_file)
      config = branch_config(branch)
      silence_stderr do
        `psql -U "#{config['username']}" -f "#{dump_file}" --host="#{config['host']}" --port=#{config['port']} #{config['database']}`
      end
      raise Error, "Unable to load database #{config['database']}." unless $? == 0
    end
  end
end
