module RubyLcd
  class << self
    def driver
      DummyDriver
    end
    def print(args)
      driver.print(args)      
    end
    def flash(queue)
      driver.flash(queue)      
    end
  end

  class DummyDriver

    # R/W pin is pulled low (write only)
    # 'enable' pin is toggled to write data to the registers

    # Pin layout for LCD, the PI GPIO pins are between brackets, the wiringPI pinnumber is after the slash:
    # 01 Ground
    # 02 VCC - 5v
    # 03 Contrast adjustment (VO) from potentio meter
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
    # 15 Backlight LED Anode (+)
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
    @@lines_buffer = nil
    PAGES_VIEW_INTERVALL = 2 
    class << self
      #must have at least 40 chars 
      def write_string(string)
        lines = string.scan(/.{1,40}/)
        #@@lines_buffer ||= Queue.new
        @@lines_buffer = lines
        
        File.open("output.txt", "w+") do | f |
          f.puts lines.join("\n")
        end        
      end

      def nextLine()
        # Display automatically goes to next line when we hit 40 chars
        fillStr  = " "
        fillCntr = 1

        while (@@charCount + fillCntr < 40)
          fillStr += " "
          fillCntr += 1
        end

        Lcd1602Driver.doLcdPrint(fillStr)

        @@charCount = 0
      end


      def print_single_line (args)
        text = args[:text]
        start_pos = 0 
        loop do
          end_pos = (start_pos + 15 > text.size-1) ?  text.size-1 : start_pos + 15    
          line = text[start_pos..end_pos]
          line +=  " " * 24
          write_string(line)
          sleep(1) if start_pos == 0
          start_pos +=1
          if start_pos >= end_pos
            break if args[:flash]           
            start_pos = 0
          end 
          sleep(0.4)
          break if text.size <16
        end        
      end
      def print_multi_lines (args)        
        text = args[:text]
        lines = text.scan(/.{1,16}/)
        lines = lines.map{|p| p + " " * 24}
        lines << " " * 40 if lines.size.odd?
        
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
        
        puts "====== buffer ============"
        puts @@lines_buffer if !@@lines_buffer.nil?
        puts "=================="
        args = {text: args} if args.is_a?(String)
        puts args 
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

