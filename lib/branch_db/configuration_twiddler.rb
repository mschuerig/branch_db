
require 'branch_db'

module BranchDb # :nodoc
  module ConfigurationTwiddler
    
    def self.included(base)
      base.send(:alias_method, :database_configuration_without_branches, :database_configuration)
      base.send(:alias_method, :database_configuration, :database_configuration_with_branches)
    end

    def database_configuration_with_branches
      dbconfig = database_configuration_without_branches
      if branch = BranchDb::current_repo_branch
        dbconfig.each do |env, config|
          BranchDb::Switcher.create(env, config, branch).switch!
        end
      end
      dbconfig
    end
  end
end
