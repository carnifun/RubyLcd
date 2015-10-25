#!/usr/bin/ruby




  
  class Server
    require 'socket'
    require 'thread'
    
    STATUS_INTERUPT = 1
    def threads
      @threads || [] 
    end
    def self.kill_others
      @threads.each do |t|
          Thread.kill t if (t.object_id != Thread.current.object_id)           
      end if !@threads.nil?
      @threads = [Thread.current]
    end
    def self.start    
      @threads = []
      Thread::abort_on_exception = true  
      server = TCPServer.new("localhost", 5000)  # Server bind to port 2000
      loop {
        @threads << Thread.start(server.accept) do |client|

          puts " Thread count = #{Thread.list}"
           @threads.each do |t|
             next unless t.alive?
            puts "passing variable to #{t.object_id}"
            
            if (t.object_id != Thread.current.object_id)          
              t["my_var"] = Time.now.to_s
              puts t.value
            end 
           end if !@threads.nil?       

            message = client.gets
            #puts "server got message #{message} "
            if !message.nil?
              puts message
              loop do 
                sleep 1 
                puts " I am trapped #{Thread.current["my_var"]}"
                if Thread.current["my_var"]
                  puts " parent is waiting 2 sconds "
                  sleep (2)
                  "last value"
                  Thread.current.exit 
                end                  
              end
            end
            client.close
        end
      }.join
    end
  end


Signal.trap('INT') do|_signo|
  puts "got interrupt"
  exit(0)
end
Signal.trap('KILL') do|_signo|
  
  puts "got KILL"
  exit(0)
end

Signal.trap('TERM') do|_signo|
  puts "got TErm"
  exit(0)
end

Server.start

