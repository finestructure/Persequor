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
    puts "new ticket"
    doc = NSDocumentController.sharedDocumentController.currentDocument
    doc.new_ticket(sender)
  end

end