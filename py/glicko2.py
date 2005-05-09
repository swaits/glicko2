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


import math
import copy


class Glicko2:
    """
    Glicko-2 Rating calculator class.
    
    This class implements the Glicko-2 rating system algorithm written by 
    Professor Mark E. Glickman.  All rating inputs and outputs are Glicko ratings,
    but internally everything is converted to and considered Glicko-2 ratings.
    
    Glicko-2 is an improvement on the original Glicko, which was, in turn, an
    improvement on the ELO system.
    
    The Glicko-2 system is specified on http://www.glicko.com/
    """

    WIN  = 1.0
    LOSS = 0.0
    DRAW = 0.5

    dvolatility = 0.3

    def __init__ (self, rating = 1500.0, deviation = 350.0, volatility = 0.06):
        """
        Constructor with rating, rating deviation, and volatility optionally
        specified.  If nothing specified, nitializes to a rating of 1500, a 
        rating deviation of 350, and a volatility of 0.06.
        """

        # creat state vars
        self.__rating     = 0.0
        self.__deviation  = 0.0
        self.__volatility = 0.0

        # create empty result lists
        self.__opponents = []
        self.__results   = []

        # initialize state
        self.SetRating(rating)
        self.SetDeviation(deviation)
        self.SetVolatility(volatility)

    def __cmp__(self, other):
        """Comparison operator"""
        return cmp( self.__rating, other.__rating )


    def GetRating (self):
        """
        Get the current rating.  This rating is a Glicko rating, not a Glicko2 rating.
        For details, please see http://www.glicko.com/
        """
        return (self.__rating * 173.7178) + 1500.0

    def GetDeviation (self):
        """
        Get the current rating deviation.  This is a Glicko rating deviation, not a 
        Glicko-2 RD.  For details, please see http://www.glicko.com/
        """
        return self.__deviation * 173.7178

    def GetVolatility (self):
        """
        Get the current rating volatility.
        """
        return self.__volatility

    def SetRating (self, rating):
        """
        Set Glicko rating.  Internally this is converted to a Glicko2 rating.
        For details, please see http://www.glicko.com/
        """
        self.__rating = (rating - 1500.0) / 173.7178

    def SetDeviation(self, deviation):
        """
        Set Glicko rating deviation.  Internally this is converted to a Glicko-2 RD.
        For details, please see http://www.glicko.com/
        """
        self.__deviation = deviation / 173.7178

    def SetVolatility(self, volatility):
        """
        Set rating volatility.
        """
        self.__volatility = volatility

    def ClearResults (self):
        """
        Clear all results previously added via AddResult(), AddWin(), AddLoss(),
        and/or AddDraw().  This method is called automatically whenever Update()
        is called.
        """
        self.__opponents = []
        self.__results   = []

    def AddResult (self, opponent, result):
        """
        Add a result to this rating.  Note that no calculation is performed until
        Update() is called.
        """
        self.__opponents.append(copy.copy(opponent))
        self.__results.append(copy.copy(result)) # copy probably not needed

    def AddWin (self, opponent):
        """
        Add a win result to this rating.  Note that no calculation is performed until
        Update() is called.
        """
        self.AddResult(opponent, self.WIN)

    def AddLoss (self, opponent):
        """
        Add a loss result to this rating.  Note that no calculation is performed until
        Update() is called.
        """
        self.AddResult(opponent, self.LOSS)

    def AddDraw (self, opponent):
        """
        Add a draw result to this rating.  Note that no calculation is performed until
        Update() is called.
        """
        self.AddResult(opponent, self.DRAW)

    def Update (self):
        """
        Update rating based on current results list, and clear results.
        """

        # util func
        def g (deviation):
            """
            Internal utility function.
            """
            return 1.0 / (math.sqrt(1.0 + 3.0 * deviation * deviation / (math.pi * math.pi)));

        # util func
        def E (rating, rating_opponent, deviation_opponent):
            """
            Internal utility function.
            """
            return 1.0 / (1.0 + math.exp(-g(deviation_opponent)*(rating - rating_opponent)));

        # bail if no opponents set
        if len(self.__opponents) == 0:
            return

        # compute variance
        variance = 0.0
        for opp in self.__opponents:
            g_i        = g(opp.__deviation)
            E_i        = E(self.__rating,opp.__rating,opp.__deviation)
            variance  += g_i * g_i * E_i * (1.0 - E_i)
        variance = 1.0 / variance

        # compute delta
        delta = 0.0
        for i in range(len(self.__opponents)):
            delta += g(self.__opponents[i].__deviation) * (self.__results[i] - E(self.__rating, self.__opponents[i].__rating, self.__opponents[i].__deviation))
        delta *= variance

        # determine new volatility
        new_volatility = 0.0
        a              = math.log( math.pow(self.__volatility,2.0) )
        x              = 0.0
        x_new          = a
        while ( abs(x - x_new) > 0.0000001 ):
            x     = x_new;
            d     = math.pow(self.__deviation,2.0) + variance + math.exp(x)
            h1    = -(x - a)/(math.pow(self.dvolatility,2.0)) - 0.5*math.exp(x)/d + 0.5*math.exp(x)*(delta/d)*(delta/d)
            h2    = -1.0/(math.pow(self.dvolatility,2.0)) - 0.5*math.exp(x)*(math.pow(self.__deviation,2.0)+variance)/(pow(d,2.0)) + 0.5*(math.pow(delta,2.0))*math.exp(x)*((math.pow(self.__deviation,2.0)) + variance - math.exp(x))/(pow(d,3.0))
            x_new = x - h1/h2
        new_volatility = math.exp(x_new / 2.0)

        # update the rating deviation to the new pre-rating period value
        pre_deviation = math.sqrt( math.pow(self.__deviation,2.0) + math.pow(new_volatility,2.0) )

        # update the rating and deviation
        new_deviation = 1.0 / (math.sqrt( 1.0/(pow(pre_deviation,2.0)) + 1.0 / variance))
        new_rating    = 0.0
        for i in range(len(self.__opponents)):
            new_rating += g(self.__opponents[i].__deviation) * (self.__results[i] - E(self.__rating, self.__opponents[i].__rating, self.__opponents[i].__deviation))
        new_rating  = new_rating * pow(new_deviation,2.0)
        new_rating += self.__rating

        # copy new values
        self.__rating     = new_rating
        self.__deviation  = new_deviation
        self.__volatility = new_volatility

        # wipe our result lists
        self.ClearResults()



# test code
if __name__ == "__main__":

    A = Glicko2(1500.0, 200.0, 0.06)
    B = Glicko2(1400.0,  30.0, 0.06)
    C = Glicko2(1550.0, 100.0, 0.06)
    D = Glicko2(1700.0, 300.0, 0.06)
    
    A.AddWin(B)
    A.AddLoss(C)
    A.AddResult(D,Glicko2.LOSS)
    
    A.Update();
    
    print "rating",A.GetRating(), "deviation",A.GetDeviation()

