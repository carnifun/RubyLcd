module HeatController 
  require "wiringpi"
  HIGH  = 1 
  LOW   = 0    
  class RelaisCard
    # Wiring pins 
    # model B+ 
    # CHANNELS ar numbered from 1 to 4 
    # CHANNELS = [ 3, 12, 13, 14 ]
    # model A+ 
    CHANNELS      = [21 , 22, 23, 24 ]
    @@initialized = false

    class << self
      def initialized?
        @@initialized
      end
      def init
        @@initialized = true
        Wiringpi.wiringPiSetup
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
        return if channel.nil? or channel.empty?
        channel = channel.to_i  - 1 
        return if  channel > 3 or channel < 0 
        pin = CHANNELS[channel]

        old_state = Wiringpi.digitalRead(pin)
        new_state = (a=="on") ? LOW : HIGH

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
end