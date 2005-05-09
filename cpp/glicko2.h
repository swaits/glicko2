/*

  Copyright (c) 2004 Stephen Waits
  
  This software is provided 'as-is', without any express or implied warranty. In
  no event will the authors be held liable for any damages arising from the use
  of this software.
  
  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it freely,
  subject to the following restrictions:
  
  1. The origin of this software must not be misrepresented; you must not claim
     that you wrote the original software. If you use this software in a
     product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  
  3. This notice may not be removed or altered from any source distribution.

*/



#ifndef __glicko2_h__
#define __glicko2_h__



class Glicko2_impl;



/**
 * Glicko-2 Rating calculator class.
 * 
 * This class implements the Glicko-2 rating system algorithm written by 
 * Professor Mark E. Glickman.  All rating inputs and outputs are Glicko ratings,
 * but internally everything is converted to and considered Glicko-2 ratings.
 * 
 * Glicko-2 is an improvement on the original Glicko, which was, in turn, an
 * improvement on the ELO system.
 * 
 * The Glicko-2 system is specified on http://www.glicko.com/
 */
class Glicko2
{
public:



	/**
	 * Enumeration of possible results.
	 */
	enum RESULT
	{
		/**
		 * A win result, internally 1.0.
		 */
		WIN,

		/**
		 * A loss result, internally 0.0.
		 */
		LOSS,

		/**
		 * A draw result, internally 0.5.
		 */
		DRAW
	};



	/**
	 * Default constructor.  Initializes to a rating of 1500, a rating deviation 
	 * of 350, and a volatility of 0.06.
	 */
	Glicko2();

	/**
	 * Copy constructor.
	 * 
	 * @param rhs    Object to copy.
	 */
	Glicko2(const Glicko2& rhs);

	/**
	 * Constructor with rating, rating deviation, and volatility specified.
	 * 
	 * @param rating     Initial rating.
	 * @param deviation  Initial rating deviation.
	 * @param volatility Initial volatility.
	 */
	Glicko2(double rating, double deviation, double volatility);



	/**
	 * Copy assignment operator.
	 * 
	 * @param rhs    Object to copy.
	 * 
	 * @return Reference to self after copy assignment.
	 */
	Glicko2& operator=(const Glicko2& rhs);



	/**
	 * Destructor.
	 */
	virtual ~Glicko2();



	/**
	 * Less than comparison operator.
	 * 
	 * @param rhs    Object to compare against.
	 * 
	 * @return true if this object's rating is less than rhs's rating; false otherwise.
	 */
	bool operator< (const Glicko2& rhs);



	/**
	 * Get the current rating.  This rating is a Glicko rating, not a Glicko2 rating.
	 * For details, please see http://www.glicko.com/
	 * 
	 * @return 
	 */
	double GetRating() const;

	/**
	 * Get the current rating deviation.  This is a Glicko rating deviation, not a 
	 * Glicko-2 RD.  For details, please see http://www.glicko.com/
	 * 
	 * @return 
	 */
	double GetDeviation() const;

	/**
	 * Get the current rating volatility.
	 * 
	 * @return 
	 */
	double GetVolatility() const;



	/**
	 * Set Glicko rating.  Internally this is converted to a Glicko2 rating.
	 * For details, please see http://www.glicko.com/
	 * 
	 * @param rating Rating.
	 */
	void SetRating(double rating);

	/**
	 * Set Glicko rating deviation.  Internally this is converted to a Glicko-2 RD.
	 * For details, please see http://www.glicko.com/
	 * 
	 * @param deviation Rating deviation.
	 */
	void SetDeviation(double deviation);

	/**
	 * Set rating volatility.
	 * 
	 * @param volatility Rating volatility.
	 */
	void SetVolatility(double volatility);



	/**
	 * Clear all results previously added via AddResult(), AddWin(), AddLoss(),
	 * and/or AddDraw().  This method is called automatically whenever Update()
	 * is called.
	 */
	void ClearResults();



	/**
	 * Add a result to this rating.  Note that no calculation is performed until
	 * Update() is called.
	 * 
	 * @param opponent Other player in contest.
	 * @param result   WIN, LOSS, or DRAW; from the point of view of this player.
	 */
	void AddResult(const Glicko2& opponent, RESULT result);



	/**
	 * Add a win result to this rating.  Note that no calculation is performed until
	 * Update() is called.
	 * 
	 * @param opponent Other (losing) player in contest.
	 */
	void AddWin(const Glicko2& opponent);

	/**
	 * Add a loss result to this rating.  Note that no calculation is performed until
	 * Update() is called.
	 * 
	 * @param opponent Other (winning) player in contest.
	 */
	void AddLoss(const Glicko2& opponent);

	/**
	 * Add a draw result to this rating.  Note that no calculation is performed until
	 * Update() is called.
	 * 
	 * @param opponent Other (drawing) player in contest.
	 */
	void AddDraw(const Glicko2& opponent);



	/**
	 * Update rating based on current results list, and clear results.
	 */
	void Update();



private:

	/**
	 * Private Implementation.
	 */
	Glicko2_impl* pimpl;

};



#endif // __glicko2_h__

