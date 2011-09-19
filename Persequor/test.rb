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
require 'thread'


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


def tickets(trac_url, username, password)
  version = 3
  puts "version: #{version}"

  trac = Trac.new(trac_url, username, password)

  case version
  
  when 1
    trac.tickets.filter(['status!=closed']).each do |id|
      trac.tickets.get(id)
      puts "loaded #{id}"
    end

  when 2
    trac.tickets.filter(['status!=closed']).parallel_map do |id|
      trac.tickets.get(id)
      puts "loaded #{id}"
    end

  when 3
    n_worker = 3
    group = Dispatch::Group.new
    queues = []
    n_worker.times do |i|
      queues << Dispatch::Queue.new("queue-#{i}")
    end
  
    trac.tickets.filter(['status!=closed']).each do |id|
      queue_id = id % n_worker
      queues[queue_id].async(group) do
        trac.tickets.get(id)
        puts "loaded #{id}"
      end
    end
    group.wait
    
  when 4
  
    queue = Queue.new
    threads = []

    trac.tickets.filter(['status!=closed']).each{ |id| queue << id }

    4.times do
      threads << Thread.new do
        until queue.empty?
          id = queue.pop(true) rescue nil
          if id
            trac.tickets.get(id)
            puts "loaded #{id}"
          end
        end
      end
    end

    threads.each { |t| t.join }
    
  end
end


if __FILE__ == $0
  CONFIG_FILE = File.expand_path '~/.trac.yml'
  configuration = YAML.load(File.read(CONFIG_FILE))
  trac_url = configuration[:trac_url]
  username = configuration[:username]
  password = configuration[:password]
  tickets(trac_url, username, password)
end
