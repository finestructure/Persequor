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


class MyDocument < NSPersistentDocument
  attr_accessor :accounts
  attr_accessor :account_popup
  attr_accessor :account_window
  attr_accessor :column_menu
  attr_accessor :password_field
  attr_accessor :predicate_editor
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
    
    accounts = defaults("accounts")
    if accounts == nil or accounts.size == 0
      add_account(self)
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
    else
      init_cache_info
      init_ticket_cache
    end
  end


  # helpers
  
  
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

  
  def fetch_rows(entity_name)
    request = NSFetchRequest.fetchRequestWithEntityName(entity_name)
    raise "no request" unless request
    moc = self.managedObjectContext
    raise "no moc" unless moc
    error = Pointer.new_with_type("@")
    rows = moc.executeFetchRequest(request, error:error)
    return rows
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
    if rows != []
      @cache_info = rows[0]
    end
  end


  def init_ticket_cache
    tickets = fetch_rows("Ticket")
    puts "tickets loaded: #{tickets.size}"
    
    if @cache_info == nil
      updated_at = nil
    else
      updated_at = @cache_info.updated_at
    end
    
    begin
      trac = Trac.new(defaults("tracUrl"),
                      defaults("username"),
                      defaults("password"))
      @ticket_cache = TicketCache.new(trac, tickets, updated_at)
    rescue
      puts "failed to initialize ticket cache"
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
  
  
  def create_entity(ticket)
    moc = self.managedObjectContext
    t = NSEntityDescription.insertNewObjectForEntityForName(
      "Ticket",
      inManagedObjectContext:moc
    )
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
  
  
  def refresh(sender)
    puts 'loading tickets'
    if @is_loading
      return
    end
    @queue.async do
      @is_loading = true
      start_show_progress(0)

      new_tickets = @ticket_cache.updates
      start_show_progress(new_tickets.size)

      new_tickets.each do |id|
        ticket = @ticket_cache.fetch(id)
        if ticket != nil
          Dispatch::Queue.main.async do
            puts "loaded #{id} #{ticket}"
            @progress_bar.incrementBy(1)
            create_entity(ticket)
          end
        end
      end
      if new_tickets.size > 0
        # don't mark dirty if there were no changes
        cache_info.updated_at = @ticket_cache.updated_at
      end
      
      end_show_progress
      @is_loading = false
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
  
  
  def account_selected(sender)
    puts "account selected"
  end
  
  
  def keychain_item_for_account(account)
    service = service_for_url(account["url"])
    username = account["username"]
    item = MRKeychain::GenericItem.item_for_service(
      service, username: username
    )
    return item
  end
  
  
  def service_for_url(url)
    return "Trac: #{url}"
  end
  
  
  def update_password_field
    index = @accounts.selectionIndex
    selected_account = @accounts.arrangedObjects[index]
    keychain_item = keychain_item_for_account(selected_account)
    if keychain_item != nil
      @password_field.setStringValue(keychain_item.password)
    end
  end
  
  
  def edit_accounts(sender)
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
    index = @accounts.selectionIndex
    selected_account = @accounts.arrangedObjects[index]
    
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
    
    puts "saved service \"#{service}\" in keychain"
  end
 
 
  def sheetDidEnd(sheet, returnCode: returnCode, contextInfo: contextInfo)
    puts "sheet ended: #{returnCode}"
    index = @accounts.selectionIndex
    if index == NSNotFound
      puts "nothing selected"
      return
    else
      puts "create new account"
      moc = self.managedObjectContext
      a = NSEntityDescription.insertNewObjectForEntityForName(
        "Account",
        inManagedObjectContext:moc
      )
      selected_account = @accounts.arrangedObjects[index]
      a.desc = selected_account["desc"]
      a.url = selected_account["url"]
      a.username = selected_account["username"]
      
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


  # table view delegate

  def tableViewSelectionDidChange(aNotification)
    puts "updating password field"
    update_password_field
  end



end

