module HeatController
  require "wiringpi"
  APP_ROOT = File.dirname(__FILE__)
  
  def log(msg)
    Logger.log(msg)
  end
  def log_error(msg)
    Logger.log_error(msg)
  end
  
  class Logger
    class << self
      @@initialized = false        
      def initialized?
        @@initialized
      end
      def init
        @@initialized = true
        @@logger_handler =  File.open(File.join(APP_ROOT, "heat_controll.log"), "w+")         
      end
      
      def log(message)
        @@logger_handler.puts("[#{Time.now.strftime("%d.%m.%Y %H:%M:%S")}][INFO ]:#{message}\n")        
      end
      def log_error(message)
        @@logger_handler.puts("[#{Time.now.strftime("%d.%m.%Y %H:%M:%S")}][ERROR]:#{message}\n")        
      end
    end 
    
  end
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
  class RelaisCard
    # Wiring pins 
    # model B+ 
    # CHANNES ar numbered from 1 to 4 
    CHANNES = [ 3, 12, 13, 14 ]
    # model A+ 
    #CHANNES = [-1,  21 , 22, 23, 24 ]
    @@initialized = false
    HIGH = 1 
    LOW = 1     
    class << self
      
      def initialized?
        @@initialized
      end
      def init
        @@initialized = true
        CHANNES.each do | c |
          Wiringpi.pinMode(c, 1)
        end
      end  
      def get_state(actuator)
        Wiringpi.digitalRead(actuator[:channel].to_i + 1)        
      end    
      def action (channel, a)
        return if channel.nil? or channel.empty?
        channel = channel.to_i  + 1 
        return if  channel >3 or channel < 0 
        pin = CHANNES[channel]
        old_state = Wiringpi.digitalRead (pin)
        new_state = (a=="on") ? HIGH : LOW
        if old_state != new_state
          Wiringpi.digitalWrite(pin, new_state)
          log("Kanal #{channel}  wurde auf #{a} gesetzt" )
          true
        end  
        false
      end
      def on(channel) 
        action(channel, "on")
      end
      def off(channel) 
        action(channel, "off")
      end      
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
      @sensor_data={}
      
      def read_sensor_temperatur(sensor_id)       
         content = File.read("/sys/bus/w1/devices/#{sensor_id}/w1_slave") 
         t = 0
         if (m = content.match(/t=(\d+)/))
           t = m[1]
         end
         t.to_f/1000          
      end
      def update_status_line
        config = ConfigReader.config
        status =" " 
        config[:sensors].each do | s |
          status +="#{s[:name]}:#{@sensor_data[s[:id]]} "
        end
        
        config[:actuators].each do | actuator |
          state = RelaisCard.get_state(actuator)
          status +="#{actuator[:name]}:#{state==1?"An":"Aus"} "
        end
        
      end
      
      def read_temperature
        config = ConfigReader.config
        @sensor_data={}
        config[:sensors].each do |s |
          @sensor_data[s[:id]] = read_sensor_temperatur(s[:id])
          if @sensor_data[s[:id]]<1
            Lcd.mlines("Achtung Sensor #{s[:name]} ist Ausgefallen")
            sleep(3)
          else
            Lcd.sline("S#{s[:name]}:#{sprintf('%.2f',t[i])} C",2)
            sleep(1)
          end
          s[:last_temperature] = @sensor_data[s[:id]]
        end
      end
      def get_sensor (s_id)
       config[:sensors].each do |s |
         return s if s[:id] == s_id
       end
      end
      def wait_for_lcd_server
        loop do
          begin 
            Lcd.mlines("Server wird gestartet", 2)
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
      
      def compose_condition_from_rule (rule, und= true)        
        rule_conditions = _und ?  rule[:and_conditions] : rule[:or_conditions]        
        rule_conditions.map do | condition |
          s_id = sensor_name_to_id(condition[:sensor])
          variation_condition = if condition[:tolerance]
            variation = condition[:tolerance]            
            if rule[:last_temperature] && rule[:last_temperature][s_id]
              variation = (@sensor_data[s_id] - rule[:last_temperature][s_id]).abs 
              "  #{variation} >= #{condition[:tolerance]}  "
            else
              nil
            end  
          end 
          c = [" #{@sensor_data[s_id]} #{condition[:comparator]} '#{condition[:value]}'.to_f  ", 
            variation_condition].compact.join(" and ")
            
          "( #{c} )"  
        end.join( _und ?  " and " : " or ") if rule_conditions
                
        
        
      end
      
      def save_rule_temperature (rule)
        (rule[:and_conditions] + rule[:or_conditions]).each do | condition |
          s_id = sensor_name_to_id(condition[:sensor])
          rule[:last_temperature] = {} if rule[:last_temperature].nil?          
          rule[:last_temperature][s_id] = @sensor_data[s_id] 
        end
        true
      end
      
      def rule_fullfilled ( rule )
        # prepare the conditions 
        and_condition = compose_condition_from_rule(rule[:and_conditions]) 
        or_condition = compose_condition_from_rule(rule[:or_conditions]) 
        

        rule_condition = [and_condition, or_condition].compact.join(" or ") 
        puts " MEIN CONDITON "
        puts condition
        sleep(1)
        if (eval " (#{condition}) ? true : false ")
          # save rule temperature
          save_rule_temperature
          return true                    
        end
        false        
      end
      
      def perform_action (actuator, action)
        excecuted = RelaisCard.send(action, actuator[:channel])
        if excecuted
          Lcd.sline("#{actuator[:name]} = #{action}")
        end
        update_status_line
      end

      

      def init
        # wait for lcd server to go up
        Logger.init
        wait_for_lcd_server
        ConfigReader.read_config_file
        ConfigReader.reload_config if ConfigReader.detect_usb_drive         
        Wiringpi.wiringPiSetup
        RelaisCard.init        
      end      
      
      def run
        # main loop
        init
        config = ConfigReader.config
        loop do
          read_temperature
        # get the rules 
          config[:actuators].each do | actuator |
            a[:rules].each do | rule |
              perform_action(actuator, rule[:action]) if rule_fullfilled(rule)
            end          
          end
          sleep(5)
        end        
      end  
    end
  end
end

HeatController::MainController.run
