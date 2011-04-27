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



#include "glicko2.h"

#include <vector>
#include <cmath>



class Glicko2_impl
{
	public:

		// constructors
		Glicko2_impl();
		Glicko2_impl(const Glicko2_impl& rhs);

		// copy assignment
		Glicko2_impl& operator=(const Glicko2_impl& rhs);

		// destructor
		virtual ~Glicko2_impl();

		// system constants
		static const double dvolatility;

		// rating data
		double rating;
		double deviation;
		double volatility;

		// result data (copy of each opponent and results, 0.0, 0.5, or 1.0)
		std::vector<Glicko2> opponents;
		std::vector<double>  results;

		// utility functions
		double g(const double& deviation);
		double E(const double& rating, const double& rating_opponent, const double& deviation_opponent);
};



const double Glicko2_impl::dvolatility = 0.3; // should be [0.3,1.2]



Glicko2_impl::Glicko2_impl() :
	rating(0.0),
	deviation(0.0),
	volatility(0.0),
	opponents(),
	results()
{
}



Glicko2_impl::Glicko2_impl(const Glicko2_impl& rhs) :
	rating(rhs.rating),
	deviation(rhs.deviation),
	volatility(rhs.volatility),
	opponents(rhs.opponents),
	results(rhs.results)
{
}



Glicko2_impl& Glicko2_impl::operator=(const Glicko2_impl& rhs)
{
	if ( this == &rhs )
	{
		return *this;
	}

	rating     = rhs.rating;
	deviation  = rhs.deviation;
	volatility = rhs.volatility;
	opponents  = rhs.opponents;
	results    = rhs.results;

	return *this;
}



Glicko2_impl::~Glicko2_impl()
{
}



double Glicko2_impl::g(const double& deviation)
{
#define PI_SQUARED (9.86960440108935861883)
	return 1.0 / (sqrt(1.0 + 3.0 * deviation * deviation / PI_SQUARED));
}



double Glicko2_impl::E(const double& rating, const double& rating_opponent, const double& deviation_opponent)
{
	return 1.0 / (1.0 + exp(-g(deviation_opponent)*(rating - rating_opponent)));
}






Glicko2::Glicko2() :
	pimpl(0)
{
	pimpl = new Glicko2_impl();

	SetRating(1500.0);
	SetDeviation(350.0);
	SetVolatility(0.06);
}



Glicko2::Glicko2(const Glicko2& rhs) :
	pimpl(0)
{
	pimpl = new Glicko2_impl(*(rhs.pimpl));
}



Glicko2::Glicko2(double rating, double deviation, double volatility) :
	pimpl(0)
{
	pimpl = new Glicko2_impl;

	SetRating(rating);
	SetDeviation(deviation);
	SetVolatility(volatility);
}



Glicko2& Glicko2::operator=(const Glicko2& rhs)
{
	if ( this == &rhs )
	{
		return *this;
	}

	*pimpl = *rhs.pimpl;

	return *this;
}



Glicko2::~Glicko2()
{
	delete pimpl;
}



bool Glicko2::operator< (const Glicko2& rhs)
{
	return pimpl->rating < rhs.pimpl->rating;
}



double Glicko2::GetRating() const
{
	return pimpl->rating * 173.7178 + 1500.0;
}



double Glicko2::GetDeviation() const
{
	return pimpl->deviation * 173.7178;
}



double Glicko2::GetVolatility() const
{
	return pimpl->volatility;
}



void Glicko2::SetRating(double rating)
{
	pimpl->rating = (rating - 1500.0) / 173.7178;
}



void Glicko2::SetDeviation(double deviation)
{
	pimpl->deviation = deviation / 173.7178;
}



void Glicko2::SetVolatility(double volatility)
{
	pimpl->volatility = volatility;
}




void Glicko2::ClearResults()
{
	pimpl->opponents.clear();
	pimpl->results.clear();
}



void Glicko2::AddResult(const Glicko2& opponent, RESULT result)
{
	pimpl->opponents.push_back(opponent);

	switch ( result )
	{
		case WIN:
			pimpl->results.push_back(1.0);
			break;

		case LOSS:
			pimpl->results.push_back(0.0);
			break;

		case DRAW:
			pimpl->results.push_back(0.5);
			break;
	}
}



void Glicko2::AddWin(const Glicko2& opponent)
{
	AddResult(opponent,WIN);
}



void Glicko2::AddLoss(const Glicko2& opponent)
{
	AddResult(opponent,LOSS);
}



void Glicko2::AddDraw(const Glicko2& opponent)
{
	AddResult(opponent,DRAW);
}



void Glicko2::Update()
{
	// bail if no opponents set
	if ( pimpl->opponents.size() == 0 )
	{
		return;
	}

	// compute variance
	double variance = 0.0;
	for ( unsigned int i=0;i<pimpl->opponents.size();i++ )
	{
		double g_i = pimpl->g(pimpl->opponents[i].pimpl->deviation);
		double E_i = pimpl->E(pimpl->rating,pimpl->opponents[i].pimpl->rating,pimpl->opponents[i].pimpl->deviation);
		variance  += g_i * g_i * E_i * (1.0 - E_i);
	}
	variance = 1.0 / variance;

	// compute delta
	double delta = 0.0;
	for ( unsigned int i=0;i<pimpl->opponents.size();i++ )
	{
		delta += pimpl->g(pimpl->opponents[i].pimpl->deviation) * (pimpl->results[i] - pimpl->E(pimpl->rating,pimpl->opponents[i].pimpl->rating,pimpl->opponents[i].pimpl->deviation));
	}
	delta *= variance;

	// determine new volatility
	double new_volatility = 0.0;
	double a              = log(pimpl->volatility*pimpl->volatility);
	double x              = 0.0;
	double x_new          = a;
	while ( abs(x - x_new) > 0.0000001 )
	{
		       x     = x_new;
		double d     = pimpl->deviation*pimpl->deviation + variance + exp(x);
		double h1    = -(x - a)/(Glicko2_impl::dvolatility*Glicko2_impl::dvolatility) - 0.5*exp(x)/d + 0.5*exp(x)*(delta/d)*(delta/d);
		double h2    = -1.0/(Glicko2_impl::dvolatility*Glicko2_impl::dvolatility) - 0.5*exp(x)*(pimpl->deviation*pimpl->deviation+variance)/(d*d) + 0.5*(delta*delta)*exp(x)*((pimpl->deviation*pimpl->deviation) + variance - exp(x))/(d*d*d);
		       x_new = x - h1/h2;
	}
	new_volatility = exp(x_new / 2.0);

	// update the rating deviation to the new pre-rating period value
	double pre_deviation = sqrt( pimpl->deviation*pimpl->deviation + new_volatility*new_volatility );

	// update the rating and deviation
	double new_deviation = 1.0 / (sqrt( 1.0/(pre_deviation*pre_deviation) + 1.0 / variance));
	double new_rating    = 0.0;
	for ( unsigned int i=0;i<pimpl->opponents.size();i++ )
	{
		new_rating += pimpl->g(pimpl->opponents[i].pimpl->deviation) * (pimpl->results[i] - pimpl->E(pimpl->rating,pimpl->opponents[i].pimpl->rating,pimpl->opponents[i].pimpl->deviation));
	}
	new_rating  = new_rating * new_deviation * new_deviation;
	new_rating += pimpl->rating;

	// copy new values
	pimpl->rating     = new_rating;
	pimpl->deviation  = new_deviation;
	pimpl->volatility = new_volatility;

	// wipe our result lists
	ClearResults();
}

