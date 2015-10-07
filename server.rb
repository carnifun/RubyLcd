module RubyLcd
  class Request
    require 'json'
    require 'thread'
    def flash()
      message = @object.message

    end

    def initialize message
      return if message.nil?
      @object = begin
        JSON.parse(message)
      rescue
        nil
      end
      @@queue ||= Queue.new
      @@queue << @object
    end

    def run
      return if @@queue.size > 1

      loop do 
        sleep(5)
        puts "in the loop "
        puts "size :#{@@queue.size} "
        object = @@queue.pop
        break if @@queue.empty?
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

    def tee
      Signal.trap('DINT') do|_signo|
        @status = STATUS_INTERUPT
        puts "@threads.count"
        puts @threads.count
        @threads.each do |t|
          puts "therad with #{t}"
          puts "is alive #{t.alive?}"
        end
      end
    end

    def self.start

      @threads = []

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
          Thread.kill self
        end
      }.join
    end
  end
end
RubyLcd::Server.start
