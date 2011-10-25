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
    wc.begin_sheet_for_document(doc, ticket_cache:doc.ticket_cache)
  end


  def show_page(sender)
    case sender.tag
    when 1
      page = 'Wiki'
    when 2
      page = 'Timeline'
    when 3
      page = 'Roadmap'
    when 4
      page = 'Search'
    else
      return
    end
    
    doc = NSDocumentController.sharedDocumentController.currentDocument
    base_url = doc.ticket_cache.url
    url = NSURL.URLWithString("#{base_url}/#{page.downcase}")
    vc = WebWindowController.alloc.initWithWindowNibName("WebWindow")
    vc.url = url
    vc.title = page
    vc.showWindow(self)
  end


  def validateMenuItem(menuItem)
    if ['Wiki', 'Timeline', 'Roadmap', 'Search'].include?(menuItem.title)
      # deactivate menu when there's no document associated (i.e. we're
      # not focused on the document window)
      doc = NSDocumentController.sharedDocumentController.currentDocument
      return doc != nil
    end
  end

end