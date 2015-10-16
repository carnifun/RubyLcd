#!/usr/bin/ruby

# start the heat Controller Main programm and server 
#APP_PATH = "/home/pi/heatcontroll"
#APP_PATH = File.dirname(__FILE__)
APP_PATH = " ss"



puts `echo #{APP_PATH}`

# start lcd server 
# `#{File.join( APP_PATH, "lcd_server.rb")} > test.log 2>&1`
` ruby test2.rb > test.log 2>&1 `

puts " bin raus "
