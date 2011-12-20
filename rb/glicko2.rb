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
  attr_reader :g2rating, :g2deviation, :g2volatility

  # a nested Class to hold a single result
  Result = Struct.new(:opponent, :result)

  public

  WIN  = 1.0
  LOSS = 0.0
  DRAW = 0.5

  # system constant, determines delta volatility over time; should be [0.3,1.2]
  DVOL = 0.3

  # Constructor with rating, rating deviation, and volatility optionally
  # specified.  If nothing specified, nitializes to a rating of 1500, a 
  # rating deviation of 350, and a volatility of 0.06.
  def initialize(rating = 1500.0, deviation = 350.0, volatility = 0.06)
    self.rating     = rating
    self.deviation  = deviation
    self.volatility = volatility
    clear_results
  end

  include Comparable

  # Comparison operator
  def <=>(other)
    p_win(other) <=> 0.5
  end

  # get the probability of beating opponent
  def p_win(opponent)
    1.0 / (1.0 + 10.0**(((opponent.rating - self.rating) / (400.0 * Math.sqrt(1.0 + 0.0000100723986 * (self.deviation**2.0 + opponent.deviation**2.0))))))
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
    @opponents = Array.new
    @results   = Array.new
  end

  # Add a result to this rating.  Note that no calculation is performed until
  # update() is called.
  def add_result(opponent,result)
    @results << Result.new(opponent.clone, result)
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

  # util func 'g'
  def Glicko2.g(deviation)
    1.0 / (Math.sqrt(1.0 + 3.0 * deviation ** 2.0 / (Math::PI ** 2.0)))
  end

  # util func 'E'
  def Glicko2.E(rating, rating_opponent, deviation_opponent)
    1.0 / (1.0 + Math.exp(-Glicko2.g(deviation_opponent)*(rating - rating_opponent)));
  end

  # Update rating based on current results list, and clear results.
  def update
    # Note that if a player does not compete during the rating period, then
    # only Step 6 applies. 
    if @results.empty?
      # In this case, the player's rating and volatility parameters remain the
      # same, but the RD increases according to:
      @g2deviation = Math.sqrt(@g2deviation**2.0 + @g2volatility**2.0)
      return
    end

    # Step 1. Determine a rating and RD for each player at the onset of the
    # rating period. The system constant which constrains the change in
    # volatility over time, needs to be set prior to application of the system.
    # Reasonable choices are between 0.3 and 1.2, though the system should be
    # tested to decide which value results in greatest predictive accuracy
    # ... (ratings already stored in instance)

    # Step 2. For each player, convert the ratings and RD's onto the Glicko-2
    # scale.
    # ... (ratings already stored in G2 format)

    # Step 3.  Compute the quantity v. This is the estimated variance of the
    # team's/player's rating based only on game outcomes.
    variance = 1.0 / @results.inject(0.0) do |sum,r|
      g_i = Glicko2.g(r.opponent.g2deviation)
      e_i = Glicko2.E(@g2rating, r.opponent.g2rating, r.opponent.g2deviation)
      sum + g_i**2.0 * e_i * (1.0 - e_i)
    end

    # Step 4. Compute the quantity delta, the estimated improvement in rating
    # by comparing the pre-period rating to the performance rating based only
    # on game outcomes.
    delta = variance * @results.inject(0.0) do |sum,r|
      sum + Glicko2.g(r.opponent.g2deviation) * (r.result - Glicko2.E(@g2rating, r.opponent.g2rating, r.opponent.g2deviation))
    end

    # Step 5. Determine the new value of the volatility.
    a      = Math.log(@g2volatility**2.0)
    x0, x1 = 0.0, a
    while ((x0 - x1).abs > 0.0000001)
      x0 = x1
      d  = @g2deviation**2.0 + variance + Math.exp(x0)
      h1 = -(x0 - a)/(DVOL**2.0) - 0.5*Math.exp(x0)/d + 0.5*Math.exp(x0)*(delta/d)*(delta/d)
      h2 = -1.0/(DVOL**2.0) - 0.5*Math.exp(x0)*(@g2deviation**2.0+variance)/(d**2.0) + 0.5*(delta**2.0)*Math.exp(x0)*((@g2deviation**2.0) + variance - Math.exp(x0))/(d**3.0)
      x1 = x0 - h1/h2
    end
    new_volatility = Math.exp(x1 / 2.0)

    # Step 6. Update the rating deviation to the new pre-rating period value.
    pre_deviation = Math.sqrt(@g2deviation**2.0 + new_volatility**2.0)

    # Step 7. Update the rating and RD to the new values.
    new_deviation = 1.0 / (Math.sqrt(1.0/(pre_deviation**2.0) + 1.0 / variance))
    new_rating    = @g2rating + new_deviation**2.0 * @results.inject(0.0) do |sum,r|
      g_i = Glicko2.g(r.opponent.g2deviation)
      e_i = Glicko2.E(@g2rating, r.opponent.g2rating, r.opponent.g2deviation)
      sum + g_i * (r.result - e_i)
    end

    # Step 8. Convert ratings and RD's back to original scale.
    @g2deviation  = new_deviation
    @g2volatility = new_volatility
    @g2rating     = new_rating

    # wipe our result lists
    clear_results
  end

end

