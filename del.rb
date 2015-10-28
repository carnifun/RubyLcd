
require 'rb-inotify'
notifier = INotify::Notifier.new
notifier.watch('/heatcontroll/tmp/lcd_file', :modify) { puts 'foo.txt was modified!' }

notifier.process

loop do
  puts '... '
  sleep(1)
end
