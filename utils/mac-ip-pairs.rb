#!/usr/bin/ruby
if false then
for i in 102..220
puts "host virtlab#{i} {"
puts "hardware ethernet 52:54:00:e9:8b:#{i.to_s(16)};"
puts "fixed-address 192.168.13.#{i};"
puts "}"

end
puts "}"
end
puts "start"
system './start_machine.sh 52:54:00:e9:8b:66 /var/www test'
puts "fin"
