#!/usr/bin/ruby

class Server
  require 'socket'
  require 'thread'
  @@threads = []
  STATUS_INTERUPT = 1

  def self.sleep_or_die(wait_s)
    step = 0.2
    t = 0
    loop do
      Thread.current.kill if Thread.current['KILL']
      break if t >= wait_s
      t += step
      sleep(step)
    end
  end

  def self.run(_message)
    gracefull_stop_others
    # wait to get kill var
    sleep(0.2)
    Thread.current.kill if Thread.current['KILL']
    loop do
      10.times do |i|
        puts "Run loop(#{i}) working on  >#{Thread.current['message']}< "
        # puts "Run loop(#{i}) >#{Thread.current.object_id}< Killed => #{Thread.current["KILL"]} alive => #{Thread.current.alive?} Stopped => #{Thread.current.stop?}"
        sleep_or_die(0.8)
      end
      Thread.current.kill if Thread.current['KILL']
    end
  end

  def self.threads
    @@threads || []
  end

  def self.gracefull_stop_others
    puts ' Start killing  '
    puts " We are in Thread ===>#{Thread.current.object_id}<=== Count = #{Thread.list.length}"
    Thread.list.each do |t|
      if t.object_id != Thread.current.object_id && t.object_id != Thread.main.object_id
        t['KILL'] = 'SET'
      end
    end
    # @@threads = [Thread.current]
  end

  def self.start
    @@threads = []
    Thread.abort_on_exception = true
    server = TCPServer.new('localhost', 2000) # Server bind to port 2000
    loop do
      @@threads << Thread.start(server.accept) do |client|
        message = client.gets
        # puts "server got message #{message} "
        unless message.nil?
          # #client.puts "responce"
          Thread.current['message'] = message
          run (message)
        end
        client.close
      end
    end.join
  end
  end

Server.start
