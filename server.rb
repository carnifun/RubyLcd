load  'dummy_driver.rb'

module RubyLcd
  class Request    
    require 'json'
    require 'thread'
    @@last_requests = nil
    
    
    def flash()
      message = @object.message
    end

    def initialize message
      return if message.nil?
      @object = begin
        JSON.parse(message,{:symbolize_names => true})
      rescue
        nil
      end
      if !@@last_requests 
        @@last_requests = Queue.new
      end
      @@last_requests << @object unless @object[:flash] 
    end

    def _run
      return if @@queue.size > 1
      loop do 
        sleep(5)
        puts "in the loop "
        puts "size :#{@@queue.size} "
        object = @@queue.pop
        break if @@queue.empty?
      end
    end

    def run
      require 'pry'      
      Server.kill_others()
      RubyLcd.print(@object)
      puts " ab hier ======"
      if @object[:flash]
        binding.pry
        last_request = @@last_requests.pop
        @@last_requests << last_request
        RubyLcd.print(last_request) if last_request
      end
    end
  end

  class Server
    require 'socket'
    require 'thread'
    
    STATUS_INTERUPT = 1

    def self.queue
      @queue
    end

    def self.kill_others
      @threads.each do |t|
          puts "therad with #{t}"
          puts "therad with #{t.object_id}"
          puts "Current therad with #{Thread.current.object_id}"
          Thread.kill t if (t.object_id != Thread.current.object_id)           
      end if !@threads.nil?
      @threads = [Thread.current]
    end

    def self.start

      @threads = []
      Thread::abort_on_exception = true  
      server = TCPServer.new("localhost", 2000)  # Server bind to port 2000
      loop {
        @threads << Thread.start(server.accept) do |client|
            puts "server startet"
            message = client.gets
            if !message.nil?
              r = Request.new(message)
              puts "was hier"
              responce = r.run
              #client.puts "responce"
            end
            client.close
        end
      }.join
    end
  end
end
RubyLcd::Server.start
