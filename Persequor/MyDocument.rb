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
  attr_accessor :predicate_editor
  attr_accessor :previous_row_count
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
    # check for return key
    event = NSApp.currentEvent
    if event and event.type == NSKeyDown
      chars = event.characters
      if chars.size > 0 and chars[0] == "\r"
        puts 'return pressed'
        predicate = @predicate_editor.objectValue
        p predicate
      end
    end
    
    #if @predicate_editor.numberOfRows == 0
    #  @predicate_editor.addRow(self)
    #end
    
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
    
    # offset refresh button
    frame = @refresh_button.frame
    @refresh_button.setFrameOrigin(
      [frame.origin.x,
       frame.origin.y \
       - @predicate_editor.rowHeight * (new_row_count - previous_row_count)]
    )
    
    # change window frame size
    windowFrame = self.windowForSheet.frame
    windowFrame.size.height += growing ? sizeChange.height : -sizeChange.height
    windowFrame.origin.y -= growing ? sizeChange.height : -sizeChange.height
    self.windowForSheet.setFrame(windowFrame, display:true, animate:true)
    
    table_scroll_view.setAutoresizingMask(old_outline_mask)
    predicate_editor_scroll_view.setAutoresizingMask(old_predicate_editor_mask)
    
    @previous_row_count = new_row_count
  end
  
  
  def button_pressed(sender)
    puts 'in here'
    @queue.async do
      username = defaults("username")
      trac = Trac.new(defaults("tracUrl"),
                      username,
                      defaults("password"))
      trac.tickets.filter(["owner=#{username}", "status!=closed"]).each do |id|
        t = trac.tickets.get(id)
        puts "ticket #{t.id} loaded"
        @array_controller.addObject(t)
        Dispatch::Queue.main.async do
          @table_view.reloadData
        end
      end
    end
  end

end

