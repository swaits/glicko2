
require "rexml/document"

file = File.new( "../py/data/hockey-2005.xml" )

doc = REXML::Document.new(file)

# each rating doc
doc.elements.each("ratingdoc") do |root|

	# each player
	root.elements.each("player") do |player|

		name      = player.elements["name"].text
		rating    = 1500.0
		deviation = 350.0
		variance  = 0.06

		# TODO: find better "Ruby-esqe" way of doing these
		if player.elements["rating"]
			rating = player.elements["rating"].text
		end
		if player.elements["deviation"]
			deviation = player.elements["deviation"].text
		end
		if player.elements["variance"]
			variance = player.elements["variance"].text
		end

		puts name,rating,deviation,variance
		puts

	end
	
	# each rating period
	root.elements.each("period") do |period|

		# each regular game
		period.elements.each("game") do |game|
			puts "home",game.elements["home"].text
			puts "away",game.elements["away"].text
			puts "result",game.elements["result"].text
			puts
		end

		# each race
		period.elements.each("race") do |race|
			race.elements.each("competitor") do |c|
				puts c.text
			end
			puts
		end

	end

end

