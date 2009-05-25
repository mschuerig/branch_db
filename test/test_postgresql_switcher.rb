
require 'test_helper'
require 'mocks'

class TestPostgresqlSwitcher < Test::Unit::TestCase
  def setup
    @config = {
      'development' => {
        'database' => 'testit_development',
        'adapter' => 'postgresql',
        'per_branch' => true
      },
      'test' => {
        'database' => 'testit_test',
        'adapter' => 'postgresql'
      }
    }
  end

  def make_switcher(options = {})
    env = options.delete(:env) || 'development'
    branch = options.delete(:branch) || 'feature'
    BranchDb::PostgresqlSwitcher.new(env, @config[env], branch, options)
  end

  def test_branches
    assert_stdout "development: testit_development, testit_feature_development.\n" do
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
    silence_stream($stdout) do
      switcher.create_empty_database
    end
    switcher.verify(
      [:drop_database, 'feature'],
      [:create_database, 'feature']
    )
  end

  def test_copy_database
    switcher = make_switcher(:branch => 'misfeature')
    silence_stream($stdout) do
      switcher.copy_from('feature')
    end
    switcher.verify(
      [:create_database, "misfeature"],
      [:dump_branch_db, "feature"],
      [:load_branch_db, "misfeature", "the-dump-file"]
    )
  end
end
