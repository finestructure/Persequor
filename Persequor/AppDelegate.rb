#
#  AppDelegate.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 12.10.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#


class AppDelegate
  
  def refresh(sender)
    doc = NSDocumentController.sharedDocumentController.currentDocument
    doc.refresh(sender)
  end
  
  def new_ticket(sender)
    app = NSApplication.sharedApplication
    doc = NSDocumentController.sharedDocumentController.currentDocument

    wc = NewTicketController.alloc.initWithWindowNibName("NewTicket")
    wc.document = doc
    app.beginSheet(
      wc.window,
      modalForWindow:doc.windowForSheet,
      modalDelegate:wc,
      didEndSelector:"newTicketSheetDidEnd:returnCode:contextInfo:",
      contextInfo:nil
    )
  end

end