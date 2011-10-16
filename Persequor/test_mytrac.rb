require 'test/unit'
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


# make private methods public for testing
class TicketCache
  public :update
end


class Test02TicketCache < Test::Unit::TestCase
  
  def setup
    @trac = Trac.new(TRAC_URL, USER, PASS)
    @trac.tickets.create("test", "description")
    
    @cache = TicketCache.new(TRAC_URL, USER, PASS)
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

  
  def test_04_updates
    @trac.tickets.create("test1", "description")
    @trac.tickets.create("test2", "description")
    sleep 2 # make we pass enough time to avoid the offset in 'updates'
    updates = @cache.updates
    assert_equal([1,2,3], updates)
    updates = @cache.updates
    assert_equal([], updates)
  end
  
  
  def test_05_create
    ticket = {summary:'my summary', description:'my description',
      milestone:'my milestone', priority:'my priority', version:'my version',
      reporter:'my reporter', owner:'my owner', cc:'my, cc',
      keywords:'my keywords', component:'my component', type:'my type'}
    @cache.create(ticket)
    updates = @cache.updates
    assert_equal([1,2], updates)
    t = @cache.fetch(2)
    assert_equal('my summary', t.summary)
    assert_equal('my description', t.description)
    assert_equal('new', t.status)
    assert_equal('my priority', t.priority)
    assert_equal('my version', t.version)
    assert_equal('my reporter', t.reporter)
    assert_equal('my owner', t.owner)
    assert_equal('my, cc', t.cc)
    assert_equal('my keywords', t.keywords)
    assert_equal('my component', t.component)
    assert_equal('my type', t.type)
  end
  
end


class Test00ConnectionFailures < Test::Unit::TestCase

  def test_01_bad_password
    trac = Trac.new(TRAC_URL, USER, "bad")
    begin
      trac.tickets.list
      raise "must not reach this poin"
    rescue Trac::TracException => e
      assert_equal("Authorization failed.\n401 Unauthorized", e.message)
    end
  end

  def test_02_bad_username
    trac = Trac.new(TRAC_URL, "bad", PASS)
    begin
      trac.tickets.list
      raise "must not reach this poin"
    rescue Trac::TracException => e
      assert_equal("Authorization failed.\n401 Unauthorized", e.message)
    end
  end

  def test_03_bad_url_1
    trac = Trac.new("http://bad", USER, PASS)
    begin
      trac.tickets.list
      raise "must not reach this poin"
    rescue SocketError => e
      assert_equal("getaddrinfo: nodename nor servname provided, or not known",
        e.message)
    end
  end

  def test_04_bad_url_2
    trac = Trac.new("http://localhost:99999", USER, PASS)
    begin
      trac.tickets.list
      raise "must not reach this poin"
    rescue SocketError => e
      assert_equal("getaddrinfo: nodename nor servname provided, or not known",
        e.message)
    end
  end

end



