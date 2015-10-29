#!/usr/bin/ruby

class String
  def to_16
    if 16 - size > 0
      self + ' ' * (16 - size)
    else
      self
    end
  end
end

APP_ROOT = '/heatcontroll'
Dir["#{APP_ROOT}/classes/*.rb"].each { |f| load f }

SIM_MODE = false

module HeatController
  MAIN_LOOP_INTERVALL = 20
  MAX_SENSOR_TEMP = 81
  MIN_SENSOR_TEMP = 3    
  class MainController
    require 'fileutils'

    class << self
      @sensor_data = []

      def fallback_programm(actuator = nil)
        config = ConfigReader.config
        actuators = config[:actuators]
        actuators = [actuator] unless actuator.nil?
        actuators.each do |act|
          RelaisCard.send(act[:fallback_state], act[:channel])
        end
      end


      def read_sensor_temperatur(sensor_id)
        sfile = "/sys/bus/w1/devices/#{sensor_id}/w1_slave"
        return 0 unless File.exist?(sfile)
        content = File.read(sfile)
        t = 0
        if (m = content.match(/t=(\d+)/))
          t = m[1]
        end
        t.to_f / 1000
      end

      def update_status
        config = ConfigReader.config
        status = @status

        last_sensor_data = sensor_data = @sensor_data.last
        last_sensor_data = @sensor_data.last(2).first if @sensor_data.length > 1
        config[:sensors].each do |s|
          variation = (sensor_data[s[:id]] - last_sensor_data[s[:id]]) > 0.0 ? '+' : '-'
          if sensor_data[s[:id]] > 0
            status += "#{s[:name]}:+#{sprintf('%.2f', sensor_data[s[:id]])} C #{variation}".to_16
          else
            status += "#{s[:name]}: ERROR ".to_16
          end
        end

        config[:actuators].each do |actuator|
          state = RelaisCard.get_state(actuator)
          # puts "state #{state} == 1 "
          status += "#{actuator[:name]}: #{state == 1 ? 'Aus' : 'An'}".to_16
        end
        Lcd.mlines(status)
      end

      def read_temperature
        config = ConfigReader.config
        return_value = true

        @sensor_data.shift if @sensor_data.size > 10
        sensor_data = {}
        config[:sensors].each do |s|
          sensor_data[s[:id]] = read_sensor_temperatur(s[:id])
          if sensor_data[s[:id]] < MIN_SENSOR_TEMP || sensor_data[s[:id]] > MAX_SENSOR_TEMP
            @status +='Achtung '.to_16 + "#{s[:name]} defekt!".to_16
            return_value = false
          end
        end
        @sensor_data << sensor_data
        return_value
      end

      def get_sensor(s_id)
        config[:sensors].each do |s|
          return s if s[:id] == s_id
        end
      end

      def wait_for_lcd_server
        return if SIM_MODE
        loop do
          begin
            s = Lcd.sline('Lcd server up')
            sleep(1)
            return true if s
          rescue
            # puts "waiting for lcd server"
            sleep(1)
          end
        end
      end

      def sensor_name_to_id(name)
        config = ConfigReader.config

        config[:sensors].each do |s|
          return s[:id] if s[:name].downcase == name.downcase
        end
      end

      def compose_condition_from_rule(rule, und = true)
        rule_conditions = und ? rule[:and_conditions] : rule[:or_conditions]
        rule_conditions.map do |condition|
          s_id = sensor_name_to_id(condition[:sensor])
          sensor_data = @sensor_data.last
          c = (sensor_data[s_id] > 0) ? " #{sensor_data[s_id]} #{condition[:comparator]} '#{condition[:value]}'.to_f  " : ' false '
          "( #{c} )"
        end.join(und ? ' and ' : ' or ') if rule_conditions
      end

      def rule_fullfilled(rule)
        # prepare the conditions
        and_condition = compose_condition_from_rule(rule)
        or_condition = compose_condition_from_rule(rule, false)

        rule_condition = [and_condition, or_condition].compact.join(' or ')
        # puts " MEIN CONDITON "
        # puts rule_condition
        # sleep(1)
        if eval " (#{rule_condition}) ? true : false "
          # puts "Condition ist OKAY "
          # save rule temperature
          return true
        end
        false
      end

      def no_faulty_sensor_detected?(rule)
        conditions = rule[:and_conditions]
        conditions += rule[:or_conditions] unless rule[:or_conditions].nil?
        conditions.each do |c|
          s_id = sensor_name_to_id(c[:sensor])
          return false if @sensor_data.last[s_id] < 1
        end
        true
      end

      def perform_action(actuator, action)
        # puts "performing action#{action}"
        excecuted = RelaisCard.send(action, actuator[:channel])
        if excecuted
          Led.action
          Lcd.sline("#{actuator[:name]}=>#{action == 'on' ? 'An' : 'Aus'}")
          # puts "action#{action} executed "
          sleep(3)
        end
      end

      def init
        @status=""
        @sensor_data = []
        # wait for lcd server to go up
        wait_for_lcd_server
        ConfigReader.read_config_file
        ConfigReader.reload_config if ConfigReader.detect_usb_drive
        RelaisCard.init
      end

      def touch_pid_file
        FileUtils.touch('/heatcontroll/tmp/heatcontroll.pid')
      end

      def run
        # main loop
        Led.loading
        init
        config = ConfigReader.config
        loop do
          @status = ""
          if read_temperature
            Led.okay
          else
            Led.warning
          end
          # get the rules
          config[:actuators].each do |actuator|
            actuator[:rules].each do |rule|
              if no_faulty_sensor_detected?(rule)
                perform_action(actuator, rule[:action]) if rule_fullfilled(rule)
              else
                fallback_programm(actuator)
                break
              end
            end
          end
          update_status
          sleep(MAIN_LOOP_INTERVALL)
          touch_pid_file
        end
      end
    end
  end
end

Signal.trap('INT') do|_signo|
  HeatController::MainController.fallback_programm
  exit(0)
end
Signal.trap('KILL') do|_signo|
  HeatController::MainController.fallback_programm
  exit(0)
end
Signal.trap('TERM') do|_signo|
  HeatController::MainController.fallback_programm
  exit(0)
end
HeatController::MainController.run
