module HeatController
  class ConfigReader
    class << self
      @config = nil

      def update_network_setting
        return false unless @config[:network]
        int_file = '/etc/wpa_supplicant/wpa_supplicant.conf'
        content = File.read(int_file)
        content = content.gsub(/ssid=.*/, "ssid=\"#{@config[:network][:ssid]}\"")
        content = content.gsub(/psk=.*/, "psk=\"#{@config[:network][:psk]}\"")
        f = File.open(int_file, 'w+')
        f.puts content
        f.close
        true
      end

      def read_config_file(new_file = false)
        log 'Reading Config File '
        @config = json_from_file(File.join(APP_ROOT, 'config', 'config.json'))
        log 'Reading Configuration file  '
        log '======================================= '
        if @config.nil?
          Lcd.mlines('lade default'.to_16 + 'Configuration')
          sleep(5)
          @config = json_from_file(File.join(APP_ROOT, 'config', 'config.default.json'))
          if @config.nil?
            Lcd.mlines('Keine Konfiguration'.to_16 + 'gefunden. exit')
            Led.fatal_error
            exit
          end
        end
        if new_file && false
          if update_network_setting
            Lcd.mlines('System Reboot'.to_16 + 'Usb entfernen.')
            sleep(5)
            system('reboot')
            exit(0)
          end
        end
        end

      def json_from_file(file)
        log "Loading #{file}"
        content = File.read(file) if File.exist?(file)
        json_from_content(content) unless content.nil?
      end

      def json_from_content(content)
        require 'json'
        begin
          JSON.parse(content, symbolize_names: true)
        rescue
          nil
        end
      end

      def reload_config
        log 'Getting new Configuration '
        # content = File.read("/media/usb/config.json")
        content = File.read(File.join(APP_ROOT, 'config', 'config.json.new'))
        if json_from_content(content).nil?
          Lcd.mlines('Konfiguration    ist FEHLERHAFT')
          log ' Json error Configuration '
          sleep(2)
          return
        end
        log ' Json Configuration is Okay '
        Lcd.mlines('Lade neue       Konfiguration ')
        sleep(4)
        log ' renaming files  '
        src = File.join(APP_ROOT, 'config', 'config.json.new')
        target = File.join(APP_ROOT, 'config', 'config.json')
        FileUtils.cp(src, target)
        log 'Copy Config filee  Finisched '
        read_config_file(true)
      end

      def detect_usb_drive
        require 'fileutils'
        # first check if we have the sda? directory
        usb_path = ''
        Dir['/dev/disk/by-uuid/*'].each do |f|
          puts File.realpath(f)
          if File.realpath(f).match(/\/dev\/sd[a-z]\d/)
            usb_path = f
            break
          end
        end

        if File.exist?(usb_path)
          # puts "dir found "
          Lcd.mlines('Usb erkannt')
          sleep(1)
          system('umount /media/usb')
          log ' Unmounting usb '
          sleep(5)
          log(' mounting usb ')
          system("mount -t vfat -o rw #{usb_path} /media/usb")
          sleep(2)
          Lcd.mlines('Usb-media Wird gelesen')
          sleep(2)
          if File.exist?('/media/usb/config.json')
            log (' Config file on  usb Found ')
            Lcd.mlines('Konfig Datei  gefunden')
            sleep(5)
            log(' copy file from usb to drive ')
            FileUtils.cp('/media/usb/config.json', '/heatcontroll/config/config.json.new')
            
          else
            Lcd.mlines('config.json     NICHT gefunden!')
            sleep(2)
            return false
          end
          if File.exist?('/media/usb/wpa_supplicant.conf')
            log (' Network config found  ')
            Lcd.mlines('Netwerk Datei  gefunden')
            sleep(2)
            log(' copy file from usb to drive ')
            FileUtils.cp('/media/usb/wpa_supplicant.conf', '/etc/wpa_supplicant/wpa_supplicant.conf')
            Lcd.mlines('System Reboot'.to_16 + 'Usb entfernen.')
            sleep(5)
            system('reboot')
            exit(0)
            #return true
          end
          return true          
        end
        false
        end

      attr_reader :config
    end
  end
end
