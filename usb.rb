       # first check if we have the sda? directory 
       puts "enter"
       if File.exists?("/dev/sda1")
         puts "dir found "
         #RubyLcd.print({text:"Usb erkannt"})
         sleep(2)
         puts "try to mount" 
         system("mount /dev/sda1 /media/usb")
         #RubyLcd.print({text:"Wird gelesen"})
         sleep(3)
         if File.exists?("/media/usb/config.json")           
          #RubyLcd.print({text:"Konfig Datei  gefunden"})
         else
          #RubyLcd.print({text:"Keine Konfiguration"})           
         end
         sleep(2)
       end
    