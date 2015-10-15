#!/usr/bin/ruby

module RubyLed
  DEFAULT_LOOP_COUNT = 60 # ca 30 sekunden
  ON = 0
  OFF = 1
  class Led 
    require 'wiringpi'
    class << self
      P_RED = 0 # GPIO 17 / pin 11
      P_BLUE = 2 # GPIO 27 / PIN 13 
      P_GREEN = 3 # GPIO 22 / PIN 15
      

      
      def init
        Wiringpi.wiringPiSetup
        [P_RED, P_BLUE, P_GREEN].each do | pin |
          Wiringpi.pinMode(pin, 1) 
          Wiringpi.digitalWrite(pin, OFF)         
        end
      end
      def all_off(params=nil)
        [P_RED, P_BLUE, P_GREEN].each do | pin |
          Wiringpi.digitalWrite(pin, OFF)         
        end
      end
      def on(pin)
          Wiringpi.digitalWrite(pin, ON)                 
      end
      def off(pin)
          Wiringpi.digitalWrite(pin, OFF)                 
      end

      def toggle(pin)
          s = Wiringpi.digitalRead(pin)                 
          Wiringpi.digitalWrite(pin, s.to_s=="1" ? ON : OFF)                 
      end
      def red(params=nil)
        on(P_RED)
      end
      def blue(params=nil)
        on(P_BLUE)
      end
      def green(params=nil)
        on(P_GREEN)
      end
      def off(params=nil)
        all_off
      end
      def blink (pins, p1, p2, params=nil )
        loop_count = DEFAULT_LOOP_COUNT 
        loop_count = -1 if (params && params[:infinity])
 
        pins = [pins] unless pins.is_a? Array     
        loop do 
          pins.each {|p| on(p)}
          sleep(p1)
          pins.each {|p| off(p)}          
          sleep(p2)
          loop_count -= 1 if loop_count >0 
          break if loop_count == 0
          break if @stopped
        end
      end
      def error (params=nil)        
        blink(P_RED, 0.2, 0.2, params)
      end      
      def okay (params=nil)
        blink(P_GREEN, 0.8, 0.45, params)        
      end      
      def action (params=nil)        
        blink(P_BLUE, 0.25, 0.25, params)        
      end      
      def warning (params=nil)                
        blink([P_RED, P_GREEN], 0.25, 0.25, params)        
      end      
      def funny (params=nil)                
        blink([P_BLUE, P_GREEN], 0.25, 0.25, params)        
      end
    end
  end
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
      
    end
    
    
    
    def run
      return if @object.nil?
      Server.kill_others()
      if @object[:command]
        return Led.send(@object[:command], @object)
      end
    end
  end

  class Server
    require 'socket'
    require 'thread'
    
    STATUS_INTERUPT = 1

    def self.kill_others
      @threads.each do |t|
          Thread.kill t if (t.object_id != Thread.current.object_id)           
      end if !@threads.nil?
      Led.all_off
      @threads = [Thread.current]
    end

    def self.start
      Led.init
      #Led.okay

      @threads = []
      Thread::abort_on_exception = true  
      server = TCPServer.new("localhost", 2010)  # Server bind to port 2010
      loop {
        @threads << Thread.start(server.accept) do |client|
            message = client.gets
            #puts "server got message #{message} "
            if !message.nil?
              r = Request.new(message)
              r.run unless r.nil?
              #client.puts "responce"
            end
            client.close
        end
      }.join
    end
  end
end

RubyLed::Server.start
