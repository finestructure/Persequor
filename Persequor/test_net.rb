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
require 'test/unit'


CONFIG_FILE = File.expand_path '~/.trac.yml'



class TestNet < Test::Unit::TestCase

  def setup
    configuration = YAML.load(File.read(CONFIG_FILE))
    trac_url = configuration[:trac_url]
    username = configuration[:username]
    password = configuration[:password]
    @trac = Trac.new(trac_url, username, password)
  end


  def test_threaded_load
    result = []
    
    ids = @trac.tickets.filter(['status!=closed'])
    n_queues = 10

    res_group = Dispatch::Group.new
    res_queues = []
    n_queues.times do |i|
       res_queues << Dispatch::Queue.new("res-queue-#{i}")
    end
    
    group = Dispatch::Group.new
    queues = []
    n_queues.times do |i|
      queues << Dispatch::Queue.new("queue-#{i}")
    end
  
    ids.each do |id|
      queue_id = id % n_queues
      queues[queue_id].async(group) do
        t = @trac.tickets.get(id)
        res_queues[queue_id].async(group) do
          result << t
          # puts "loaded #{id}"
        end
      end
    end
    group.wait
    res_group.wait
    
    assert_equal(ids.size, result.size)
    ids.each_with_index do |index, id|
      #p result[index]
      #assert_equal(id, result[index].id)
    end
  end


end

