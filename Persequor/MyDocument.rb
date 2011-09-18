#
#  MyDocument.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 18.09.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#

require 'trac4r/trac'


class MyDocument < NSPersistentDocument
  attr_accessor :data
  attr_accessor :predicate_editor
  attr_accessor :queue
  attr_accessor :table_view

  def init
  	super
  	if (self != nil)
      @queue = Dispatch::Queue.new('de.abstracture.presequor')
      @data = []
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
    
    @predicate_editor.addRow(self)
  end


  # NSTableViewDataSource
  
  def numberOfRowsInTableView(aTableView)
    return @data.size
  end


  def tableView(aTableView, objectValueForTableColumn:column, row:rowIndex)
    case column.identifier
      when "Id"
        return @data[rowIndex][0]
      when "Summary"
        return @data[rowIndex][1]
    end
  end

  
  # helpers
  
  def defaults(key)
    defaults = NSUserDefaults.standardUserDefaults
    defaults.objectForKey(key)
  end


  # actions
  
  
  def predicateEditorChanged(sender)
    puts 'editor'
  end
  
  
  def button_pressed(sender)
    puts 'in here'
    @queue.async do
      username = defaults("username")
      trac = Trac.new(defaults("tracUrl"),
                      username,
                      defaults("password"))
      trac.tickets.filter(["owner=#{username}", "status!=closed"]).each do |id|
        puts id
        t = trac.tickets.get(id)
        p t
        @data << [id, t.summary]
        Dispatch::Queue.main.async do
          @table_view.reloadData
        end
      end
    end
  end

end

