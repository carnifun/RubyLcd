#!/usr/bin/ruby

class String
  def to_16
    if 16 - size > 0
      self + " " * (16 - size)
    else
     self	
    end
  end
end

APP_ROOT = "/heatcontroll"
load "#{APP_ROOT}/logger.rb"

module HeatController  
  require "wiringpi"
  HIGH = 1 
  LOW = 0    
  T_MS = 1.0000000/1000000
  MAIN_LOOP_INTERVALL = 15
  
  class Led
    require 'socket'
    def self.tcp_send request 
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
  
  class Lcd
    require 'socket'
    
    def self.tcp_send request 
      begin 
        socket = TCPSocket.open("127.0.0.1","2000") 
        socket.print(request)               # Send request
        socket.close
        true
       rescue
         return false
       end
    end
    
    
    def self.sline(msg, row = 1 )
        tcp_send  "{\"text\":\"#{msg}\", \"single_line\":\"#{row}\" }\r\n"
    end
    
    def self.mlines(msg)
      tcp_send "{\"text\":\"#{msg}\"}\r\n"
    end
         
    def self.flash(msg)
      tcp_send "{\"text\":\"#{msg}\", \"flash\": \"true\"}\r\n"
    end
     def self.clear()
      tcp_send "{\"command\":\"clear\"}\r\n"
    end    
  end

  
  class RelaisCard
    # Wiring pins 
    # model B+ 
    # CHANNELS ar numbered from 1 to 4 
    # CHANNELS = [ 3, 12, 13, 14 ]
    # model A+ 
    CHANNELS = [21 , 22, 23, 24 ]
    @@initialized = false

    class << self
      
      def initialized?
        @@initialized
      end
      def init
        @@initialized = true
        CHANNELS.each do | c |
          Wiringpi.pinMode(c, 1)
          Wiringpi.digitalWrite(c, HIGH)
        end
      end  
      def get_state(actuator)
        pin = CHANNELS[actuator[:channel].to_i - 1]
        Wiringpi.digitalRead(pin)        
      end    
      def action (channel, a)
        #puts "channel #{channel} action #{a}"
        return if channel.nil? or channel.empty?
        channel = channel.to_i  - 1 
        return if  channel > 3 or channel < 0 
        pin = CHANNELS[channel]
        #puts "Pin #{pin}"
        old_state = Wiringpi.digitalRead(pin)
        new_state = (a=="on") ? LOW : HIGH
        #puts "action #{a} old_state#{old_state} new_state#{new_state} -- "
        if old_state.to_i != new_state.to_i
          Wiringpi.digitalWrite(pin, new_state)
          log("Channel #{channel} set to #{a} " )
          return true
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
      
      def update_network_setting
        return false unless @config[:network]
        int_file = "/etc/network/interfaces"
        #int_file = "/home/pi/interfaces"
        content = File.read(int_file) 
        content = content.gsub(/wpa-ssid.*/, "wpa-ssid \"#{@config[:network][:ssid]}\"")
        content = content.gsub(/wpa-psk.*/, "wpa-psk \"#{@config[:network][:psk]}\"")
        f = File.open(int_file, "w+")
        f.puts content
        f.close
        true
      end
      def read_config_file(new_file=false)
          @config = json_from_file(File.join(APP_ROOT, "config","config.json")) 
          if @config.nil? 
            Lcd.mlines("lade default".to_16 + "Configuration")          
            sleep(5)
            @config = json_from_file(File.join(APP_ROOT, "config","config.default.json")) 
            if @config.nil?
              Lcd.mlines("Keine Konfiguration".to_16+  "gefunden. exit")
              Led.fatal_error
              exit()
            end
          end
          if new_file            
            if update_network_setting
 	            Lcd.mlines("System Reboot".to_16+  "Usb entfernen.")
              sleep(5)
	            system('reboot')		
	            exit(0)
	          end  	
          end
        end
      def json_from_file ( file )
        log " loading #{file}"

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
        content = File.read("/media/usb/config.json")       
        if json_from_content(content).nil?
          Lcd.mlines("Konfiguration    ist FEHLERHAFT")
          sleep(2)
          return 
        end
        Lcd.mlines("Lade neue     Konfiguration ")
        sleep(4)
        File.open(File.join(APP_ROOT, "config","config.json"), "w+") do |f |
          f.puts content
        end
        read_config_file(true)
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
           #puts "dir found "
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
           #Lcd.mlines("Kein Usb erkannt")
           #sleep(5)           
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
      @sensor_data=[]            
      def fallback_programm(actuator = nil)
        config = ConfigReader.config
        actuators = config[:actuators]
        actuators = [actuator] if !actuator.nil?         
        actuators.each do | act |
          RelaisCard.send(act[:fallback_state], act[:channel])
        end
      end
      def _fallback_programm
        config = ConfigReader.config
        config[:actuators].each do | actuator |
          RelaisCard.send(actuator[:fallback_state], actuator[:channel])
          #Lcd.sline("#{actuator[:name]}=>#{actuator[:fallback_state]=="on"? "An": "Aus"}")
        end
        log "Fallback programm activated"
      end
      def read_sensor_temperatur(sensor_id)       
        sfile = "/sys/bus/w1/devices/#{sensor_id}/w1_slave"
        return 0 unless File.exists?(sfile)       
         content = File.read(sfile) 
         t = 0
         if (m = content.match(/t=(\d+)/))
           t = m[1]
         end
         t.to_f/1000          
      end
      def update_status
        config = ConfigReader.config
        status ="" 
        
        last_sensor_data = sensor_data = @sensor_data.last 
        last_sensor_data = @sensor_data.last(2).first if @sensor_data.length > 1 
        config[:sensors].each do | s |
          variation = (sensor_data[s[:id]] - last_sensor_data[s[:id]] ) > 0.0 ? "+" : "-"
          if sensor_data[s[:id]]>0
            status +="#{s[:name]}:+#{sprintf('%.2f',sensor_data[s[:id]])} C #{variation}".to_16
          else
            status +="#{s[:name]}: ERROR ".to_16            
          end
        end
        
        config[:actuators].each do | actuator |
          state = RelaisCard.get_state(actuator)
          #puts "state #{state} == 1 "
          status +="#{actuator[:name]}: #{state==1?"Aus":"An"}".to_16
        end
        Lcd.mlines(status)
      end
      
      def read_temperature
        config = ConfigReader.config
        return_value =  true
        
        
        @sensor_data.shift if @sensor_data.size > 10
        sensor_data = {} 
        config[:sensors].each do |s|
          sensor_data[s[:id]] = read_sensor_temperatur(s[:id])
          if sensor_data[s[:id]]<1
            Lcd.mlines("Achtung ".to_16 + "#{s[:name]} defekt!")
            return_value =  false
          end
        end
        @sensor_data << sensor_data
        return_value
      end
      def get_sensor (s_id)
       config[:sensors].each do |s |
         return s if s[:id] == s_id
       end
      end
      def wait_for_lcd_server
        loop do
          begin 
            s = Lcd.sline("Lcd server up")
            sleep(1)
            return true if s 
          rescue
            #puts "waiting for lcd server"  			
            sleep(1)
          end
        end
      end
      def sensor_name_to_id (name) 
        config = ConfigReader.config
        
        config[:sensors].each do |s |
        return s[:id] if s[:name].downcase == name.downcase
        end
      end
      
      def compose_condition_from_rule (rule, und= true)        
        rule_conditions = und ?  rule[:and_conditions] : rule[:or_conditions]        
        rule_conditions.map do | condition |
          s_id = sensor_name_to_id(condition[:sensor])
          sensor_data = @sensor_data.last          
          c = (sensor_data[s_id]>0) ? " #{sensor_data[s_id]} #{condition[:comparator]} '#{condition[:value]}'.to_f  " : " false "            
          "( #{c} )"
        end.join(und ?  " and " : " or ") if rule_conditions
      end
      def rule_fullfilled ( rule )
        # prepare the conditions 
        and_condition = compose_condition_from_rule(rule) 
        or_condition = compose_condition_from_rule(rule,false) 
        

        rule_condition = [and_condition, or_condition].compact.join(" or ") 
        #puts " MEIN CONDITON "
        #puts rule_condition
        #sleep(1)
        if (eval " (#{rule_condition}) ? true : false ")
          #puts "Condition ist OKAY "
          # save rule temperature
          return true                    
        end
        false        
      end
      def no_faulty_sensor_detected?(rule)
        conditions = rule[:and_conditions]
        conditions += rule[:or_conditions] if !rule[:or_conditions].nil?
        conditions.each do | c |
          s_id = sensor_name_to_id(c[:sensor])
          return false if @sensor_data.last[s_id] < 1 
        end
        true 
      end
      def perform_action (actuator, action)
        #puts "performing action#{action}"
        excecuted = RelaisCard.send(action, actuator[:channel])
        if excecuted
          Led.action
          Lcd.sline("#{actuator[:name]}=>#{action=="on"? "An": "Aus"}")
          #puts "action#{action} executed "
          sleep(3)
        end
      end
      def init
	     @sensor_data=[]
        # wait for lcd server to go up
        wait_for_lcd_server
        ConfigReader.read_config_file
        ConfigReader.reload_config  if ConfigReader.detect_usb_drive                 
        Wiringpi.wiringPiSetup
        RelaisCard.init       
      end      
      def touch_pid_file
	     require "fileutils"
	     FileUtils.touch("/heatcontroll/tmp/heatcontroll.pid")
      end		
      def run
        # main loop
        Led.loading
        init
        config = ConfigReader.config
        loop do
          
          if read_temperature
            Led.okay          
          else
            Led.warning
          end
          # get the rules 
          config[:actuators].each do | actuator |
            actuator[:rules].each do | rule |                                 
              if no_faulty_sensor_detected?(rule)         
                perform_action(actuator, rule[:action]) if rule_fullfilled(rule)
              else
                fallback_programm(actuator)
                break;
              end
            end          
          end      
          update_status
          sleep(MAIN_LOOP_INTERVALL)
	        touch_pid_file	
        end        
      end  
    end
  end
end


Signal.trap('INT') do|_signo|
  HeatController::MainController.fallback_programm
  exit(0)
end
Signal.trap('KILL') do|_signo|
  HeatController::MainController.fallback_programm
  exit(0)
end

Signal.trap('TERM') do|_signo|
  HeatController::MainController.fallback_programm
  exit(0)
end

HeatController::MainController.run
