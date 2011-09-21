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
require 'dispatch'


CONFIG_FILE = File.expand_path '~/.trac.yml'


class Array
  def parallel_map(&block)
    result = []
    # Creating a group to synchronize block execution.
    group = Dispatch::Group.new
    # We will access the `result` array from within this serial queue,
    # as without a GIL (Global Interpreter Lock) we cannot assume array access to be thread-safe.
    result_queue = Dispatch::Queue.new('access-queue.#{result.object_id}')
    0.upto(self.size) do |idx|
      # Dispatch a task to the default concurrent queue.
      Dispatch::Queue.concurrent.async(group) do
        temp = block[self[idx]]
        result_queue.async(group) { result[idx] = temp }
      end
    end
    # Wait for all the blocks to finish.
    group.wait
    result
  end
end


class TestNet < Test::Unit::TestCase

  def setup
    configuration = YAML.load(File.read(CONFIG_FILE))
    trac_url = configuration[:trac_url]
    username = configuration[:username]
    password = configuration[:password]
    @trac = Trac.new(trac_url, username, password)
  end


  def test_threaded_load_1
    result = []
    
    ids = @trac.tickets.filter(['status!=closed'])
    n_queues = 4

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
      assert_equal(id, result[index].id)
    end
  end


  def _test_threaded_load_2
    result = []
    
    ids = @trac.tickets.filter(['status!=closed'])
    result = ids.parallel_map{ |id| @trac.tickets.get(id) }
    
    assert_equal(ids.size, result.size)
    ids.each_with_index do |index, id|
      p result[index]
      assert_equal(id, result[index].id)
    end
  end


  # segfaults for n_queue > 1
  def _test_threaded_load_3
    job = Dispatch::Job.new
  
    @result = job.synchronize(Array.new)
    
    ids = @trac.tickets.filter(['status!=closed'])
    orig = ids.dup
    
    n_queues = 4
    while ids.size > 0
      n_queues.times do
        id = ids.pop
        if id != nil
          job.add{ 
            #puts "loaded #{id}"
            @result << @trac.tickets.get(id)
          }
        end
      end
      job.join
    end
    
    assert_equal(orig.size, @result.size)
    orig.each_with_index do |index, id|
      #p @result[index]
      assert_equal(id, @result[index].id)
    end
  end


end

