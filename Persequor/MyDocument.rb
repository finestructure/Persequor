#
#  MyDocument.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 18.09.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#

require 'trac4r/trac'


class MyDocument < NSPersistentDocument
  attr_accessor :array_controller
  attr_accessor :is_loading
  attr_accessor :predicate_editor
  attr_accessor :previous_row_count
  attr_accessor :progress_bar
  attr_accessor :toolbar_view
  attr_accessor :queue
  attr_accessor :refresh_button
  attr_accessor :table_view

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
    
    @previous_row_count = 2
    @predicate_editor.addRow(self)
    display_value = @predicate_editor.displayValuesForRow(1).lastObject
    if display_value.isKindOfClass(NSControl)
      self.windowForSheet.makeFirstResponder(display_value)
    end
  end


  # helpers
  
  def defaults(key)
    defaults = NSUserDefaults.standardUserDefaults
    defaults.objectForKey(key)
  end


  # actions
  
  
  def predicateEditorChanged(sender)
    predicate = @predicate_editor.objectValue
    p predicate.predicateFormat
    @array_controller.setFilterPredicate(predicate)
    
    # resize window as needed
    new_row_count = @predicate_editor.numberOfRows
    
    if new_row_count == previous_row_count
      return
    end
    
    table_scroll_view = @table_view.enclosingScrollView
    old_outline_mask = table_scroll_view.autoresizingMask
    
    predicate_editor_scroll_view = @predicate_editor.enclosingScrollView
    old_predicate_editor_mask = predicate_editor_scroll_view.autoresizingMask
    
    table_scroll_view.setAutoresizingMask(NSViewWidthSizable | NSViewMaxYMargin)
    predicate_editor_scroll_view.setAutoresizingMask(NSViewWidthSizable | NSViewHeightSizable)
    
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
  
  
  def start_show_progress(max_count)
    if max_count > 0
      @progress_bar.setIndeterminate(false)
      @progress_bar.setMaxValue(max_count)
    else
      @progress_bar.setIndeterminate(true)
      Dispatch::Queue.main.async{ @progress_bar.startAnimation(self) }
    end
    @progress_bar.hidden = false
    @refresh_button.enabled = false
  end
  
  
  def end_show_progress
    @progress_bar.hidden = true
    @refresh_button.enabled = true
  end
  
  
  def button_pressed(sender)
    puts 'loading tickets'
    @queue.async do
      @is_loading = true
      start_show_progress(0)

      # clear array
      count = @array_controller.arrangedObjects.size
      index_set = NSIndexSet.indexSetWithIndexesInRange([0, count])
      p index_set
      @array_controller.removeObjectsAtArrangedObjectIndexes(index_set)
      
      username = defaults("username")
      trac = Trac.new(defaults("tracUrl"),
                      username,
                      defaults("password"))
#     filter = ["owner=#{username}", "status!=closed"]
      filter = ["status!=closed"]
      tickets = trac.tickets.filter(filter)
      
      start_show_progress(tickets.size)
      
      tickets.each do |id|
        t = trac.tickets.get(id)
        puts "ticket #{t.id} loaded"
        @progress_bar.incrementBy(1)
        @array_controller.addObject(t)
      end
      
      end_show_progress
      @is_loading = false
    end
  end

end

