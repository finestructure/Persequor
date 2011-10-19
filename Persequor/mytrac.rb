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

  def initialize(url, username, password, tickets=[], updated_at=nil)
    @trac = Trac.new(url, username, password)

    @tickets = {}
    tickets.each{ |t| @tickets[t.id] = t }
    @updated_at = updated_at
  end


  def updates
    if @updated_at == nil
      @updated_at = Time.now
      return @trac.tickets.list(:include_closed => false)
    else
      # offset since slightly to allow for rounding errors
      since = @updated_at - 1
      return @trac.tickets.changes(since)
    end
  end


  def fetch(id)
    ticket = @trac.tickets.get(id)
    # only update if the ticket is really newer
    # (could have overlap due to offset above)
    if (not @tickets.include?(id) or
        ticket.updated_at.to_time > @tickets[id].updated_at.to_time)
      @tickets[id] = ticket
      return ticket
    else
      return nil
    end
  end


  def create(ticket)
    attributes = ticket
    summary = attributes.delete('summary')
    description = attributes.delete('description') || ''
    @trac.tickets.create(summary, description, attributes)
  end


  def statuses
    return @trac.tickets.settings[:status]
  end
  

  def components
    return @trac.tickets.settings[:component]
  end
  

  private

  # currently not used due to threading issues
  def update(&block)
    if @updated_at == nil
      @updated_at = Time.now
      @trac.tickets.list(:include_closed => false).each do |id|
        @tickets[id] = @trac.tickets.get(id)
        #puts "loaded: #{id} #{@tickets[id]}"
        if block_given?
          yield @tickets[id]
        end
      end
    else
      # offset since slightly to allow for rounding errors
      since = @updated_at - 1
      @trac.tickets.changes(since).each do |id|
        ticket = @trac.tickets.get(id)
        # only update if the ticket is really newer
        # (could have overlap due to offset above)
        if (not @tickets.include?(id) or
            ticket.updated_at.to_time > @tickets[id].updated_at.to_time)
          @tickets[id] = ticket
          if block_given?
            yield ticket
          end
        end
      end
    end
  end

end


