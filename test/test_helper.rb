
require 'stringio'
require 'fileutils'
require 'test/unit'

require 'branch_db'

#require 'rubygems'
#require 'ruby-debug'

RAILS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), 'tmp'))

def assert_stdout(expected)
  oldout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.rewind
  case expected
  when String
    assert_equal(expected, $stdout.read)
  when Regexp
    assert_match(expected, $stdout.read)
  else
    raise ArgumentError, "Don't know how to check stdout against #{expected.inspect}."
  end
ensure
  $stdout = oldout
end

def assert_sqlite_db_exist(name)
  assert File.exists?(File.join(RAILS_ROOT, name)), "SQLite database #{name} does not exist."
end

# from ActiveSupport
def silence_stream(stream)
  old_stream = stream.dup
  stream.reopen(RUBY_PLATFORM =~ /mswin/ ? 'NUL:' : '/dev/null')
  stream.sync = true
  yield
ensure
  stream.reopen(old_stream)
end
