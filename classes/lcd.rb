module HeatController
  class Lcd
    require 'socket'

    def self.tcp_send(request)
      return true if SIM_MODE
      begin
         socket = TCPSocket.open('127.0.0.1', '2000')
         socket.print(request) # Send request
         socket.close
	 #log "sent #{request}"
         true
       rescue
         return false
       end
    end

    def self.sline(msg, row = 1)
      tcp_send "{\"text\":\"#{msg}\", \"single_line\":\"#{row}\" }\r\n"
    end

    def self.mlines(msg)
      tcp_send "{\"text\":\"#{msg}\"}\r\n"
    end

    def self.flash(msg)
      tcp_send "{\"text\":\"#{msg}\", \"flash\": \"true\"}\r\n"
    end

    def self.clear
      tcp_send "{\"command\":\"clear\"}\r\n"
   end
  end
end


=begin

module HeatController
  class Lcd
    def self.lcd_file
      return @lcd_file unless @lcd_file.nil?
      @lcd_file = File.open('/heatcontroll/lcd_tmp/lcd_file', 'w+')
    end

    def self.sline(msg, _row = 1)
      mlines(msg)
    end

    def self.mlines(msg)
      lcd_file.truncate(0)
      lcd_file.puts(msg)
      lcd_file.fsync
      #	lcd_file.close
      # @lcd_file = nil
    end
  end
end
=end
