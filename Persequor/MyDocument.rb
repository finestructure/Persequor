#
#  MyDocument.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 18.09.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#

require 'trac4r/trac'
require 'mytrac'


class MyDocument < NSPersistentDocument
  attr_accessor :array_controller
  attr_accessor :cache_info
  attr_accessor :is_loading
  attr_accessor :predicate_editor
  attr_accessor :previous_row_count
  attr_accessor :progress_bar
  attr_accessor :query
  attr_accessor :toolbar_view
  attr_accessor :queue
  attr_accessor :refresh_button
  attr_accessor :table_view
  attr_accessor :ticket_cache

  def init
  	super
  	if (self != nil)
      @queue = Dispatch::Queue.new('de.abstracture.presequor')
  	end
    self
  end


  def windowNibName
    # Override returning the nib file name of the document
    # If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    "MyDocument"
  end


  def windowControllerDidLoadNib(aController)
    super
    @predicate_editor.enclosingScrollView.setHasVerticalScroller(false)
    @previous_row_count = 2 # height that's configured in the nib
    init_query
    init_cache_info
    init_ticket_cache
  end


  # helpers
  
  def defaults(key)
    defaults = NSUserDefaults.standardUserDefaults
    defaults.objectForKey(key)
  end


  def save_predicate(predicate)
    data = NSKeyedArchiver.archivedDataWithRootObject(predicate)
    @query.predicate = data
  end


  def default_predicate
    username = defaults("username")
    if username != nil
      predicate = NSPredicate.predicateWithFormat(
      "(owner ==[cd] \"#{username}\") and (status != \"closed\")"
      )
    else
      predicate = NSPredicate.predicateWithFormat('status != \"closed\"')
    end
    return predicate
  end

  
  def fetch_rows(entity_name)
    request = NSFetchRequest.fetchRequestWithEntityName(entity_name)
    raise "no request" unless request
    moc = self.managedObjectContext
    raise "no moc" unless moc
    error = Pointer.new_with_type("@")
    rows = moc.executeFetchRequest(request, error:error)
    return rows
  end
  
  
  def init_query
    rows = fetch_rows("Query")
    
    if rows == nil or rows == []
      @query = NSEntityDescription.insertNewObjectForEntityForName(
        "Query",
        inManagedObjectContext:self.managedObjectContext
      )
      predicate = default_predicate
      save_predicate(predicate)
    else
      @query = rows[0]
      data = @query.predicate
      predicate = NSKeyedUnarchiver.unarchiveObjectWithData(data)
    end
    
    @predicate_editor.setObjectValue(predicate)
    @array_controller.setFilterPredicate(predicate)
    resize_window
  end


  def init_cache_info
    rows = fetch_rows("CacheInfo")
    if rows == nil or rows == []
      puts "no data"
      @cache_info = NSEntityDescription.insertNewObjectForEntityForName(
        "CacheInfo",
        inManagedObjectContext:self.managedObjectContext
      )
    else
      puts "got data"
      @cache_info = rows[0]
    end
  end


  def init_ticket_cache
    tickets = fetch_rows("Ticket")
    puts "tickets loaded: #{tickets.size}"
    
    trac = Trac.new(defaults("tracUrl"),
                    defaults("username"),
                    defaults("password"))
    @ticket_cache = TicketCache.new(trac, tickets, @cache_info.updated_at)
  end


  def resize_window
    new_row_count = @predicate_editor.numberOfRows
    
    if new_row_count == previous_row_count
      return
    end
    
    table_scroll_view = @table_view.enclosingScrollView
    old_outline_mask = table_scroll_view.autoresizingMask
    
    predicate_editor_scroll_view = @predicate_editor.enclosingScrollView
    old_predicate_editor_mask = predicate_editor_scroll_view.autoresizingMask
    
    table_scroll_view.setAutoresizingMask(
      NSViewWidthSizable | NSViewMaxYMargin
    )
    predicate_editor_scroll_view.setAutoresizingMask(
      NSViewWidthSizable | NSViewHeightSizable
    )
    
    growing = new_row_count > previous_row_count
    
    heightDiff = @predicate_editor.rowHeight \
      * (new_row_count - @previous_row_count)
    heightDiff = heightDiff.abs
    
    sizeChange = @predicate_editor.convertSize([0, heightDiff], toView:nil)
    
    # offset toolbar_view
    frame = @toolbar_view.frame
    @toolbar_view.setFrameOrigin(
      [frame.origin.x,
       frame.origin.y \
       - @predicate_editor.rowHeight * (new_row_count - previous_row_count)]
    )
    
    # change window frame size
    windowFrame = self.windowForSheet.frame
    windowFrame.size.height += growing ? sizeChange.height : -sizeChange.height
    windowFrame.origin.y -= growing ? sizeChange.height : -sizeChange.height
    self.windowForSheet.setFrame(windowFrame, display:true, animate:false)
    
    table_scroll_view.setAutoresizingMask(old_outline_mask)
    predicate_editor_scroll_view.setAutoresizingMask(old_predicate_editor_mask)
    
    @previous_row_count = new_row_count
  end
  

  # actions
  
  
  def predicateEditorChanged(sender)
    predicate = @predicate_editor.objectValue
    p predicate.predicateFormat
    
    @array_controller.setFilterPredicate(predicate)
    save_predicate(predicate)
    
    resize_window
  end
  
  
  def start_show_progress(max_count)
    Dispatch::Queue.main.async do
      if max_count > 0
        @progress_bar.setIndeterminate(false)
        @progress_bar.setDoubleValue(0)
        @progress_bar.setMaxValue(max_count)
      else
        @progress_bar.setIndeterminate(true)
        @progress_bar.startAnimation(self)
      end
      @progress_bar.hidden = false
      @refresh_button.enabled = false
    end
  end
  
  
  def end_show_progress
    Dispatch::Queue.main.async do
      @progress_bar.hidden = true
      @refresh_button.enabled = true
    end
  end
  
  
  def create_entity(ticket)
    moc = self.managedObjectContext
    t = NSEntityDescription.insertNewObjectForEntityForName(
      "Ticket",
      inManagedObjectContext:moc
    )
    t.id = ticket.id
    t.severity = ticket.severity
    t.milestone = ticket.milestone
    t.status = ticket.status
    t.priority = ticket.priority
    t.version = ticket.version
    t.reporter = ticket.reporter
    t.owner = ticket.owner
    t.cc = ticket.cc
    t.summary = ticket.summary
    t.desc = ticket.description
    t.keywords = ticket.keywords
    t.component = ticket.component
    #t.created_at = ticket.created_at
    #t.updated_at = ticket.updated_at
    return t
  end
  
  
  def fetch_tickets(trac, ids, n_queues=1)
    group = Dispatch::Group.new
    queues = []
    n_queues.times do |i|
      queues << Dispatch::Queue.new("de.abstracture.queue-#{i}")
    end

    ids.each do |id|
      queue_id = id % n_queues
      queues[queue_id].async(group) do
        t = trac.tickets.get(id)
        puts "loaded #{id} (queue: #{queue_id})"
        Dispatch::Queue.main.async do
          @progress_bar.incrementBy(1)
          predicate = @predicate_editor.predicate
          create_entity(t)
          @array_controller.setFilterPredicate(predicate)
        end
      end
    end
    group.wait
  end
  
  
  def refresh(sender)
    puts 'loading tickets'
    @queue.async do
      @is_loading = true
      start_show_progress(0)

      # clear array
      Dispatch::Queue.main.async do
        count = @array_controller.arrangedObjects.size
        index_set = NSIndexSet.indexSetWithIndexesInRange([0, count])
        @array_controller.removeObjectsAtArrangedObjectIndexes(index_set)
      end
      
      username = defaults("username")
      trac = Trac.new(defaults("tracUrl"),
                      username,
                      defaults("password"))
#     filter = ["owner=#{username}", "status!=closed"]
      filter = ["status!=closed"]
      tickets = trac.tickets.filter(filter)
      
      start_show_progress(tickets.size)
      fetch_tickets(trac, tickets)
      
      end_show_progress
      @is_loading = false
    end
  end


  def clear_button_pressed(sender)
    count = @predicate_editor.numberOfRows
    while count > 1 do
      @predicate_editor.removeRowAtIndex(count-1)
      count -= 1
    end
    resize_window
  end

end

