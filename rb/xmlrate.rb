#!/usr/bin/env ruby

require "rexml/document"
require "glicko2"

# sort & output the player array
def output_players(playerhash,title="")
	puts title
	sorted_players = playerhash.sort { |a,b| a[1] <=> b[1] }
	i = 0
	sorted_players.reverse.each { |k,v| puts sprintf("%3d%30s: %6.1f   +/- %5.1f   %0.05f\n",i += 1,k,v.rating,v.deviation,v.volatility) }
	puts
end

# handle one file
def parse_file(filename)

	# load & parse XML
	file = File.new(filename)
	doc = REXML::Document.new(file)
	
	# each rating doc
	doc.elements.each("ratingdoc") do |root|
	
		# new/empty player hash											
		players = Hash.new
	
		# each player
		root.elements.each("player") do |player|
	
			# setup defaults
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

			# create player + glicko2 object
			players[name] = Glicko2.new(rating.to_f,deviation.to_f,variance.to_f)
	
		end
	
		# dump initial player ratings
		output_players(players,"initial ratings")
		
		# each rating period
		period_id = 0
		root.elements.each("period") do |period|
	
			# each regular game
			period.elements.each("game") do |game|
			
				home = game.elements["home"].text
				away = game.elements["away"].text
				result = game.elements["result"].text
	
				result_val = Glicko2::WIN if result == "win"
				result_val = Glicko2::LOSS if result == "loss"
				result_val = Glicko2::DRAW if result == "draw"
				
				players[home].add_result( players[away], result_val )
				players[away].add_result( players[home], 1.0 - result_val )
			end
	
			# each race
			racelist = []
			period.elements.each("race") do |race|
				race.elements.each("competitor") do |c|
				
					# make this competitor lose to everyone already in our list
					racelist.each do |otherc|
						players[otherc].add_win(players[c.text])
						players[c.text].add_loss(players[otherc])		
					end
	
					# add this competitor to our list
					racelist.push(c.text)
					
				end
			end
	
			# update all players
			players.each_value { |p| p.update }
	
			# output players
			output_players(players,sprintf("after rating period %d",period_id += 1))
	
		end
	
	end
end


# main program
ARGV.each { |a| parse_file(a) }


