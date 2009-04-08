
require 'branch_db'
require 'branch_db/configuration_twiddler'

class MockConfiguration
  def initialize(config)
    @config = config
  end
  
  def database_configuration
    @config
  end
  include ::BranchDb::ConfigurationTwiddler
end

module BranchDb
  def self.set_branch(branch)
    @branch = branch
  end
  def self.current_repo_branch
    @branch
  end
  
  class PostgresqlSwitcher < Switcher
    def dump_branch_db(*args)
      @ops ||= []
      @ops << [:dump_branch_db] + args
    end
    def load_branch_db(*args)
      @ops ||= []
      @ops << [:load_branch_db] + args
    end
    def existing_databases
      %w( testit_development testit_feature_development testit_test )
    end
    def operations
      @ops
    end
  end
end

def create_mock_sqlite_db(name)
  File.open(File.join(RAILS_ROOT, name), 'w') { |f| f.puts 'Mock' }
end
