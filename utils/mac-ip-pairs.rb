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
#puts "start"
#system './start_machine.sh 52:54:00:e9:8b:66 /var/www test'
#puts "fin"

# add more macs
=begin

(1..999).each do |nr|
	Mac.create(:mac=>"52:54:00:e9:9#{nr.to_s(16)[0]}:#{nr.to_s(16).last(2)}", :ip=> "192.168.13.#{nr}")
end
(1..101).each do |nr|
	Mac.create(:mac=>"52:54:00:e9:9#{nr.to_s(16)[0]}:#{nr.to_s(16).last(2)}", :ip=> "192.168.13.#{nr}")
end

=end
