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

      socket = TCPSocket.open("127.0.0.1","13666")
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
    
    def self.mlines(msg="default pages multiline message from client")
      puts " start"
      socket = TCPSocket.open("localhost","13666")
      socket.print("hello\n")
      puts " waiting for responce "
      response = socket.read 
      puts responce
      sleep(1)
      socket.print("screen_add heat_s\n")
            response = socket.read 
      puts responce
      sleep(1)
      socket.print("widget_add heat_s Page string\n")
            response = socket.read 
      puts responce
      sleep(1)
      socket.print("widget_set heat_s Name 1 1 \" Das ist meine Nachricht \"\n")
            response = socket.read 
      puts responce
      sleep(1)
      socket.print("widget_set heat_s Name 2 1 \" Status \"\n")
      socket.close
      #puts response
    end
    
    
  end
end
=begin
 
 kleine sensoren 

 "sensors": [
    {
      "name": "s1",
      "description": "Sensor an der Therme 1 ",
      "id": "10-000802c68099"
    }, {
      "name": "s2",
      "description": "Sensor am uv-pumpe 2 ",
      "id": "10-000802bf0598"
    }
  ]
  
  
  widget_set heat_s w1 1 1 "From second screen "

hello
connect LCDproc 0.5.x protocol 0.3 lcd wid 16 hgt 2 cellwid 5 cellhgt 8
screen_add heat_s -priority 0
huh? Usage: screen_add <screenid>
screen_add heat_s
success
listen heat_s
widget_add heat_s w1
huh? Usage: widget_add <screenid> <widgetid> <widgettype> [-in <id>]
widget_add heat_s w1 scroller
success
widget_set heat_s w1 "mein Text"
huh? Wrong number of arguments
wiget_set heat_s w1 string " das ist mein langer Text"
huh? Invalid command "wiget_set"
widget_set heat_s w1 string " das ist mein langer Text"
huh? Wrong number of arguments
widget_set heat_s w1 string 1 1 " das ist mein langer Text"
huh? Wrong number of arguments
widget_add heat_s Name string
success
widget_set heat_s Name 1 1 " meine daten "
success


s.print (" 

hello
screen_add Screen01
screen_set Screen01 -priority 0
widget_add Screen01 Number string
widget_add Screen01 Name string
widget_set Screen01 Number 1 1 "Dies ist zeile eins"
widget_set Screen01 Name 1 2 "Dies ist zeile zwei"")
=end