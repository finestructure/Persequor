#
#  NewTicketController.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 12.10.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#


class NewTicketController < NSWindowController

  attr_accessor :document
  attr_accessor :new_ticket
  
  def begin_sheet_for_document(doc)
    @document = doc
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
      @document.new_ticket(@new_ticket)
    end
  end

end
