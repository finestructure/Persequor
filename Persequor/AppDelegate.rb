#
#  AppDelegate.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 26.09.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#


class AppDelegate
  attr_accessor :accounts
  attr_accessor :prefs_window

  def add_account(sender)
    account = {
      "desc" => "New Account"
    }
    @accounts.insertObject(account, atArrangedObjectIndex:0)
    @accounts.setSelectionIndex(0)
  end

end
