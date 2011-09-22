require 'rubygems'
require 'trac4r/trac'
require 'test/unit'
require 'time'
require 'mytrac'

TRAC_URL = "http://localhost:8080"
USER = "admin"
PASS = "admin"


class TestMyTrac < Test::Unit::TestCase

  def setup
    @trac = Trac.new(TRAC_URL, USER, PASS)
  end

  
  def test_01_ticket_create
    @trac.tickets.create("test", "description")
    ids = @trac.tickets.list
    assert(ids.size > 0)
  end


  def test_02_ticket_changes
    since = Time.local(2011,9,1)
    res = @trac.tickets.changes(since)
    assert(res.size > 0)
  end


  def test_03_ticket_settings
    assert_not_nil(@trac.tickets.settings)
  end


  def test_04_ticket_desc
    t = @trac.tickets.get(1)
    assert_not_nil(t)
    assert_not_nil(t.desc)
    t.desc = 'new description'
  end


end
