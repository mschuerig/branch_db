# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{branch_db}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Schuerig"]
  s.date = %q{2009-04-08}
  s.description = %q{Give each git branch its own databases for ActiveRecord.}
  s.email = ["michael@schuerig.de"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = [".gitignore", "History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "lib/branch_db.rb", "lib/branch_db/configuration_twiddler.rb", "lib/branch_db/postgresql_switcher.rb", "lib/branch_db/sqlite_switcher.rb", "lib/branch_db/switcher.rb", "lib/branch_db/task_helper.rb", "lib/tasks/db_branches.rb", "test/mocks.rb", "test/test_branch_db.rb", "test/test_configuration_twiddler.rb", "test/test_helper.rb", "test/test_postgresql_switcher.rb", "test/test_sqlite_switcher.rb", "test/test_switcher.rb"]
  s.has_rdoc = false
  s.homepage = %q{http://github.com/mschuerig/branch_db}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{branch_db}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Give each git branch its own databases for ActiveRecord.}
  s.test_files = ["test/test_sqlite_switcher.rb", "test/test_helper.rb", "test/test_configuration_twiddler.rb", "test/test_postgresql_switcher.rb", "test/test_branch_db.rb", "test/test_switcher.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, [">= 2.0.2"])
      s.add_development_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<activerecord>, [">= 2.0.2"])
      s.add_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<activerecord>, [">= 2.0.2"])
    s.add_dependency(%q<newgem>, [">= 1.3.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
