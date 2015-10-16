Signal.trap('INT') do|_signo|
  puts " INTERRUPT received "
  exit(0)
end
Signal.trap('TERM') do|_signo|
  puts " Terminate received "
  exit(0)
end

command = Thread.new do
  stop = false
  Signal.trap('INT') do|_signo|
    puts " Thread Interupted  "
    stop = true
  end
  
  10.times do
    puts " me and me "
    puts " Exiting " if stop
    Thread.exit if stop
    sleep(1)
  end
end

puts " befor gejoin wird "
command.join                 # main programm waiting for thread
puts "command complete"