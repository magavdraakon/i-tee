# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
(0...5).each do |a|
	(16..200).each do |b|
		first = (a+16).to_s(16).upcase
		second = b.to_s(16).upcase
		ip = b+a*199
		Mac.create({:mac=> "52:54:00:e9:#{first}:#{second}", :ip=> "192.168.13.#{ip}"})
	end
end