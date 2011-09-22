require 'rubygems'
require 'trac4r/trac'
require 'test/unit'
require 'time'
require 'mytrac'

TRAC_URL = "http://localhost:8080"
USER = "admin"
PASS = "admin"


class Test01Trac < Test::Unit::TestCase

  def setup
    @trac = Trac.new(TRAC_URL, USER, PASS)
    @start_time = Time.now
    @trac.tickets.list.each{ |id| @trac.tickets.delete(id) }
    @trac.tickets.create("test", "description")
  end

  def teardown
    # try to clean up
    #@trac.tickets.list.each{ |id| @trac.tickets.delete(id) }
  end
  
  def test_01_ticket_create
    before = @trac.tickets.list.size
    @trac.tickets.create("test", "description")
    after = @trac.tickets.list.size
    assert_equal(before +1, after)
  end


  def test_02_ticket_changes
    # offset start_time slightly to allow for rounding errors
    since = @start_time - 0.5
    t = @trac.tickets.get(1)
    assert(t.updated_at.to_time > since)
    assert_equal(1, @trac.tickets.changes(since).size)
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


class MyTrac
  attr_accessor :cache, :update_at
end


class Test02MyTrac < Test::Unit::TestCase
  
  def setup
    @trac = MyTrac.new(TRAC_URL, USER, PASS)
    @trac.tickets.create("test", "description")
  end

  def teardown
    # try to clean up
    @trac.tickets.list.each{ |id| @trac.tickets.delete(id) }
  end


  def test_01_cache
    assert_equal({}, @trac.cache)
    assert_equal(nil, @trac.update_at)
    @trac.update
    id = 1
    assert_equal("test", @trac.cache[id].summary)
    assert_not_nil(@trac.update_at)
  end


  
end

