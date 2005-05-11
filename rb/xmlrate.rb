
require "rexml/document"
require "glicko2"

file = File.new( "../py/data/hockey-2005.xml" )

doc = REXML::Document.new(file)

# each rating doc
doc.elements.each("ratingdoc") do |root|

	players = Hash.new

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

		players[name] = Glicko2.new(rating.to_f,deviation.to_f,variance.to_f)
		puts name,rating,deviation,variance
		puts

	end
	
	# each rating period
	root.elements.each("period") do |period|

		# each regular game
		period.elements.each("game") do |game|
		
			home = game.elements["home"].text
			away = game.elements["away"].text
			result = game.elements["result"].text
			
			players[home].add_result( players[away], result.to_f )
			players[away].add_result( players[home], 1.0 - result.to_f )
		end

		# each race
		period.elements.each("race") do |race|
			race.elements.each("competitor") do |c|
				puts c.text
			end
			puts
		end

		# update all players
		players.each_value { |p| p.update }
		players.each { |p,r| puts p,r.rating }

	end

end

