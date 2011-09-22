require 'time'
require 'trac4r/trac'
require 'mytrac'
require 'yaml'

class Trac::Ticket
  # alias to support core data which doesn't allow 'description' property
  alias :desc :description
  alias :desc= :description=
end


class MyTrac < Trac::Base

  def initialize(*args)
    super(*args)
    @cache = {}
  end

  def update
    if @update_at == nil
      @update_at = Time.now
      @tickets.list(:include_closed => false).each do |id|
        @cache[id] = @tickets.get(id)
        #puts "loaded #{id}"
      end
    else
      since = @update_at
      @tickets.changes(since).each do |id|
        @cache[id] = @tickets.get(id)
        puts "updated #{id}"
      end
    end
  end

end



if __FILE__ == $0
  main
end
