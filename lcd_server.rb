#!/usr/bin/ruby

APP_ROOT = "/heatcontroll"
load "#{APP_ROOT}/classes/logger.rb"
load "#{APP_ROOT}/driver/lcd1602_driver.rb"
#load "/mnt/win/driver/lcd1602_driver.rb"


module RubyLcd
  class Request    
    require 'json'
    require 'thread'
    @@last_requests = []
    
    def initialize message
      return if message.nil?
      @object = begin
        JSON.parse(message,{:symbolize_names => true})
      rescue
        nil
      end
      add_request @object if !@object.nil?
    end
    
    def add_request(object)
      @@last_requests.pop if @@last_requests.size >=10        
      @@last_requests << object unless object[:flash]
    end
    
    def get_extra_text(row)
      i = 0
      row = (row == BOTTOM_ROW) ? TOP_ROW : BOTTOM_ROW
      @@last_requests.reverse_each do |request|
        i +=1 
        next if i==1 # skip first request
        if request[:single_line] == row
          return request[:text]
        end
      end
      nil
    end
    
    def run
      return if @object.nil?
      Server.gracefull_stop_others()
      if @object[:single_line]
        @object[:extra_text] ||= get_extra_text(@object[:single_line]) 
      end
      if @object[:command]
        return RubyLcd.send(@object[:command])
      end
      RubyLcd.print(@object)
      if @object[:flash]
        RubyLcd.print(@@last_requests.last) unless @@last_requests.nil?
      end
    end
  end

  class Server
    require 'socket'
    
    STATUS_INTERUPT = 1
    MAIN_WAIT_INTERVAL = 0.3

    def self.get_ip
       a =  Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
       return a.ip_address unless a.nil?
       nil
    end
    def self.file_changed?      
      t = File.mtime("/heatcontroll/lcd_tmp/lcd_file")
      (@last_modification != t)              
    end
    def self.read_file
      @last_modification = File.mtime("/heatcontroll/lcd_tmp/lcd_file") 
      File.read("/heatcontroll/lcd_tmp/lcd_file")
    end
    def self.start
      log("Lcd Server gestartet")
      RubyLcd.print({text:"LCD Display ist   Bereit"})
      ip = nil
      2.times do |i|
        ip = get_ip
        if (ip)
          RubyLcd.print({text:"IP:             #{ip}"})
          log("Netzwerk IP:#{ip}")
        else
          RubyLcd.print({text:"Warte auf       Netzwerk#{ '.' * (i+1) }"})
        end
        sleep(2)
        break if ip
      end
      RubyLcd.print({text:"Kein  Netzwerk"}) unless ip
      f = File.open("/heatcontroll/lcd_tmp/lcd_file", "w+")
      f.puts " STARTEN "
      f.close
      
      
      loop do 
        if file_changed?
          message = read_file
          RubyLcd.print(message)          
        end
        sleep(MAIN_WAIT_INTERVAL)    
      end
    end
  end
end


RubyLcd::Server.start

