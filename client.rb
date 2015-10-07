module RubyLcd
  class Client
    require 'socket'

    def self.test

      request = "{\"boo\":\"10\"}\r\n"

      socket = TCPSocket.open("127.0.0.1","2000")
      socket.print(request)               # Send request
      #response = socket.read              # Read complete response
      # Split response at first blank line into headers and body
      socket.close
      #puts response
      puts "done"
    end
  end
end
