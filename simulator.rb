print "\e[2J"
loop do   
  sleep(0.4)
  print "\e[0;0H\n"
  print "================\n"
  inhalt = File.read("output.txt")
  puts inhalt.gsub(/ /, '-')  
  print "================\n"
end


