module HeatController
  APP_ROOT = File.dirname(__FILE__)
  
  class Lcd
    require 'socket'
    def self.sline(msg, row = 1 )
      request = "{\"text\":\"#{msg}\", \"single_line\":\"#{row}\" }\r\n"
      socket = TCPSocket.open("127.0.0.1","2000")
      socket.print(request)               # Send request
      socket.close
    end
    
    def self.mlines(msg)
      request = "{\"text\":\"#{msg}\"}\r\n"
      socket = TCPSocket.open("127.0.0.1","2000")
      socket.print(request)               # Send request
      socket.close
    end
         
    def self.flash(msg)
      request = "{\"text\":\"#{msg}\", \"flash\": \"true\"}\r\n"
      socket = TCPSocket.open("127.0.0.1","2000")
      socket.print(request)               # Send request
      socket.close
    end
     def self.clear()
      request = "{\"command\":\"clear\"}\r\n"
      socket = TCPSocket.open("127.0.0.1","2000")
      socket.print(request)               # Send request
      socket.close
    end
    
  end
  
  class ConfigReader
    
    class << self
      @config = nil            
      def read_config_file
          @config = json_from_file(File.join(APP_ROOT, "config","config.json")) 
          if @config.nil? 
            Lcd.mlines("Konfiguration konnte nicht gefunden werden , versuche default Configuration zu laden")          
            sleep(2)
            @config = json_from_file(File.join(APP_ROOT, "config","config..default.json")) 
            if @config.nil?
              Lcd.mlines("Keine Konfiguration gefunden Programm wird gestoppt")
              exit()
            end
          end
        end
      def json_from_file ( file )
        content = File.read(file) if File.exists?(file)
        json_from_content(content) unless content.nil?
      end  
      def json_from_content(content)
        require 'json'
        return begin
          JSON.parse(content,{:symbolize_names => true})
        rescue
          nil
        end
      end
      def reload_config
        require 'digest/md5'      
        content = File.read("/media/usb/config.json")
        md5 = Digest::MD5.hexdigest(content)
        if File.exists?(File.join(APP_ROOT, "config",md5))       
          Lcd.mlines("Konfiguration ist breits aktuell")
          sleep(2)
          return  
        end
        if json_from_content(content).nil?
          Lcd.mlines("Konfiguration    ist FEHLERHAFT")
          sleep(2)
          return 
        end
        File.open(File.join(APP_ROOT, "config",md5), "w+") do |f |
          f.puts content
        end
        File.open(File.join(APP_ROOT, "config","config.json"), "w+") do |f |
          f.puts content
        end
        read_config_file
      end
      def detect_usb_drive
         # first check if we have the sda? directory 
         usb_path = ""
         Dir["/dev/disk/by-uuid/*"].each do | f |
           if  File.realpath(f).match(/\/dev\/sd[a-z]\d/)
            usb_path = f 
            break;
           end  
         end
         
         if File.exists?(usb_path)
           puts "dir found "
           Lcd.mlines("Usb erkannt")
           sleep(1)         
           system("unmount /media/usb")
           system("mount #{usb_path} /media/usb")
           Lcd.mlines("Usb-media       Wird gelesen")
           sleep(2)
           if File.exists?("/media/usb/config.json")           
            Lcd.mlines("Konfig Datei  gefunden")
            return true
           else
            Lcd.mlines("config.json     NICHT gefunden!")           
           end
         else
           puts "was hier "
           Lcd.mlines("Kein Usb erkannt")
           sleep(5)           
           puts " was hier 2 "
         end
         false
        end    
      def config
        return @config
      end
    end  
  end


  class MainController
    class << self
      
      
      def read_sensor_temperatur(sensor_id)       
         content = File.read("/sys/bus/w1/devices/#{sensor_id}/w1_slave") 
         t = 0
         if (m = content.match(/t=(\d+)/))
           t = m[1]
         end
         t.to_f/1000          
      end
      def _read_temperature 
        loop do
         t=[]
         ["10-000802c68099", "10-000802bf0598"].each_with_index do |id, i |
           t[i] = read_sensor_temperatur(id)  
          if t[i]<1           
            Lcd.mlines("Achtung Sensor #{i} Ausgefallen")
            sleep(3)
          else
            Lcd.sline("S#{i}:#{sprintf('%.2f',t[i])} C",2)
          end 
          sleep(1)
         end
        end  
      end
      def read_temperature 
        config = ConfigReader.config
        temp_data={}
        loop do
         config[:sensors].each do |s |
          temp_data[s[:id]] = read_sensor_temperatur(s[:id])  
          if temp_data[s[:id]]<1           
            Lcd.mlines("Achtung Sensor #{s[:name]} ist Ausgefallen")
            sleep(3)
          else
            Lcd.sline("S#{s[:name]}:#{sprintf('%.2f',t[i])} C",2)
          end
          s[:last_temperature] = temp_data[s[:id]]
          sleep(1)
         end
        end  
        temp_data
      end
      def get_sensor (s_id)
       config[:sensors].each do |s |
         return s if s[:id] == s_id
       end
      end
      def wait_for_lcd_server
        loop do
          begin 
            Lcd.sline("Bitte warten",1)
            Lcd.sline("Server wird gestartet", 2)
            sleep(2)
            return true
          rescue
            sleep(5)
          end  
        end  
      end
      def sensor_name_to_id (name) 
        config = ConfigReader.config
        
        config[:sensors].each do |s |
          return s[:id] if s[:name] == name
        end
      end
      def rule_fullfilled ( rule, temp_data )
        # prepare the conditions 
        and_condition = rule[:and_conditions].map do | condition |
          s_id = sensor_name_to_id(condition[:sensor])
          s = get_sensor(s_id)
          variation = condition[:tolerance]
          variation = (temp_data[s_id] - s[:last_temperature]).abs unless s[:last_temperature].nil? 
          " ( #{temp_data[s_id]} #{condition[:comparator]} '#{condition[:value]}'.to_f ) and ( #{variation} >= #{condition[:tolerance]} ) "
        end.join(" and ") if rule[:and_conditions]
        
        or_condition = rule[:or_conditions].map do | condition |
          s_id = sensor_name_to_id(condition[:sensor])
          " ( #{temp_data[s_id]} #{condition[:comparator]} '#{condition[:value]}'.to_f ) "
        end.join(" OR ") if rule[:or_conditions]        
        condition = [and_condition, or_condition].compact.join(" or ") 
        puts " MEIN CONDITON "
        puts condition
        sleep(1)
        eval " (#{condition}) ? true : false "
      end
      
      def perform_action (actuator, action)
        
      end
      
      
      def run
        wait_for_lcd_server
        ConfigReader.read_config_file
        ConfigReader.reload_config if ConfigReader.detect_usb_drive 
        # main loop
        config = ConfigReader.config
        loop do         
          temp_data = read_temperature
        # get the rules 
          config[:actuators].each do | actuator |
            a[:rules].each do | rule |
              perform_action(actuator, rule[:action]) if rule_fullfilled(rule, temp_data)
            end          
          end
          sleep(5)
        end        
      end  
    end
  end
end

HeatController::MainController.run
