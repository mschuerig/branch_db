
module Recorder
  include Test::Unit::Assertions
  def self.included(base)
    base.extend(SingletonMethods)
  end
  def recorded_calls
    @recorded_calls ||= []
  end
  module SingletonMethods
    def record(*methods, &block)
      methods.each do |m|
        define_method(m) do |*args|
          recorded_calls << [m.to_sym] + args
          block.call if block
        end
      end
    end
  end
  def verify(*expected)
    assert_equal(expected, recorded_calls)
  end
end    

module BranchDb
  def self.set_branch(branch)
    @branch = branch
  end
  def self.current_repo_branch
    @branch
  end
  
  class PostgresqlSwitcher < Switcher
    include Recorder
    record :create_database, :drop_database, :load_branch_db
    record(:dump_branch_db) { 'the-dump-file' }

    def existing_databases
      %w( testit_development testit_feature_development testit_test )
    end
    def operations
      @ops
    end
  end

  class SqliteSwitcher < Switcher
    include Recorder
    record :create_database
  end
end

def create_mock_sqlite_db(*names)
  db_dir = File.join(RAILS_ROOT, 'db')
  FileUtils.mkdir_p(db_dir) unless File.directory?(db_dir)
  names.each do |name|
    File.open(File.join(RAILS_ROOT, name), 'w') { |f| f.puts 'Mock' }
  end
end
