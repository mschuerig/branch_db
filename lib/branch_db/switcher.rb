
module BranchDb # :nodoc:

  class Switcher
    def self.which(config)
      switcher = switchers.detect { |sw| sw.can_handle?(config) }
      unless switcher
        $stderr.puts "Your database adapter (#{config['adapter']}) is not supported yet."
        switcher = self # double as null switcher
      end
      switcher
    end
    
    def self.can_handle?(config)
      raise Error, "Subclasses of BranchDb::Switcher must implement #can_handle?(config)."
    end
    
    def self.create(rails_env, config, branch, options = {})
      which(config).new(rails_env, config, branch, options)
    end
    
    def self.branches(rails_env, config)
      self.which(config).show_branches(rails_env, config)
    end

    def initialize(rails_env, config, branch, options = {})
      @rails_env, @config, @branch = rails_env, config, branch
      @overwrite = options[:overwrite]
      setup_environment
    end

    def current
      # Must be implemented in subclasses.
    end
    
    def exists?
      branch_db_exists?(@branch)
    end
    
    def switch!
      if exists?
        @config.replace(branch_config(@branch))
      end
    end
    
    def create_empty_database
      db = branch_db(@branch)
      if branch_db_exists?(@branch)
        if !@overwrite
          $stderr.puts "Database #{db} exists already."
          return
        else
          puts "Dropping existing database #{db}..."
          drop_database(@branch)
        end
      end
      puts "Creating fresh database #{db}..."
      create_database(@branch)
      yield if block_given?
    end
    
    def delete_database
      ensure_branch_db_exists!(@branch)
      puts "Dropping existing database #{branch_db(@branch)}..."
      drop_database(@branch)
    end
    
    def copy_from(from_branch)
      ensure_branch_db_exists!(from_branch)

      create_empty_database do
        puts "Copying data..."
        copy_database(from_branch, @branch)
      end
    end
    
    protected
    
    def self.show_branches(rails_env, config)
      case per_branch = config['per_branch']
      when true
        puts "#{rails_env}: Has branch databases. Cannot determine which ones."
#      when Hash
#        puts "#{rails_env}:"
#        per_branch.each do |db|
#          puts "  #{db}"
#        end
      end
    end

    def branch_config(branch)
      @config.merge('database' => branch_db(branch))
    end

    def ensure_branch_db_exists!(branch)
      unless branch_db_exists?(branch)
        raise Error, "There is no database for the branch #{branch}."
      end
    end

    def branch_db_exists?(branch)
      false
    end
    
    def setup_environment
    end
    
    def branch_db(branch)
      # Must be implemented in subclasses.
    end
    
    def create_database(branch)
      # Must be implemented in subclasses.
    end
    
    def drop_database(branch)
      # Must be implemented in subclasses.
    end
    
    def copy_database(from_branch, to_branch)
      # Must be implemented in subclasses.
    end
    
    private

    def self.switchers
      @switchers ||= []
    end

    def self.inherited(child)
      switchers << child
    end
  end
end

