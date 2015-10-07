def do_it ( counter )
  
  
  loop do 
    puts " in the loop #{counter}"    
    break if $stop 
    sleep(1) 
  end  
  puts "Counter stopped #{counter }"
end




  $stop = false 

def main 
  
  i = 100

  loop do     
    Thread.start do 
      puts " starting threads and wait 5 seconds"
      do_it(i)
    end
    sleep(5)
    i+=1
    $stop = true if i == 103
  end
  
  
end


main 