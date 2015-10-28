#!/usr/bin/ruby
APP_ROOT = '/heatcontroll'
load "#{APP_ROOT}/classes/logger.rb"

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
        [P_RED, P_BLUE, P_GREEN].each do |pin|
          Wiringpi.pinMode(pin, 1)
          Wiringpi.digitalWrite(pin, OFF)
        end
      end

      def all_off(_params = nil)
        [P_RED, P_BLUE, P_GREEN].each do |pin|
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
        Wiringpi.digitalWrite(pin, s.to_s == '1' ? ON : OFF)
      end

      def red(_params = nil)
        on(P_RED)
      end

      def blue(_params = nil)
        on(P_BLUE)
      end

      def green(_params = nil)
        on(P_GREEN)
      end

      def pink(_params = nil)
        on(P_BLUE)
        on(P_RED)
      end

      def off(_params = nil)
        all_off
      end

      def blink(pins, p1, p2, params = nil)
        loop_count = DEFAULT_LOOP_COUNT
        loop_count = -1 if params && params[:infinity]

        pins = [pins] unless pins.is_a? Array
        loop do
          pins.each { |p| on(p) }
          sleep(p1)
          pins.each { |p| off(p) }
          sleep(p2)
          loop_count -= 1 if loop_count > 0
          break if loop_count == 0
        end
      end

      # okay ==> warning ==> error 3 *  DEFAULT_LOOP_COUNT
      # action => okay ==> warning ==> error  4 * DEFAULT_LOOP_COUNT
      def error(params = nil)
        blink(P_RED, 0.2, 0.2, params)
      end

      def okay(params = nil)
        blink(P_GREEN, 0.8, 0.45, params)
        # we should not be here and if
        warning(params)
      end

      def action(params = nil)
        blink(P_BLUE, 0.25, 0.25, params)
        # we should not be here and if
        okay(params)
      end

      def warning(params = nil)
        blink([P_RED, P_GREEN], 0.25, 0.25, params)
        # we should not be here and if
        error(params)
      end

      def funny(params = nil)
        blink([P_BLUE, P_GREEN], 0.25, 0.25, params)
      end
    end
  end
  class Request
    require 'json'
    require 'thread'
    @@last_requests = []

    def initialize(message)
      return if message.nil?
      @object = begin
        JSON.parse(message, symbolize_names: true)
      rescue
        nil
      end
    end

    def run
      return if @object.nil?
      Server.kill_others
      return Led.send(@object[:command], @object) if @object[:command]
    end
  end
  class Server
    require 'socket'
    require 'thread'

    STATUS_INTERUPT = 1

    def self.kill_others
      @threads.each do |t|
        Thread.kill t if (t.object_id != Thread.current.object_id)
      end unless @threads.nil?
      Led.all_off
      @threads = [Thread.current]
    end

    def self.start
      Led.init
      Led.pink
      log('Led Server started')
      @threads = []
      Thread.abort_on_exception = true
      server = TCPServer.new('localhost', 2010) # Server bind to port 2010
      loop do
        @threads << Thread.start(server.accept) do |client|
          message = client.gets
          # puts "server got message #{message} "
          unless message.nil?
            r = Request.new(message)
            r.run unless r.nil?
            # client.puts "responce"
          end
          client.close
        end
      end.join
    end
  end
end

Signal.trap('INT') do|_signo|
  RubyLed::Led.all_off
  exit(0)
end
Signal.trap('KILL') do|_signo|
  RubyLed::Led.all_off
  exit(0)
end

Signal.trap('TERM') do|_signo|
  RubyLed::Led.all_off
  exit(0)
end

RubyLed::Server.start
