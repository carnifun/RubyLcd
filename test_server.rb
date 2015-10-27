#!/usr/bin/ruby

APP_ROOT = "/heatcontroll"
load "#{APP_ROOT}/classes/logger.rb"
#load "#{APP_ROOT}/driver/lcd1602_driver.rb"


module RubyLcd
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
      add_request @object if !@object.nil?
    end
    
    def add_request(object)
      @@last_requests.pop if @@last_requests.size >=10        
      @@last_requests << object unless object[:flash]
    end
    
    def get_extra_text(row)
      i = 0
      row = (row == BOTTOM_ROW) ? TOP_ROW : BOTTOM_ROW
      @@last_requests.reverse_each do |request|
        i +=1 
        next if i==1 # skip first request
        if request[:single_line] == row
          return request[:text]
        end
      end
      nil
    end
    
    def run
      return if @object.nil?
      Server.gracefull_stop_others()
      loop do 
        10.times do | i | 
          puts " Thread id #{Thread.current.object_id}"
          puts " Var = #{Thread.current["STOP"]}"
          puts " #{@object} "
          puts " pass #{i}  "
          sleep(1)
        end  
        Thread.current.kill if Thread.current["STOP"]
      end
      
    end
  end

  class Server
    require 'socket'
    require 'thread'
    @@threads = []   
    STATUS_INTERUPT = 1

    def self.threads
      @@threads || [] 
    end

    def self.gracefull_stop_others
      
      puts " we have #{@@threads.count} threads"
      tmp = @@threads  
      tmp.each do |t|
        if (t.object_id != Thread.current.object_id)     
           t["STOP"] = "---SET----"           
           puts " Sending stop message "
           puts " thread stoped = #{t.stop?}"
           puts " thread alive = #{t.alive?}"
           
            
           puts " waiting start "
           t.join
           #puts " KILLLED "
           puts " waiting end "
           # wait until thred exit 
           #puts " killing "
           #t.kill
           # log ("Finisched Waiting  ")
         else
          #t["STOP"] = "---CURRRENT----"
         end    
      end if !@@threads.nil?
      
      #@@threads = [Thread.current]
    end
    def self._gracefull_stop_others
      @@threads.each do |t|
        if (t.object_id != Thread.current.object_id)     
           t["STOP"] = Time.now.to_s
           log ("STOP SIGNAL SET for Thread #{t.object_id} we must wait ")
           # wait until thred exit 
           t.value           
           log ("Finisched Waiting  ")
         end     
      end if !@@threads.nil?
      @@threads = [Thread.current]
    end
    def self.get_ip
       a =  Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
       return a.ip_address unless a.nil?
       nil
    end
    def self.start
      @@threads = []
      Thread::abort_on_exception = true  
      server = TCPServer.new("localhost", 2000)  # Server bind to port 2000
      loop {
        @@threads << Thread.start(server.accept) do |client|
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


#Signal.trap('INT') do|_signo|
  #RubyLcd.driver.init
#end
Signal.trap('KILL') do|_signo|
  RubyLcd.clear
  exit(0)
end

Signal.trap('TERM') do|_signo|
  RubyLcd.clear
  exit(0)
end
RubyLcd::Server.start

