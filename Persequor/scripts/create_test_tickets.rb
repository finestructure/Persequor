#!/usr/bin/env macruby

require 'rubygems'
require 'trac4r/trac'

TRAC_URL = "http://localhost:8080"
USER = "admin"
PASS = "admin"

if __FILE__ == $0
  trac = Trac.new(TRAC_URL, USER, PASS)
  trac.tickets.list.each{ |id| trac.tickets.delete(id) }
  (1..20).each{ |i| trac.tickets.create("test #{i}", "description #{i}") }
end