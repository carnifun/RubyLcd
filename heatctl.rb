#!/usr/bin/ruby

# start the heat Controller Main programm and server 

#APP_ROOT = File.dirname(__FILE__)
APP_ROOT = "/heatcontroll"
LOG_PATH= "#{APP_ROOT}/log"



def is_running? (proc)    
  proc = "[#{proc[0]}]" + proc[1..proc.size]
  pid = `ps auxwww | grep '#{proc}' | head -1 | awk '{print $2}'`
  return false if pid.empty?
  pid
end


def stop (proc, wait=false)
  # kill
  term = 15
  # terminate
  kill = 9 
  pid = is_running?(proc)  
  if pid
    `kill -#{term} #{pid} `
    10.times do | i |   
      puts " wating for process to finish #{i}"
      sleep(1)
    end if wait
    # wait the process to go fallback
    `kill -#{kill} #{pid} ` 
    puts "#{proc} gestoppt "
  else
    puts "#{proc} is not running "
  end  
end

def start(proc)
  base = File.basename( proc , ".*" )
  if !is_running?(proc)  
    system "ruby #{APP_ROOT}/#{proc} >> #{LOG_PATH}/#{base}.log 2>&1 &"
    puts "#{base} gestartet"
  else
    puts "#{base} already running"    
  end
end


command = ARGV[0] || ""


if command == "start"
  start("lcd_server.rb")      
  start("led_server.rb")   
  sleep(3)   
  start("heat_controller.rb")      
elsif command =="stop" 
  stop("lcd_server.rb")   
  stop("led_server.rb")   
  stop("heat_controller.rb", true)      
end

