#
#  TicketWindowController.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 04.10.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#


class TicketWindowController < NSWindowController
  attr_accessor :base_url
  attr_accessor :ticket
  attr_accessor :web_view
  
  def windowDidLoad
    puts "windowDidLoad #{self.window}"
    self.window.title = "Ticket #{@ticket.id}"
    url = NSURL.URLWithString("#{@base_url}/ticket/#{@ticket.id}")
    request = NSURLRequest.requestWithURL(url)
    @web_view.mainFrame.loadRequest(request)
    self.window.makeKeyAndOrderFront(self)
  end
  
end
