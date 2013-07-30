#!/usr/bin/env ruby -w

#
#
# Copyright (c) 2004 Stephen Waits
# 
# This software is provided 'as-is', without any express or implied warranty. In
# no event will the authors be held liable for any damages arising from the use
# of this software.
# 
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it freely,
# subject to the following restrictions:
# 
# 1. The origin of this software must not be misrepresented; you must not claim
#    that you wrote the original software. If you use this software in a
#    product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
# 
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 
# 3. This notice may not be removed or altered from any source distribution.
#
#


# Glicko-2 Rating calculator class.
#
# This class implements the Glicko-2 rating system algorithm written by 
# Professor Mark E. Glickman.  All rating inputs and outputs are Glicko ratings,
# but internally everything is converted to and considered Glicko-2 ratings.
#
# Glicko-2 is an improvement on the original Glicko, which was, in turn, an
# improvement on the ELO system.
#
# The Glicko-2 system is specified on http://www.glicko.com/
# 
class Glicko2

  protected

    # Glicko2 reprensentation (Glicko2 uses different scales from Glicko)
    attr_accessor :g2rating, :g2deviation, :g2volatility

    # a nested Class to hold a single result
    Result = Struct.new(:opponent, :result)

  public

    WIN  = 1.0
    LOSS = 0.0
    DRAW = 0.5

    # Constructor with rating, rating deviation, and volatility optionally
    # specified.  If nothing specified, nitializes to a rating of 1500, a 
    # rating deviation of 350, and a volatility of 0.06.
    def initialize(rating = 1500.0, deviation = 350.0, volatility = 0.06)
      @dvolatility    = 0.3
      self.rating     = rating
      self.deviation  = deviation
      self.volatility = volatility
      clear_results
    end

    include Comparable

    # Comparison operator
    def <=>(other)
      self.rating <=> other.rating
    end

    # Get the current rating.  This rating is a Glicko rating, not a Glicko2 rating.
    # For details, please see http://www.glicko.com/
    def rating
      (@g2rating * 173.7178) + 1500.0
    end

    # Set Glicko rating.  Internally this is converted to a Glicko2 rating.
    # For details, please see http://www.glicko.com/
    def rating=(r)
      @g2rating = (r - 1500.0) / 173.7178
    end

    # Get the current rating deviation.  This is a Glicko rating deviation, not a 
    # Glicko-2 RD.  For details, please see http://www.glicko.com/
    def deviation
      @g2deviation * 173.7178
    end

    # Set Glicko rating deviation.  Internally this is converted to a Glicko-2 RD.
    # For details, please see http://www.glicko.com/
    def deviation=(d)
      @g2deviation = d / 173.7178
    end

    # Get the current rating volatility.
    def volatility
      @g2volatility
    end

    # Set rating volatility.
    def volatility=(v)
      @g2volatility = v
    end

    # Clear all results previously added via add_result(), add_win(), add_loss(),
    # and/or add_draw().  This method is called automatically whenever update()
    # is called.
    def clear_results
      @opponents = []
      @results = []
    end

    # Add a result to this rating.  Note that no calculation is performed until
    # update() is called.
    def add_result(opponent,result)
      @results.push( Result.new(opponent.clone, result) )
    end

    # Add a win result to this rating.  Note that no calculation is performed until
    # update() is called.
    def add_win(opponent)
      add_result(opponent,Glicko2::WIN)
    end

    # Add a loss result to this rating.  Note that no calculation is performed until
    # update() is called.
    def add_loss(opponent)
      add_result(opponent,Glicko2::LOSS)
    end

    # Add a draw result to this rating.  Note that no calculation is performed until
    # update() is called.
    def add_draw(opponent)
      add_result(opponent,Glicko2::DRAW)
    end

    # util func
    def Glicko2.g(deviation)
      1.0 / (Math.sqrt(1.0 + 3.0 * deviation ** 2.0 / (Math::PI ** 2.0)))
    end

    # util func
    def Glicko2.E(rating, rating_opponent, deviation_opponent)
      1.0 / (1.0 + Math.exp(-Glicko2.g(deviation_opponent)*(rating - rating_opponent)));
    end

    # Update rating based on current results list, and clear results.
    def update
      # util func

      # bail if no opponents set
      if @results.empty?
        @g2deviation = Math.sqrt(@g2deviation**2.0 + @g2volatility**2.0)
        return
      end

      # compute variance

      #variance = 0.0
      #@results.inject(0.0) do |variance,r|
      # g_i = Glicko2.g(r.opponent.g2deviation)
      # e_i = Glicko2.E(@g2rating,r.opponent.g2rating,r.opponent.g2deviation)
      # g_i ** 2.0 * e_i * (1.0 - e_i)
      #end

      variance = 0.0
      @results.each do |r|
        g_i = Glicko2.g(r.opponent.g2deviation)
        e_i = Glicko2.E(@g2rating,r.opponent.g2rating,r.opponent.g2deviation)
        variance += g_i ** 2.0 * e_i * (1.0 - e_i)
      end
      variance = 1.0 / variance

      # compute delta
      delta = 0.0
      @results.each do |r|
        delta += Glicko2.g(r.opponent.g2deviation) * (r.result - Glicko2.E(@g2rating, r.opponent.g2rating, r.opponent.g2deviation))
      end
      delta *= variance

      # determine new volatility
      new_volatility = 0.0
      a              = Math.log( @g2volatility**2.0 )
      x              = 0.0
      x_new          = a
      while ( (x - x_new).abs > 0.0000001 )
        x     = x_new
        d     = @g2deviation**2.0 + variance + Math.exp(x)
        h1    = -(x - a)/(@dvolatility**2.0) - 0.5*Math.exp(x)/d + 0.5*Math.exp(x)*(delta/d)*(delta/d)
        h2    = -1.0/(@dvolatility**2.0) - 0.5*Math.exp(x)*(@g2deviation**2.0+variance)/(d**2.0) + 0.5*(delta**2.0)*Math.exp(x)*((@g2deviation**2.0) + variance - Math.exp(x))/(d**3.0)
        x_new = x - h1/h2
      end
      new_volatility = Math.exp(x_new / 2.0)

      # update the rating deviation to the new pre-rating period value
      pre_deviation = Math.sqrt( @g2deviation**2.0 + new_volatility**2.0 )

      # update the rating and deviation
      new_deviation = 1.0 / (Math.sqrt( 1.0/(pre_deviation**2.0) + 1.0 / variance))
      new_rating    = 0.0
      @results.each do |r|
          new_rating += Glicko2.g(r.opponent.g2deviation) * (r.result - Glicko2.E(@g2rating, r.opponent.g2rating, r.opponent.g2deviation))
      end
      new_rating  = new_rating * new_deviation**2.0
      new_rating += @g2rating

      # wipe our result lists
      clear_results

      # copy new values
      @g2deviation  = new_deviation
      @g2volatility = new_volatility
      @g2rating     = new_rating
    end
end

