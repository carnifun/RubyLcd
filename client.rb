module RubyLcd
  class Client
    require 'socket'
   def self.send request 
      socket = TCPSocket.open("127.0.0.1","2010")
      socket.print(request)               # Send request
      socket.close
    end
    #def self.method_missing(method_name, *arguments, &block)
    #  puts "needs this class method#{method_name}"
    #end
    
    def self.warning      
      send "{\"command\":\"warning\"}\r\n"
    end
    def self.okay      
      send "{\"command\":\"okay\"}\r\n"
    end
    def self.error      
      send "{\"command\":\"error\"}\r\n"
    end
    def self.action      
      send "{\"command\":\"action\"}\r\n"
    end
    def self.off      
      send "{\"command\":\"all_off\"}\r\n"
    end
    def self.led(command)
      send "{\"command\":\"#{command}\"}\r\n"
    end
     def self.funny
      send "{\"command\":\"funny\", \"infinity\":\"true\"}\r\n"
    end
    
    def self.single_line(msg="singel line message ffrom client ", row = 1 )

      request = "{\"text\":\"#{msg}\", \"single_line\":\"#{row}\" }\r\n"

      socket = TCPSocket.open("127.0.0.1","2000")
      socket.print(request)               # Send request
      #response = socket.read              # Read complete response
      # Split response at first blank line into headers and body
      socket.close
      #puts response
    end
    def self.beuteln(msg="das ist ein Beutel", row = 1 )

      request = "{\"text\":\"#{msg}\", \"single_line\":\"#{row}\" }\r\n"

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
     def self.clear()

      request = "{\"command\":\"clear\"}\r\n"

      socket = TCPSocket.open("127.0.0.1","2000")
      socket.print(request)               # Send request
      #response = socket.read              # Read complete response
      # Split response at first blank line into headers and body
      socket.close
      #puts response
    end
  end
end
