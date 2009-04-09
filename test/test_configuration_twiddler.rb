
require 'test_helper'

require 'branch_db/configuration_twiddler'
require 'mocks'

class MockConfiguration
  def initialize(config)
    @config = config
  end
  
  def database_configuration
    @config
  end
  include ::BranchDb::ConfigurationTwiddler
end

module RealDatabaseTests
  def test_master_branch
    BranchDb.set_branch('master')
    assert_env_db 'testit_development', 'development'
    assert_env_db 'testit_test', 'test'
  end
  
  def test_branch
    BranchDb.set_branch('feature')
    assert_env_db 'testit_feature_development', 'development'
    assert_env_db 'testit_test', 'test'
  end
  
  def test_non_existing_branch
    BranchDb.set_branch('erehwon')
    assert_env_db 'testit_development', 'development'
    assert_env_db 'testit_test', 'test'
  end

  def assert_env_db(expected, env)
    assert_equal expected, @mock.database_configuration[env]['database']
  end
end

class TestConfigurationTwiddlerPostgreSQL < Test::Unit::TestCase
  def setup
    @mock = MockConfiguration.new({
      'development' => {
        'database' => 'testit_development',
        'adapter' => 'postgresql',
        'per_branch' => true
      },
      'test' => {
        'database' => 'testit_test',
        'adapter' => 'postgresql',
      }
    })
  end
  
  include RealDatabaseTests
end

class TestConfigurationTwiddlerMysql < Test::Unit::TestCase
  def setup
    @mock = MockConfiguration.new({
      'development' => {
        'database' => 'testit_development',
        'adapter' => 'mysql',
        'per_branch' => true
      },
      'test' => {
        'database' => 'testit_test',
        'adapter' => 'mysql',
      }
    })
  end
  
  include RealDatabaseTests
end

class TestConfigurationTwiddlerSQLite < Test::Unit::TestCase
  def setup
    create_mock_sqlite_db(
      'db/development.sqlite3', 
      'db/development_feature.sqlite3',
      'db/test.sqlite3'
    )
    @mock = MockConfiguration.new({
      'development' => {
        'database' => 'db/development.sqlite3',
        'adapter' => 'sqlite3',
        'per_branch' => true
      },
      'test' => {
        'database' => 'db/test.sqlite3',
        'adapter' => 'sqlite3'
      }
    })
  end
  
  def teardown
    FileUtils.rm_rf(RAILS_ROOT)
  end
  
  def test_master_branch
    BranchDb.set_branch('master')
    assert_env_db 'db/development.sqlite3', 'development'
    assert_env_db 'db/test.sqlite3', 'test'
  end
  
  def test_branch
    BranchDb.set_branch('feature')
    assert_env_db 'db/development_feature.sqlite3', 'development'
    assert_env_db 'db/test.sqlite3', 'test'
  end
  
  def test_non_existing_branch
    BranchDb.set_branch('erehwon')
    assert_env_db 'db/development.sqlite3', 'development'
    assert_env_db 'db/test.sqlite3', 'test'
  end

  def assert_env_db(expected, env)
    assert_equal expected, @mock.database_configuration[env]['database']
  end
end
