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
      @last_typed = {}
      @components = NSArrayController.alloc.init
      @milestones = NSArrayController.alloc.init
      @types = NSArrayController.alloc.init
    end
    return self
  end
  
  
  def begin_sheet_for_document(doc, ticket_cache:ticket_cache)
    @document = doc
    
    @components.setContent([""] + ticket_cache.components)
    @milestones.setContent([""] + ticket_cache.milestones)
    @types.setContent(ticket_cache.types)
    @types.setSelectedObjects(["task"])
    
    @users = []
    ticket_cache.tickets.each do |_,t|
      @users << t.reporter
      @users << t.owner
      @users << t.cc
    end
    @users.uniq!
    
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
  
  
  # text view delegate
  
  def control(control, textView:textView, completions:words, 
    forPartialWordRange:charRange, indexOfSelectedItem:index)
    typed = textView.string.substringWithRange(charRange)
    if typed != ""
      completions = @users.find_all{ |i| i.start_with?(typed) }
    end
    return completions
  end


  def controlTextDidChange(notification)
    if @complete_posting
      return
    end
  
    @complete_posting = true

    field_editor = notification.userInfo.objectForKey("NSFieldEditor")
    tag = notification.object.tag
    text_changed = @last_typed[tag] != field_editor.string
    if text_changed
      @last_typed = field_editor.string.copy
      field_editor.complete(nil)
    end
    
    @complete_posting = false
  end


end
