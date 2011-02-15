#!/usr/bin/ruby

for i in 102..220
puts "host virtlab#{i} {"
puts "hardware ethernet 52:54:00:e9:8b:#{i.to_s(16)};"
puts "fixed-address 192.168.13.#{i};"
puts "}"

end
puts "}"

