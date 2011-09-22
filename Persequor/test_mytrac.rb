require 'rubygems'
require 'yaml'
require 'trac4r/trac'
require 'test/unit'
require 'time'
require 'mytrac'

CONFIG_FILE = File.expand_path '~/.trac.yml'



class TestMyTrac < Test::Unit::TestCase

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
    assert_not_nil(@trac.tickets.settings)
  end


  def test_ticket_desc
    t = @trac.tickets.get(201)
    assert_not_nil(t)
    assert_not_nil(t.desc)
    t.desc = 'new description'
  end


end
