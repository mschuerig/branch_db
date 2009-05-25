
require 'branch_db'

module BranchDb # :nodoc:
  module TaskHelper

    def current_branch
      BranchDb::current_repo_branch(true)
    end

    def environment_options
      returning options = {} do
        [:overwrite, :verbose].each do |opt|
          options[opt] = (ENV[opt.to_s.upcase] =~ /\A(true|1)\Z/i) == 0
        end
      end
    end

    def target_branch
      ENV['BRANCH'] || current_branch
    end

    def originating_branch
      ENV['ORIG_BRANCH'] || 'master' ### TODO determine originating branch
    end

    def each_local_config
      ActiveRecord::Base.configurations.each do |rails_env, config|
        next unless config['database']
        case per_branch = config['per_branch']
        when true
#        when Hash
        else
          next
        end
        local_database?(config) do
          yield rails_env, config
        end
      end
    end

    def each_local_database(*args)
      options = args.last.kind_of?(Hash) ? args.pop : {}
      options = options.reverse_merge(environment_options)
      branch = args[0] || target_branch
      each_local_config do |rails_env, config|
        yield BranchDb::Switcher.create(rails_env, config, branch, options)
      end
    end
  end
end
