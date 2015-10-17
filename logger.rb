  class Logger
    class << self
      CONSOLE = false
      APP_ROOT = File.dirname(__FILE__)
      @@initialized = false
      @@logger_handler = false        
      def initialized?
        @@initialized
      end
      def init
        return if initialized?
        puts "Log"
        puts File.join(APP_ROOT, "heat_controller.log")
        #@@logger_handler =  File.open(File.join(APP_ROOT, "heat_controller.log"), "w+")         
        @@logger_handler =  File.open("/tmp/heat_controller.log", "w+")         
        @@initialized = true
      end
      def logger_handler 
        return @@logger_handler if @@logger_handler
        init
        @@logger_handler
      end
      def log(message)
        if CONSOLE
          puts __FILE__
          puts message
        else
          logger_handler.puts("[#{Time.now.strftime("%d.%m.%Y %H:%M:%S")}][INFO]:#{message}\n")        
        end
      end
      def log_error(message)
        logger_handler.puts("[#{Time.now.strftime("%d.%m.%Y %H:%M:%S")}][ERROR]:#{message}\n")        
      end
    end     
  end
  
  def log(msg)    
    Logger.log(msg)
  end
  def log_error(msg)
    Logger.log_error(msg)
  end
  

