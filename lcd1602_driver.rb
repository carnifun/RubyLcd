    class String
      def to_40
        self + " " * (40 - size)
      end
    end
module RubyLcd
     TOP_ROW = "1"  
      BOTTOM_ROW = "2"  
  class << self
    def driver
      Lcd1602Driver.init unless Lcd1602Driver.initialized?
      Lcd1602Driver
    end
    def print(args)
      driver.cls
      driver.print(args)      
    end
    def print_top(message)
      driver.cls
      driver.print({text: message, single_line: TOP_ROW})      
    end
    def print_bottom(message)
      driver.cls
      driver.print({text: message, single_line: BOTTOM_ROW})      
    end
    def flash(message)      
      driver.cls
      driver.print({text: message, flash: true})      
    end
    def clear(args=nil)
      driver.cls
      driver.cls()      
    end
  end

  class Lcd1602Driver
    require 'wiringpi'

    # R/W pin is pulled low (write only)
    # 'enable' pin is toggled to write data to the registers

    # Pin layout for LCD, the PI GPIO pins are between brackets, the wiringPI pinnumber is after the slash:
    # 01 Ground
    # 02 VCC - 5v
    # 03 Contrast adjustment (VO) from potentio meter 4,7 kOhm to Ground 
    # 04 (25/6) Register select (RS), RS=0: Command, RS=1: Data
    # 05 (1/?) Read/Write (R/W) R/W=0: Write, R/W=1: read (This pin is not used/always set to 1)
    # 06 (24/5) Clock (Enable) Falling edge triggered
    # 07 Bit 0 (Not used in 4-bit operation)
    # 08 Bit 1 (Not used in 4-bit operation)
    # 09 Bit 2 (Not used in 4-bit operation)
    # 10 Bit 3 (Not used in 4-bit operation)
    # 11 (23/4) Bit 4
    # 12 (17/0) Bit 5
    # 13 (21/2) Bit 6
    # 14 (22/3) Bit 7
    # 15 Backlight LED Anode (+) 1 KOhm to Vcc 5v 
    # 16 Backlight LED Cathode (-)

    T_MS = 1.0000000/1000000
    P_RS = 11 # GPIO 7
    P_RW = 99 #Bogus number not used at this moment
    P_EN = 10 # 8
    P_D0 = 99 #Bogus number not used at this moment
    P_D1 = 99 #Bogus number not used at this moment
    P_D2 = 99 #Bogus number not used at this moment
    P_D3 = 99 #Bogus number not used at this moment
    P_D4 = 6 # 25
    P_D5 = 5 # 24
    P_D6 = 4 # 23
    P_D7 = 1 # 18
    ON   = 1
    OFF  = 0
    # 0b00000
    P_RS_BIT_MASK = 1 << 4
    P_D7_BIT_MASK = 1 << 3
    P_D6_BIT_MASK = 1 << 2
    P_D5_BIT_MASK = 1 << 1
    P_D4_BIT_MASK = 1 << 0

    @@charCount = 0
    @@onPi      = true # So I can debug the non-RaspberryPi code on a separate machine
    @@initialized = false
    PAGES_VIEW_INTERVALL = 3
    SLIDE_INTERVAL = 1
    class << self
      def initialized?
        @@initialized
      end

      def init
        if (@@onPi == true)
          Wiringpi.wiringPiSetup

          # Set all pins to output mode (not sure if this is needed)
          Wiringpi.pinMode(P_RS, 1)
          Wiringpi.pinMode(P_EN, 1)
          Wiringpi.pinMode(P_D4, 1)
          Wiringpi.pinMode(P_D5, 1)
          Wiringpi.pinMode(P_D6, 1)
          Wiringpi.pinMode(P_D7, 1)

          initDisplay()
          sleep T_MS * 10
          lcdDisplay(ON, OFF, OFF)
          setEntryMode()
          @@initialized = true
        end
      end

      def setEntryMode()
        # Entry mode set: move cursor to right after each DD/CGRAM write
        command(0)
        command(0b0110)
      end

      def pulseEnable()
        # Indicate to LCD that command should be 'executed'
        Wiringpi.digitalWrite(P_EN, 0)
        sleep T_MS * 10
        Wiringpi.digitalWrite(P_EN, 1)
        sleep T_MS * 10
        Wiringpi.digitalWrite(P_EN, 0)
        sleep T_MS * 10
      end

      def write(byte)
        Wiringpi.digitalWrite(P_RS, 1)
        Wiringpi.digitalWrite(P_D7, byte & P_D7_BIT_MASK)
        Wiringpi.digitalWrite(P_D6, byte & P_D6_BIT_MASK)
        Wiringpi.digitalWrite(P_D5, byte & P_D5_BIT_MASK)
        Wiringpi.digitalWrite(P_D4, byte & P_D4_BIT_MASK)
        sleep T_MS
        pulseEnable()
      end
      def command(byte)
        Wiringpi.digitalWrite(P_RS, 0)
        Wiringpi.digitalWrite(P_D7, byte & P_D7_BIT_MASK)
        Wiringpi.digitalWrite(P_D6, byte & P_D6_BIT_MASK)
        Wiringpi.digitalWrite(P_D5, byte & P_D5_BIT_MASK)
        Wiringpi.digitalWrite(P_D4, byte & P_D4_BIT_MASK)
        sleep T_MS
        pulseEnable()
      end

      # Turn on display and cursor
      def lcdDisplay(display, cursor, block)
        command(0)
        command("1#{display}#{cursor}#{block}".to_i(2))
        # display # 1 = 0n
        # cursor # 1 = Cursor on, 0 = Cursor off
        # block  # 1 = Block, 0 = Underline cursor
      end

      def write_char(byte)
        # Write data to CGRAM/DDRAM
        # write left and right byte
        
        while byte.size < 8 do 
          byte = "0" + byte 
        end
        write(byte[0..3].to_i(2))
        write(byte[4..7].to_i(2))
        
        @@charCount += 1
      end

      def cls()
        # Clear all data from screen
        command(0)
        command(0b0001)
      end
      #LCD_SETDDRAMADDR = 0x80
      #def set_cursor ( col, row )
      #  row_offsets = [ 0x00, 0x40, 0x14, 0x54]
                  
        # command(LCD_SETDDRAMADDR | (col + row_offsets[row]));
      #end

      def initDisplay()
        # Set function to 4 bit operation
        i = 0
        3.times do    # Needs to be executed 3 times
        # Wait > 40 MS
          sleep 42 * T_MS
          command(0b0011)
        end

        # Function set to 4 bit
        # Needs to be executed 2 times
        2.times do
          command(0b0010)
        end

        # Set number of display lines
        # P_D7 N = 0 = 1 line display
        #  PD6 F = 0 = 5x8 character font
        command(0b1000)

        # Display Off (2 blocks)
        command(0)

        command(0b1000)

        # Display clear (2 blocks)
        command(0)

        command(1)

        # Entry mode set"
        command(0)

        #P_D5 1 = Increment by 1
        #P_D4 0 = no shift
        command(0b0111)

      end

      def write_string(string)
        # Loop through each character in the string, convert it to binary, and print it to the LCD
        
        lines = string.scan(/.{1,40}/)
        #puts "Buffer "
        #puts lines.inspect
        #puts "Buffer "
        lines.each do | l | 
          l.each_byte do | b |
              write_char(b.to_s(2))
          end        
        end
        #@@string_buffer ||=[]
        #@@string_buffer << string        
      end
      def print_single_line (args)
                
        text = args[:text]
                
        extra_text = args[:extra_text] || " ".to_40
        if extra_text              
          extra_text = extra_text.scan(/.{1,40}/).first
          extra_text = extra_text.to_40
        end          
        start_pos = 0 
        loop do
          end_pos = (start_pos + 15 > text.size-1) ?  text.size-1 : start_pos + 15    
          line = text[start_pos..end_pos]
          line = line.to_40          
          line = (args[:single_line] == TOP_ROW) ? line + extra_text : extra_text + line   
          write_string(line)
          sleep(1) if start_pos == 0
          start_pos +=1
          if start_pos >= end_pos
            start_pos = 0
          end 
          sleep(0.8)
          break if text.size <16
        end        
      end
      def print_multi_lines (args)        
        text = args[:text]
        lines = text.scan(/.{1,16}/)
        lines = lines.map{|p| p.to_40}
        lines << " ".to_40 if lines.size.odd?
        
        pages = lines.each_slice(2).map do | top_line, bottom_line |
          top_line + bottom_line
        end
        loop do 
          pages.each do | page_text |
            write_string(page_text)
            sleep(PAGES_VIEW_INTERVALL)          
            break if pages.size == 1
          end
          break if args[:flash] || pages.size == 1
        end        
      end
      def print (args)
        args = {text: args} if args.is_a?(String)
        args[:text] = args[:text].force_encoding('BINARY').encode('ASCII', :invalid => :replace, :undef => :replace, :replace => '')
        args[:extra_text] = args[:extra_text].force_encoding('BINARY').encode('ASCII', :invalid => :replace, :undef => :replace, :replace => '') if args[:extra_text]
        single_line    = args[:single_line] || false
        if single_line         
          print_single_line(args) 
        else
          print_multi_lines(args)
        end 
      end

     

     

      


    end
  end
end

