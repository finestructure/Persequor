#
#  WebWindowController.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 04.10.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#


class WebWindowController < NSWindowController
  attr_accessor :progress_bar
  attr_accessor :stop_button
  attr_accessor :url
  attr_accessor :ticket
  attr_accessor :web_view
  
  
  def windowDidLoad
    url = NSURL.URLWithString(@url)
    request = NSURLRequest.requestWithURL(url)
    @web_view.frameLoadDelegate = self
    @web_view.mainFrame.loadRequest(request)
    self.window.makeKeyAndOrderFront(self)
  end
  
  
  def title=(title)
    self.window.title = title
  end
  

  def webView(sender, didStartProvisionalLoadForFrame:frame)
    @progress_bar.hidden = false
    @stop_button.hidden = false
  end

  
  def webView(sender, didFinishLoadForFrame:frame)
    @progress_bar.hidden = true
    @stop_button.hidden = true
  end
  
  
  def back_forward_selector(sender)
    case sender.selectedSegment
    when 0
      @web_view.goBack
    when 1
      @web_view.goForward
    end
  end
  
end
