#!/usr/bin/ruby

# This is a simple wrapper designed to be run by an external script.

# It checks to see if the time is within the allowable range for the script to
# run and then calls the main Konstabot script.

time = Time.new
puts time

if time.wday.between?(1,6) && time.hour.between?(8,17)
    puts "Running Konstabot"
    `ruby konstabot.rb -n 10 -H`
else
   puts "Skipped"
end

