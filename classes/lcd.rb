module HeatController 
  class Lcd
    
    
    def self.lcd_file
      return @lcd_file unless @lcd_file.nil?
      @lcd_file = File.open("/heatcontroll/lcd_tmp/lcd_file", "w+") 
    end
    
    def self.sline(msg, row = 1 )
      mlines(msg) 
    end
    
    def self.mlines(msg)
      lcd_file.truncate(0)
      lcd_file.puts(msg)
      lcd_file.fsync	
#	lcd_file.close
#@lcd_file = nil
    end
         

  end
end
