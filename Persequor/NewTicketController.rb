#
#  NewTicketController.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 12.10.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#


class NewTicketController < NSWindowController

  attr_accessor :document
  
  def begin_sheet_for_document(doc)
    @document = doc
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
  end

end
