module RubyLcd
  class Client
    require 'socket'

    def self.single_line(msg="singel line message ffrom client ")

      request = "{\"text\":\"#{msg}\", \"single_line\":\"true\" }\r\n"

      socket = TCPSocket.open("127.0.0.1","2000")
      socket.print(request)               # Send request
      #response = socket.read              # Read complete response
      # Split response at first blank line into headers and body
      socket.close
      #puts response
    end
    def self.multiple_lines(msg="default pages multiline message from client")

      request = "{\"text\":\"#{msg}\"}\r\n"

      socket = TCPSocket.open("127.0.0.1","2000")
      socket.print(request)               # Send request
      #response = socket.read              # Read complete response
      # Split response at first blank line into headers and body
      socket.close
      #puts response
    end
    
    def self.flash(msg="flashing some messages ")

      request = "{\"text\":\"#{msg}\", \"flash\": \"true\"}\r\n"

      socket = TCPSocket.open("127.0.0.1","2000")
      socket.print(request)               # Send request
      #response = socket.read              # Read complete response
      # Split response at first blank line into headers and body
      socket.close
      #puts response
    end
  end
end
