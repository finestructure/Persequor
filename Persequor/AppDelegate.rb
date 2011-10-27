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
    if doc != nil
      doc.refresh(sender)
    else
      key_window = NSApplication.sharedApplication.keyWindow
      wc = key_window.windowController
      if wc.respondsToSelector('reload:')
        wc.reload(sender)
      end
    end
  end
  
  
  def new_ticket(sender)
    doc = NSDocumentController.sharedDocumentController.currentDocument
    wc = NewTicketController.alloc.initWithWindowNibName("NewTicket")
    wc.begin_sheet_for_document(doc, ticket_cache:doc.ticket_cache)
  end


  def base_url
    doc = NSDocumentController.sharedDocumentController.currentDocument
    if doc != nil
      return doc.ticket_cache.url
    else
      # one of the other windows not associated with a document is key
      # we have to figure out which document it belongs to
      key_window = NSApplication.sharedApplication.keyWindow
      wc = key_window.windowController
      # get the full url of key window (if it has one)
      begin
        current_url = wc.url
      rescue
        current_url = ""
      end
    
      doc = NSDocumentController.sharedDocumentController.documents.find do |d|
        # pick the document with matches the beginning of the full url:
        # that's the base url we're looking for
        current_url.start_with?(d.ticket_cache.url)
      end
        
      if doc != nil
        return doc.ticket_cache.url
      end
    end
    
    return nil
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
    
    vc = WebWindowController.alloc.initWithWindowNibName("WebWindow")
    vc.url = "#{base_url}/#{page.downcase}"
    vc.title = page
    vc.showWindow(self)
  end


  def validateMenuItem(menuItem)
    if ['Wiki', 'Timeline', 'Roadmap', 'Search'].include?(menuItem.title)
      # only activate menu items if we can obtain a base url
      return base_url != nil
    else
      return true
    end
  end

end