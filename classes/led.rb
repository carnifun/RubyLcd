module HeatController 
  
  class Led
    require 'socket'
    def self.tcp_send request
      return true if SIM_MODE 
      begin
        socket = TCPSocket.open("127.0.0.1","2010") 
        socket.print(request)               # Send request
        socket.close
        true      
      rescue
        false
      end
    end
    
    def self.method_missing(method_name, *arguments, &block)
      tcp_send "{\"command\":\"#{method_name}\"}\r\n"
    end
  
    def self.loading      
      tcp_send "{\"command\":\"funny\", \"infinity\":\"true\"}\r\n"
    end       
    def self.fatal_error
      tcp_send "{\"command\":\"error\", \"infinity\":\"true\"}\r\n"
    end
  end
end