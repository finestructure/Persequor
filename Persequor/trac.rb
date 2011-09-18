#
#  trac.rb
#  Persequor
#
#  Created by Sven A. Schmidt on 18.09.11.
#  Copyright 2011 abstracture GmbH & Co. KG. All rights reserved.
#

require 'rubygems'
require 'yaml'
require 'trac4r/trac'


def tickets(trac_url, username, password)
  trac = Trac.new(trac_url, username, password)
  trac.tickets.list
  trac.query("ticket.query", "status=accepted&status=assigned&status=new&status=reopened&group=owner&col=id&col=summary&col=status&col=owner&col=type&col=priority&col=milestone&col=component&order=priority")
  trac.tickets.filter(['owner=sas', 'status!=closed'])
end


if __FILE__ == $0
  CONFIG_FILE = File.expand_path '~/.trac.yml'
  configuration = YAML.load(File.read(CONFIG_FILE))
  trac_url = configuration[:trac_url]
  username = configuration[:username]
  password = configuration[:password]
  p tickets(trac_url, username, password)
end
