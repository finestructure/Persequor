#
#  NewTicketController.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 12.10.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#


class NewTicketController < NSWindowController

  attr_accessor :components
  attr_accessor :document
  attr_accessor :milestones
  attr_accessor :new_ticket
  attr_accessor :types
  
  
  def initWithWindowNibName(nib)
    super(nib)
    if self != nil
      @components = NSArrayController.alloc.init
      @milestones = NSArrayController.alloc.init
      @types = NSArrayController.alloc.init
    end
    return self
  end
  
  
  def begin_sheet_for_document(doc)
    @document = doc
    
    @components.setContent([""] + @document.ticket_cache.components)
    @milestones.setContent([""] + @document.ticket_cache.milestones)
    @types.setContent(@document.ticket_cache.types)
    @types.setSelectedObjects(["task"])
    
    @new_ticket = {}
    NSApplication.sharedApplication.beginSheet(
      self.window,
      modalForWindow:doc.windowForSheet,
      modalDelegate:self,
      didEndSelector:"newTicketSheetDidEnd:returnCode:contextInfo:",
      contextInfo:nil
    )
  end
  
  
  def dismiss_sheet(sender)
    NSApplication.sharedApplication.endSheet(self.window,
      returnCode:sender.tag)
    self.window.close
  end


  def newTicketSheetDidEnd(sheet, returnCode: returnCode,
    contextInfo: contextInfo)
    $log.debug("new ticket sheet ended: #{returnCode}")
    case returnCode
    when 0
      # cancel => do nothing
    when 1
      # create ticket
      @new_ticket["component"] = @components.selectedObjects[0]
      @new_ticket["milestone"] = @milestones.selectedObjects[0]
      @new_ticket["type"] = @types.selectedObjects[0]
      @document.new_ticket(@new_ticket)
    end
  end

end
