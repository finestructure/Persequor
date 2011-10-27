#
#  WebWindowController.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 04.10.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#


class WebWindowController < NSWindowController
  attr_accessor :progress_bar
  attr_accessor :state
  attr_accessor :stop_button
  attr_accessor :url
  attr_accessor :ticket
  attr_accessor :web_view
  
  
  def windowDidLoad
    @state = :idle
    url = NSURL.URLWithString(@url)
    request = NSURLRequest.requestWithURL(url)
    @web_view.frameLoadDelegate = self
    @web_view.mainFrame.loadRequest(request)
    self.window.makeKeyAndOrderFront(self)
  end
  
  
  def title=(title)
    self.window.title = title
  end
  
  
  def transition_to(target_state)
    case @state
    when :loading
      if target_state == :idle
        @progress_bar.hidden = true
        @stop_button.image = \
          NSImage.imageNamed(NSImageNameRefreshTemplate)
      end
    when :idle
      if target_state == :loading
        @progress_bar.hidden = false
        @stop_button.image = \
          NSImage.imageNamed(NSImageNameStopProgressTemplate)
      end
    end
    @state = target_state
  end
  

  def webView(sender, didStartProvisionalLoadForFrame:frame)
    transition_to(:loading)
  end

  
  def webView(sender, didFinishLoadForFrame:frame)
    transition_to(:idle)
  end
  
  
  def webView(sender, didFailProvisionalLoadWithError:error, forFrame:frame)
    transition_to(:idle)
  end
  
  
  def webView(sender, didFailLoadWithError:error, forFrame:frame)
    transition_to(:idle)
  end
  
  
  def reload(sender)
    @web_view.reload(sender)
  end
  
  
  def stop_reload_button(sender)
    case @state
    when :idle
      @web_view.reload(sender)
    when :loading
      @web_view.stopLoading(sender)
    end
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
