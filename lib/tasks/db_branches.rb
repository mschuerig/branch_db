
namespace :db do
  task :branches => "branches:list"

  namespace :branches do
    task :setup => "db:load_config" do
      require 'branch_db/task_helper'
      include BranchDb::TaskHelper
    end
    
    desc "List all branch databases"
    task :list => :setup do
      each_local_config do |rails_env, config|
        BranchDb::Switcher.branches(rails_env, config)
      end
    end
    
    desc "Currently selected databases."
    task :current => :setup do
      each_local_database { |switcher| switcher.current }
    end

    desc "Create empty databases for a branch. Current or BRANCH."
    task :create => :setup do
      each_local_database { |switcher| switcher.create_empty_database }
    end
    
    desc "Copy databases from one branch to another. Default is from ORIG_BRANCH=master to BRANCH=<current branch>"
    task :copy => :setup do
      each_local_database { |switcher| switcher.copy_from(originating_branch) }
    end

    desc "Delete databases for a branch given by BRANCH"
    task :delete => :setup do
      case target_branch
      when current_branch
        $stderr.puts "Cannot delete databases for the current branch."
      when 'master'
        $stderr.puts "Cannot delete databases for the master branch."
      else
        each_local_database { |switcher| switcher.delete_database }
      end
    end
  end
end
