module RubyLcd
  class LcdDriver
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

    T_MS = 1.0/1000000
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

    # based on code from lrvick, LiquidCrystal and Adafruit
    # commands
    LCD_CLEARDISPLAY        = 0x01
    LCD_RETURNHOME          = 0x02
    LCD_ENTRYMODESET        = 0x04
    LCD_DISPLAYCONTROL      = 0x08
    LCD_CURSORSHIFT         = 0x10
    LCD_FUNCTIONSET         = 0x20
    LCD_SETCGRAMADDR        = 0x40
    LCD_SETDDRAMADDR        = 0x80

    # flags for display entry mode
    LCD_ENTRYRIGHT          = 0x00
    LCD_ENTRYLEFT           = 0x02
    LCD_ENTRYSHIFTINCREMENT = 0x01
    LCD_ENTRYSHIFTDECREMENT = 0x00

    # flags for display on/off control
    LCD_DISPLAYON           = 0x04
    LCD_DISPLAYOFF          = 0x00
    LCD_CURSORON            = 0x02
    LCD_CURSOROFF           = 0x00
    LCD_BLINKON             = 0x01
    LCD_BLINKOFF            = 0x00

    # flags for display/cursor shift
    LCD_DISPLAYMOVE         = 0x08
    LCD_CURSORMOVE          = 0x00

    # flags for display/cursor shift
    LCD_DISPLAYMOVE         = 0x08
    LCD_CURSORMOVE          = 0x00
    LCD_MOVERIGHT           = 0x04
    LCD_MOVELEFT            = 0x00

    # flags for function set
    LCD_8BITMODE            = 0x10
    LCD_4BITMODE            = 0x00
    LCD_2LINE               = 0x08
    LCD_1LINE               = 0x00
    LCD_5x10DOTS            = 0x04
    LCD_5x8DOTS             = 0x00

    class << self
      def delayMicroseconds (ms)
        sleep(ms * T_MS)
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

      def write_4bit(bits)
        Wiringpi.digitalWrite(P_D7, bits & P_D7_BIT_MASK)
        Wiringpi.digitalWrite(P_D6, bits & P_D6_BIT_MASK)
        Wiringpi.digitalWrite(P_D5, bits & P_D5_BIT_MASK)
        Wiringpi.digitalWrite(P_D4, bits & P_D4_BIT_MASK)
        pulseEnable()
      end

      def write_byte(byte, char_mode=0)
        puts byte
        while byte.size < 8 do
          byte = "0" + byte
        end
        sleep(T_MS)
        Wiringpi.digitalWrite(P_RS, char_mode)
        write_4bit(byte[0..3].to_i(2))
        write_4bit(byte[4..7].to_i(2))
      end

      def commands(bytes)
        bytes = [bytes] unless bytes.is_a? Array
        bytes.each {|b| write_byte(b.to_s(2))}
      end

      def write_chars(bytes)
        bytes = [bytes] unless bytes.is_a? Array
        bytes.each {|b| write_byte(b, 1)}
      end

      def initialize ()

        Wiringpi.wiringPiSetup

        # Set all pins to output mode
        Wiringpi.pinMode(P_RS, 1)
        Wiringpi.pinMode(P_EN, 1)
        Wiringpi.pinMode(P_D4, 1)
        Wiringpi.pinMode(P_D5, 1)
        Wiringpi.pinMode(P_D6, 1)
        Wiringpi.pinMode(P_D7, 1)

        commands([0x33,
        # initialization
                0x32,
                # initialization
                0x10,
                # 2 line 5x7 matrix
                0x0C,
                # turn cursor off 0x0E to enable cursor
                0x06])
        # shift cursor right

        @displaycontrol = LCD_DISPLAYON | LCD_CURSOROFF | LCD_BLINKOFF
        commands( @displaycontrol | LCD_DISPLAYCONTROL )

        # Initialize to default text direction (for romance languages)
        @displaymode = LCD_ENTRYLEFT | LCD_ENTRYSHIFTDECREMENT
        # set the entry mode
        commands( @displaymode | LCD_ENTRYMODESET)
        clear()
      end

      def home
        commands(LCD_RETURNHOME)
        # set cursor position to zero
        delayMicroseconds(3000)
      # this command takes a long time!
      end

      def clear
        commands(LCD_CLEARDISPLAY)
        # command to clear display
        delayMicroseconds(3000)
      # 3000 microsecond sleep, clearing the display takes a long time
      end

      def setCursor (col, row)
        row_offsets = [0x00, 0x40, 0x14, 0x54]
        numlines = 2
        row = numlines - 1  if row > numlines # we count rows starting w/0
        commands(LCD_SETDDRAMADDR | (col + row_offsets[row]))
      end

      def noDisplay
        #""" Turn the display off (quickly) """
        @displaycontrol &= ~LCD_DISPLAYON
        commands(LCD_displaycontrol | @displaycontrol)
      end

      def display
        #""" Turn the display on (quickly) """
        @displaycontrol|= LCD_DISPLAYON
        commands(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      def noCursor
        # """ Turns the underline cursor off """
        @displaycontrol &= ~LCD_CURSORON
        commands(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      def cursor
        #""" Turns the underline cursor on """
        @displaycontrol |= LCD_CURSORON
        commands(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      def noBlink
        #""" Turn the blinking cursor off """
        @displaycontrol &= ~LCD_BLINKON
        commands(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      def blink
        #""" Turn the blinking cursor on """
        @displaycontrol |= LCD_BLINKON
        commands(LCD_DISPLAYCONTROL | @displaycontrol)
      end

      def DisplayLeft
        #""" These commands scroll the display without changing the RAM """
        commands(LCD_CURSORSHIFT | LCD_DISPLAYMOVE | LCD_MOVELEFT)
      end

      def scrollDisplayRight
        #""" These commands scroll the display without changing the RAM """
        commands(LCD_CURSORSHIFT | LCD_DISPLAYMOVE | LCD_MOVERIGHT)
      end

      def leftToRight
        #""" This is for text that flows Left to Right """
        @displaymode |= LCD_ENTRYLEFT
        commands(LCD_ENTRYMODESET | @displaymode)
      end

      def rightToLeft
        #""" This is for text that flows Right to Left """
        @displaymode &= ~LCD_ENTRYLEFT
        commands(LCD_ENTRYMODESET | @displaymode)
      end

      def autoscroll
        #""" This will 'right justify' text from the cursor """
        @displaymode |= LCD_ENTRYSHIFTINCREMENT
        commands(LCD_ENTRYMODESET | @displaymode)
      end

      def noAutoscroll
        #""" This will 'left justify' text from the cursor """
        @displaymode &= ~LCD_ENTRYSHIFTINCREMENT
        commands(LCD_ENTRYMODESET | @displaymode)
      end
      def nextline
        commands(0xC0)
      end

      def message(text)
        #commands(0xC0)  # next line
        text.each_byte do | b |
          write_chars(b.to_s(2))
        end
      end
    end
  end
end