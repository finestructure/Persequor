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
    doc = NSDocumentController.sharedDocumentController.currentDocument
    wc = NewTicketController.alloc.initWithWindowNibName("NewTicket")
    wc.begin_sheet_for_document(doc)
  end

end