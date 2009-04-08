require File.dirname(__FILE__) + '/test_helper.rb'

require 'mocks'

class TestPostgresqlSwitcher < Test::Unit::TestCase
  def setup
    @config = {
      'development' => {
        'database' => 'testit_development',
        'adapter' => 'postgresql'
      }
    }
    @switcher = BranchDb::PostgresqlSwitcher.new('development', @config, 'feature')
  end
  
  def test_branches
    puts BranchDb::PostgresqlSwitcher.branches('development', @config['development'])
  end
end
