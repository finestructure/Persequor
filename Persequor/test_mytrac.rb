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
    since = @start_time - 1
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



class Test02TicketCache < Test::Unit::TestCase
  
  def setup
    @trac = Trac.new(TRAC_URL, USER, PASS)
    @trac.tickets.create("test", "description")
    
    @cache = TicketCache.new(@trac)
  end

  def teardown
    # try to clean up
    @trac.tickets.list.each{ |id| @trac.tickets.delete(id) }
  end


  def test_01_cache
    assert_equal({}, @cache.tickets)
    assert_equal(nil, @cache.updated_at)
    @cache.update
    id = 1
    assert_equal("test", @cache.tickets[id].summary)
    assert_not_nil(@cache.updated_at)
  end


  def test_02_cache_changes
    @cache.update
    assert_equal(1, @cache.tickets.size)
    @trac.tickets.create("test", "description")
    assert_equal(1, @cache.tickets.size)
    @cache.update
    assert_equal(2, @cache.tickets.size)
  end


  def test_03_update_block
    @trac.tickets.create("test1", "description")
    @trac.tickets.create("test2", "description")
    res = []
    @cache.update{|t| res << t.summary}
    assert_equal(3, res.size)
    assert_equal("test", res[0])
    assert_equal("test1", res[1])
    assert_equal("test2", res[2])
    res = []
    @cache.update{|t| res << t.summary}
    assert_equal(0, res.size)
  end

  
end

