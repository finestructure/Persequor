#
#  MyDocument.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 18.09.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#

require 'trac4r/trac'
require 'mytrac'
require 'keychain/keychain'
require 'logger'

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG


class MyDocument < NSPersistentDocument
  attr_accessor :accounts
  attr_accessor :account_window
  attr_accessor :column_menu
  attr_accessor :password_field
  attr_accessor :predicate_editor
  attr_accessor :previous_account
  attr_accessor :progress_bar
  attr_accessor :progress_label
  attr_accessor :refresh_button
  attr_accessor :table_view
  attr_accessor :tickets
  attr_accessor :toolbar_view


  def init
  	super
  	if (self != nil)
      @queue = Dispatch::Queue.new('de.abstracture.presequor')
  	end
    self
  end


  def windowNibName
    "MyDocument"
  end


  def windowControllerDidLoadNib(aController)
    super
    @predicate_editor.enclosingScrollView.setHasVerticalScroller(false)
    @previous_row_count = 2 # height that's configured in the nib

    init_column_menu
    init_query
    
    if core_data_account_set?
      $log.info("account is set")
      init_accounts
      init_cache_info
      init_ticket_cache
    else
      $log.info("no account")
      begin_account_sheet
    end

    # this KVO observer needs to come after the init methods (see #15)
    @accounts.addObserver(self, forKeyPath:'selection', options:0, context:nil)
    
    @table_view.setTarget(self)
    @table_view.setDoubleAction('rowAction')
  end


  # helpers
  
  
  def init_accounts
    # check if the account stored in the document ("cd_account") is also
    # present in the user defaults (@accounts array)
    # if not, add it
    cd_account = fetch_rows("Account")[0]
    # first match both desc and url
    res = @accounts.arrangedObjects.find do |a|
      a["desc"] == cd_account.desc and a["url"] == cd_account.url
    end
    if res == nil
      # now try just the url
      res = @accounts.arrangedObjects.find do |a|
        a["url"] == cd_account.url
      end
    end
    
    if res != nil
      $log.info("found matching account")
      @accounts.setSelectedObjects([res])
    else
      $log.info("no matching account, adding it to user defaults")
      account = {
        "desc" => cd_account.desc,
        "url" => cd_account.url,
        "username" => cd_account.username
      }
      @accounts.insertObject(account, atArrangedObjectIndex:0)
      @accounts.setSelectionIndex(0)
    end
  end
  
  
  def core_data_account_set?
    rows = fetch_rows("Account")
    return (rows != nil and rows.size > 0)
  end
  
  
  def begin_account_sheet
    # add a default if none are stored in the user defaults
    user_defaults_accounts = defaults("accounts")
    if user_defaults_accounts == nil or user_defaults_accounts.size == 0
        add_account(self)
    end
    # need to open the sheet with a slight delay to make sure the
    # parent window is up
    nc = NSNotificationCenter.defaultCenter
    nc.addObserverForName(
      NSWindowDidBecomeKeyNotification,
      object: self.windowForSheet,
      queue: nil,
      usingBlock: ->(notification){
        self.performSelector(
          'edit_accounts:',
          withObject: self,
          afterDelay: 0.5
        )
      }
    )
  end
  
  
  def init_column_menu
    @column_menu.removeAllItems
    @table_view.tableColumns.each do |col|
      item = NSMenuItem.alloc.initWithTitle(col.identifier,
        action:'column_menu_item_selected:', keyEquivalent:"")
      item.state = col.isHidden ? NSOffState : NSOnState
      item.enabled = true
      @column_menu.addItem(item)
    end
  end
  
  
  def defaults(key)
    defaults = NSUserDefaults.standardUserDefaults
    defaults.objectForKey(key)
  end


  def save_predicate(predicate)
    if @query == nil
      @query = NSEntityDescription.insertNewObjectForEntityForName(
        "Query",
        inManagedObjectContext:self.managedObjectContext
      )
    end
    data = NSKeyedArchiver.archivedDataWithRootObject(predicate)
    @query.predicate = data
  end


  def cache_info
    if @cache_info == nil
      @cache_info = NSEntityDescription.insertNewObjectForEntityForName(
        "CacheInfo",
        inManagedObjectContext:self.managedObjectContext
      )
    end
    return @cache_info
  end


  def default_predicate
    username = defaults("username") || ""
    predicate = NSPredicate.predicateWithFormat(
    "(owner ==[cd] \"#{username}\") and (status != \"closed\")"
    )
    return predicate
  end

  
  def fetch_rows(entity_name, predicate_string=nil)
    $log.debug("fetching rows for #{entity_name}")
    request = NSFetchRequest.fetchRequestWithEntityName(entity_name)
    raise "no request" unless request
    moc = self.managedObjectContext
    raise "no moc" unless moc
    if predicate_string
      $log.debug("setting predicate string to \"#{predicate_string}\"")
      request.predicate = NSPredicate.predicateWithFormat(predicate_string)
    end
    error = Pointer.new_with_type("@")
    rows = moc.executeFetchRequest(request, error:error)
    $log.debug("fetched #{rows.size} rows")
    return rows
  end
  
  
  def delete_rows(entity_name)
    request = NSFetchRequest.fetchRequestWithEntityName(entity_name)
    raise "no request" unless request
    request.setIncludesPropertyValues(false)
    moc = self.managedObjectContext
    raise "no moc" unless moc
    error = Pointer.new_with_type("@")
    moc.executeFetchRequest(request, error:error).each do |obj|
      moc.deleteObject(obj)
    end
  end
  
  
  def init_query
    rows = fetch_rows("Query")
    
    if rows == nil or rows == []
      predicate = default_predicate
    else
      @query = rows[0]
      data = @query.predicate
      predicate = NSKeyedUnarchiver.unarchiveObjectWithData(data)
    end
    
    @predicate_editor.setObjectValue(predicate)
    @tickets.setFilterPredicate(predicate)
    resize_window
  end


  def init_cache_info
    rows = fetch_rows("CacheInfo")
    case rows.size
    when 1
      $log.info("got cache info")
      @cache_info = rows[0]
    when 0
      $log.info("no cache info")
    else
      $log.warn("multiple entries for cache info (should not be possible)")
    end
  end


  def init_ticket_cache
    tickets = fetch_rows("Ticket")
    $log.debug("tickets loaded: #{tickets.size}")
    
    if @cache_info == nil
      updated_at = nil
    else
      updated_at = @cache_info.updated_at
    end
    
    begin
      keychain_item = keychain_item_for_account(selected_account)
      trac = Trac.new(selected_account["url"],
                      selected_account["username"],
                      keychain_item.password)
      @ticket_cache = TicketCache.new(trac, tickets, updated_at)
    rescue Exception => e
      $log.warn("failed to initialize ticket cache")
      $log.warn(e.message)
      $log.warn(e.backtrace.inspect)
    end
  end


  def resize_window
    new_row_count = @predicate_editor.numberOfRows
    
    if new_row_count == @previous_row_count
      return
    end
    
    table_scroll_view = @table_view.enclosingScrollView
    old_outline_mask = table_scroll_view.autoresizingMask
    
    predicate_editor_scroll_view = @predicate_editor.enclosingScrollView
    old_predicate_editor_mask = predicate_editor_scroll_view.autoresizingMask
    
    table_scroll_view.setAutoresizingMask(
      NSViewWidthSizable | NSViewMaxYMargin
    )
    predicate_editor_scroll_view.setAutoresizingMask(
      NSViewWidthSizable | NSViewHeightSizable
    )
    
    growing = new_row_count > @previous_row_count
    
    heightDiff = @predicate_editor.rowHeight \
      * (new_row_count - @previous_row_count)
    heightDiff = heightDiff.abs
    
    sizeChange = @predicate_editor.convertSize([0, heightDiff], toView:nil)
    
    # offset toolbar_view
    frame = @toolbar_view.frame
    @toolbar_view.setFrameOrigin(
      [frame.origin.x,
       frame.origin.y \
       - @predicate_editor.rowHeight * (new_row_count - @previous_row_count)]
    )
    
    # change window frame size
    windowFrame = self.windowForSheet.frame
    windowFrame.size.height += growing ? sizeChange.height : -sizeChange.height
    windowFrame.origin.y -= growing ? sizeChange.height : -sizeChange.height
    self.windowForSheet.setFrame(windowFrame, display:true, animate:false)
    
    table_scroll_view.setAutoresizingMask(old_outline_mask)
    predicate_editor_scroll_view.setAutoresizingMask(old_predicate_editor_mask)
    
    @previous_row_count = new_row_count
  end
  

  # actions
  
  
  def predicateEditorChanged(sender)
    save_predicate(@predicate_editor.objectValue)    
    resize_window
  end
  
  
  def start_show_progress(max_count)
    Dispatch::Queue.main.async do
      if max_count > 0
        @progress_bar.setIndeterminate(false)
        @progress_bar.setDoubleValue(0)
        @progress_bar.setMaxValue(max_count)
      else
        @progress_bar.setIndeterminate(true)
        @progress_bar.startAnimation(self)
      end
      @progress_bar.hidden = false
      @refresh_button.enabled = false
    end
      @progress_label.hidden = false
  end
  
  
  def end_show_progress
    Dispatch::Queue.main.async do
      @progress_bar.hidden = true
      @refresh_button.enabled = true
    end
      @progress_label.hidden = true
  end
  
  
  def update_ticket(ticket)
    rows = fetch_rows("Ticket", "id == #{ticket.id}")
    if rows.size == 1
      t = rows[0]
    else
      moc = self.managedObjectContext
      rows.each {|t| moc.deleteObject(t)}
      t = NSEntityDescription.insertNewObjectForEntityForName(
        "Ticket",
        inManagedObjectContext:moc
      )
    end
  
    t.id = ticket.id
    t.severity = ticket.severity
    t.milestone = ticket.milestone
    t.status = ticket.status
    t.priority = ticket.priority
    t.version = ticket.version
    t.reporter = ticket.reporter
    t.owner = ticket.owner
    t.cc = ticket.cc
    t.summary = ticket.summary
    t.desc = ticket.description
    t.keywords = ticket.keywords
    t.component = ticket.component
    t.created_at = ticket.created_at.to_time
    t.updated_at = ticket.updated_at.to_time
    return t
  end
  
  
  # alert shown for connection errors occurring during refresh
  def show_alert_for_exception(e)
    $log.warn(e)
    $log.warn(e.inspect)
    alert = NSAlert.alloc.init
    alert.addButtonWithTitle("Edit Settings")
    if e.inspect =~ /Authorization failed/
      alert.messageText = "Authorization Failure"
      alert.informativeText = "Could not log in to " \
        "#{selected_account["url"]}. Please validate your login settings."
    else
      alert.messageText = "Connection Failure"
      alert.informativeText = "Could not connect to " \
        "#{selected_account["url"]}. Please validate your login settings."
    end
    Dispatch::Queue.main.sync do
      if alert.runModal == NSAlertFirstButtonReturn
        edit_accounts(self)
      end
    end
  end
  
  
  def refresh(sender)
    $log.debug('loading tickets')
    if @is_loading
      return
    end
    @queue.async do
      @is_loading = true
      start_show_progress(0)

      init_ticket_cache if @ticket_cache == nil
      
      begin
        new_tickets = @ticket_cache.updates
        $log.debug("fetched #{new_tickets.size} updates")
        start_show_progress(new_tickets.size)
  
        new_tickets.each do |id|
          ticket = @ticket_cache.fetch(id)
          if ticket != nil
            Dispatch::Queue.main.async do
              $log.debug("loaded #{id} #{ticket}")
              @progress_bar.incrementBy(1)
              update_ticket(ticket)
            end
          end
        end
        if new_tickets.size > 0
          # don't mark dirty if there were no changes
          cache_info.updated_at = @ticket_cache.updated_at
        end
      
        # re-apply filter, a bit hacky but no other way seems to work with 
        # bindings in place
        predicate = @predicate_editor.predicate
        @tickets.setFilterPredicate(nil)
        @tickets.setFilterPredicate(predicate)
      rescue Exception => e
        show_alert_for_exception(e)
      ensure
        end_show_progress
        @is_loading = false
      end
    end
  end


  def default_button_pressed(sender)
    predicate = default_predicate
    @predicate_editor.setObjectValue(predicate)
    @tickets.setFilterPredicate(predicate)
    resize_window
  end


  def clear_button_pressed(sender)
    count = @predicate_editor.numberOfRows
    while count > 1 do
      @predicate_editor.removeRowAtIndex(count-1)
      count -= 1
    end
    @tickets.setFilterPredicate(@predicate_editor.predicate)
    resize_window
  end

  
  def column_menu_item_selected(menu_item)
    col = @table_view.tableColumnWithIdentifier(menu_item.title)
    return if col == nil
    case menu_item.state
    when NSOffState
      col.setHidden(false)
      menu_item.state = NSOnState
    when NSOnState
      col.setHidden(true)
      menu_item.state = NSOffState
    end
  end
  
  
  def keychain_item_for_account(account)
    if account != nil
      service = service_for_url(account["url"])
      username = account["username"]
      item = MRKeychain::GenericItem.item_for_service(
        service, username: username
      )
      return item
    else
      return nil
    end
  end
  
  
  def service_for_url(url)
    return "Trac: #{url}"
  end
  
  
  def selected_account
    index = @accounts.selectionIndex
    return @accounts.arrangedObjects[index]
  end
  
  
  def update_password_field
    keychain_item = keychain_item_for_account(selected_account)
    if keychain_item != nil
      @password_field.setStringValue(keychain_item.password)
    else
      @password_field.setStringValue('')
    end
  end
  
  
  def edit_accounts(sender)
    @previous_account = selected_account.dup
    app = NSApplication.sharedApplication
    app.beginSheet(
      @account_window,
      modalForWindow:self.windowForSheet,
      modalDelegate:self,
      didEndSelector:"sheetDidEnd:returnCode:contextInfo:",
      contextInfo:nil
    )
    update_password_field
  end

 
  def dismiss_sheet(sender)
    NSApplication.sharedApplication.endSheet(@account_window,
      returnCode:sender.tag)
    @account_window.close
  end
 
 
  def save_password
    service = service_for_url(selected_account["url"])
    username = selected_account["username"]
    password = @password_field.stringValue
    
    if service == nil or username == nil
      return
    end
    
    keychain_item = keychain_item_for_account(selected_account)
    if keychain_item != nil
      keychain_item.password = password
    else
      MRKeychain::GenericItem.add_item_for_service(
        service,
        username: username,
        password: password
      )
    end
    
    $log.debug("saved service \"#{service}\" in keychain")
  end
 
  
  def update_account
    index = @accounts.selectionIndex
    if index == NSNotFound
      $log.debug("nothing selected")
      return
    end

    if not core_data_account_set?
      $log.debug("create new account")
      moc = self.managedObjectContext
      account = NSEntityDescription.insertNewObjectForEntityForName(
        "Account",
        inManagedObjectContext:moc
      )
    else
      $log.debug("got account")
      account = fetch_rows("Account")[0]
    end
    
    # save selected account data to core data
    account.desc = selected_account["desc"]
    account.url = selected_account["url"]
    account.username = selected_account["username"]    
    
    # invalidate cache
    $log.debug("invalidating cache")
    delete_rows("Ticket")
    delete_rows("CacheInfo")
    init_cache_info
    init_ticket_cache
  end
 
 
  def sheetDidEnd(sheet, returnCode: returnCode, contextInfo: contextInfo)
    $log.debug("sheet ended: #{returnCode}")
    if @previous_account["url"] != selected_account["url"] or \
       @previous_account["username"] != selected_account["username"] or \
       @previous_account["password"] != selected_account["password"] or
      $log.debug("account updated")
      update_account
      save_password
    end
  end
  

  def add_account(sender)
    account = {
      "desc" => "New Account"
    }
    @accounts.insertObject(account, atArrangedObjectIndex:0)
    @accounts.setSelectionIndex(0)
  end


  # password text field delegate

  def control(control, textShouldEndEditing: editor)
    save_password
    return true
  end


  # KVO for accounts controller

  def observeValueForKeyPath(keypath, ofObject: object, change: change,
    context: context)
    if keypath == "selection"
      update_password_field
      if not @account_window.isVisible
        # only do update_account when change is triggered by popup
        # when sheet is up, it's happening in sheetDidEnd
        update_account
      end
    end
  end


  # table view action
  
  def rowAction
    $log.debug("clicked: #{@table_view.clickedRow}")
    row_index = @table_view.clickedRow
    
    return if row_index == -1
    
    ticket = @tickets.arrangedObjects[row_index]
    $log.debug("ticket: #{ticket.id}")
    
    vc = TicketWindowController.alloc.initWithWindowNibName("TicketWindow")
    vc.base_url = selected_account["url"]
    vc.ticket = ticket
    vc.showWindow(self)
  end
  
  
  # autosaving
  
  def self.autosavesInPlace
    return true
  end

end

