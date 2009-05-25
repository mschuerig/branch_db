
require 'branch_db/switcher'

module BranchDb # :nodoc:

  class SqliteSwitcher < Switcher
    def self.can_handle?(config)
      (config['adapter'] =~ /^sqlite/) == 0
    end

    def current
      current_branch = branch_db_exists?(@branch) ? @branch : 'master'
      puts "#{@rails_env}: #{rails_root_relative(branch_db(current_branch))} (SQLite)"
    end

    protected

    def self.show_branches(rails_env, config)
      super
    end

    def branch_db(branch)
      if branch == 'master'
        @config['database']
      else
        @config['database'].sub(/(.+)\./, "\\1_#{branch}.")
      end
    end

    def branch_db_exists?(branch)
      File.exists?(branch_db_path(branch))
    end

    def create_database(branch)
      config = branch_config(branch)
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection
    end

    def drop_database(branch)
      FileUtils.rm_f(branch_db_path(branch))
    end

    def copy_database(from_branch, to_branch)
      FileUtils.cp(branch_db_path(from_branch), branch_db_path(to_branch))
    end

    private

    def branch_db_path(branch)
      File.join(RAILS_ROOT, branch_db(branch))
    end

  end
end
