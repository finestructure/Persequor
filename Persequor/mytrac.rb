require 'time'
require 'trac4r/trac'
require 'mytrac'
require 'yaml'

class Trac::Ticket
  # alias to support core data which doesn't allow 'description' property
  alias :desc :description
  alias :desc= :description=
end


class TicketCache
  attr_accessor :tickets
  attr_accessor :updated_at

  def initialize(trac, tickets=[], updated_at=nil)
    @trac = trac
    @tickets = {}
    tickets.each{ |t| @tickets[t.id] = t }
    @updated_at = updated_at
  end

  def update(block=lambda {|id|})
    if @updated_at == nil
      @updated_at = Time.now
      @trac.tickets.list(:include_closed => false).each do |id|
        @tickets[id] = @trac.tickets.get(id)
        #puts "loaded #{id}"
        block.call(@tickets[id])
      end
    else
      # offset since slightly to allow for rounding errors
      since = @updated_at - 1
      @trac.tickets.changes(since).each do |id|
        @tickets[id] = @trac.tickets.get(id)
        #puts "updated #{id}"
        block.call(@tickets[id])
      end
    end
  end

end



if __FILE__ == $0
  main
end
