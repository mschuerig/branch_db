
require 'test_helper'
require 'mocks'

class TestSqliteSwitcher < Test::Unit::TestCase
  def setup
    create_mock_sqlite_db(
      'db/development.sqlite3', 
      'db/development_feature.sqlite3',
      'db/test.sqlite3'
    )
    @config = {
      'development' => {
        'database' => 'db/development.sqlite3',
        'adapter' => 'sqlite3',
        'per_branch' => true
      },
      'test' => {
        'database' => 'db/test.sqlite3',
        'adapter' => 'sqlite3'
      }
    }
  end

  def teardown
    FileUtils.rm_rf(RAILS_ROOT)
  end

  def make_switcher(options = {})
    env = options.delete(:env) || 'development'
    branch = options.delete(:branch) || 'feature'
    BranchDb::SqliteSwitcher.new(env, @config[env], branch, options)
  end
  
  def test_branches
    assert_stdout "development: Has branch databases. Cannot determine which ones.\n" do
      BranchDb::Switcher.branches('development', @config['development'])
    end
    assert_stdout "" do
      BranchDb::Switcher.branches('development', @config['test'])
    end
  end

  def test_create_empty_database_non_existing
    switcher = make_switcher(:branch => 'misfeature')
    silence_stream($stdout) do
      switcher.create_empty_database
    end
    switcher.verify(
      [:create_database, 'misfeature']
    )
  end

  def test_create_empty_database_existing
    switcher = make_switcher
    silence_stream($stderr) do
      switcher.create_empty_database
    end
    switcher.verify
  end

  def test_create_empty_database_existing_overwrite
    switcher = make_switcher(:overwrite => true)
    assert_stdout(/^Dropping/) do
      switcher.create_empty_database
    end
    switcher.verify(
      [:create_database, 'feature']
    )
  end

  def test_copy_database
    switcher = make_switcher(:branch => 'misfeature')
    silence_stream($stdout) do
      switcher.copy_from('feature')
    end
    switcher.verify(
      [:create_database, "misfeature"]
    )
    assert_sqlite_db_exist('db/development_misfeature.sqlite3')
  end
end
