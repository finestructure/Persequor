require 'rubygems'
require 'yaml'
require 'trac4r/trac'
require 'test/unit'
require 'time'

CONFIG_FILE = File.expand_path '~/.trac.yml'


class TestTrac < Test::Unit::TestCase

  def setup
    configuration = YAML.load(File.read(CONFIG_FILE))
    trac_url = configuration[:trac_url]
    username = configuration[:username]
    password = configuration[:password]
    @trac = Trac.new(trac_url, username, password)
  end


  def test_ticket_changes
    since = Time.local(2011,9,1)
    res = @trac.tickets.changes(since)
    assert(res.size > 0)
  end


  def test_ticket_settings
    p @trac.tickets.settings
  end


end
