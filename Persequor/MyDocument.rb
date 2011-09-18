#
#  MyDocument.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 18.09.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#

require 'trac'


class MyDocument < NSPersistentDocument
  attr_accessor :textfield

  def init
  	super
  	if (self != nil)
      # Add your subclass-specific initialization here.
      # If an error occurs here, return nil.
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
    # Add any code here that needs to be executed once the windowController has loaded the document's window.
  end

  
  # helpers
  def defaults(key)
    defaults = NSUserDefaults.standardUserDefaults
    defaults.objectForKey(key)
  end


  # actions
  
  def button_pressed(sender)
    puts 'in here'
    @textfield.setStringValue(defaults("tracUrl"))
  end

end

