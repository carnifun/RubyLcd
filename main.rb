module RubyLcd
  class Server
    require 'socket'
    def self.start
      server = TCPServer.new 2000 # Server bind to port 2000
      loop do
        client = server.accept    # Wait for a client to connect
        client.puts "Hello !"
        client.puts "Time is #{Time.now}"
        client.close
      end
    end
  end
end