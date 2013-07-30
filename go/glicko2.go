//
//
// Copyright (c) 2013 Stephen Waits
// 
// This software is provided 'as-is', without any express or implied warranty. In
// no event will the authors be held liable for any damages arising from the use
// of this software.
// 
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it freely,
// subject to the following restrictions:
// 
// 1. The origin of this software must not be misrepresented; you must not claim
//    that you wrote the original software. If you use this software in a
//    product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 
// 3. This notice may not be removed or altered from any source distribution.
//
//
//
// Glicko-2 Rating calculator package.
//
// This package implements the Glicko-2 rating system algorithm written by
// Professor Mark E. Glickman.  All rating inputs and outputs are Glicko ratings,
// but internally everything is converted to and considered Glicko-2 ratings.
//
// Glicko-2 is an improvement on the original Glicko, which was, in turn, an
// improvement on the ELO system.
//
// The Glicko-2 system is specified on http://www.glicko.com/
//
package glicko2

import (
	"fmt"
	"math"
)

// system constant, determines delta volatility over time; should be [0.3,1.2]
const kDVOL float64 = 0.3

// Glicko2 state reprensentation (Glicko2 uses different scales from Glicko)
type Glicko2 struct {
	rating     float64
	deviation  float64
	volatility float64
	wins       [](*Glicko2)
	losses     [](*Glicko2)
	draws      [](*Glicko2)
}

// Initializer with rating, rating deviation, and volatility specified.
func NewGlicko2(rating float64, deviation float64, volatility float64) *Glicko2 {
	return newGlicko2(rating, deviation, volatility)
}

// Initializer with default rating, rating deviation, and volatility.
func NewDefaultGlicko2() *Glicko2 {
	return newGlicko2(1500.0, 350.0, 0.06)
}

// helper for initialization
func newGlicko2(rating float64, deviation float64, volatility float64) *Glicko2 {
	g := new(Glicko2)
	g.SetRating(rating)
	g.SetDeviation(deviation)
	g.SetVolatility(volatility)
	return g
}

// get the probability of beating opponent
func (g *Glicko2) ProbWin(opponent *Glicko2) float64 {
	return 1.0 / (1.0 + math.Pow(10.0, ((opponent.Rating()-g.Rating())/(400.0*math.Sqrt(1.0+0.0000100723986*((g.Deviation()*g.Deviation())+(opponent.Deviation()*opponent.Deviation())))))))
}

// Get the current rating.  This rating is a Glicko rating, not a Glicko2 rating.
// For details, please see http://www.glicko.com/
func (g *Glicko2) Rating() float64 {
	return ((g.rating * 173.7178) + 1500.0)
}

// Set Glicko rating.  Internally this is converted to a Glicko2 rating.
// For details, please see http://www.glicko.com/
func (g *Glicko2) SetRating(rating float64) {
	g.rating = (rating - 1500.0) / 173.7178
}

// Get the current rating deviation.  This is a Glicko rating deviation, not a
// Glicko-2 RD.  For details, please see http://www.glicko.com/
func (g *Glicko2) Deviation() float64 {
	return (g.deviation * 173.7178)
}

// Set Glicko rating deviation.  Internally this is converted to a Glicko-2 RD.
// For details, please see http://www.glicko.com/
func (g *Glicko2) SetDeviation(deviation float64) {
	g.deviation = deviation / 173.7178
}

// Get the current rating volatility.
func (g *Glicko2) Volatility() float64 {
	return g.volatility
}

// Set rating volatility.
func (g *Glicko2) SetVolatility(volatility float64) {
	g.volatility = volatility
}

// helper to make a copy of a Glicko2 struct
func (g *Glicko2) duplicate() *Glicko2 {
	c := *g
	return &c
}

// Clear all results previously added via add_result(), add_win(), add_loss(),
// and/or add_draw().  This method is called automatically whenever update()
// is called.
func (g *Glicko2) ClearResults() {
	g.wins = nil
	g.losses = nil
	g.draws = nil
}

// Add a win result to this rating.  Note that no calculation is performed until
// Update() is called.
func (g *Glicko2) AddWin(loser *Glicko2) {
	g.wins = append(g.wins, loser.duplicate())
}

// Add a loss result to this rating.  Note that no calculation is performed until
// Update() is called.
func (g *Glicko2) AddLoss(winner *Glicko2) {
	g.losses = append(g.losses, winner.duplicate())
}

// Add a draw result to this rating.  Note that no calculation is performed until
// Update() is called.
func (g *Glicko2) AddDraw(drawer *Glicko2) {
	g.draws = append(g.draws, drawer.duplicate())
}

// Print a Glicko2 struct
func (g *Glicko2) Print() {
	fmt.Printf("    rating: %v\n", g.Rating())
	fmt.Printf(" deviation: %v\n", g.Deviation())
	fmt.Printf("volatility: %v\n", g.Volatility())
	for _, win := range g.wins {
		fmt.Printf(" *beat\n")
		fmt.Printf("      rating: %v\n", win.Rating())
		fmt.Printf("   deviation: %v\n", win.Deviation())
		fmt.Printf("  volatility: %v\n", win.Volatility())
	}
}

// util func 'g'
func calcG(deviation float64) float64 {
	return 1.0 / (math.Sqrt(1.0 + 3.0*(deviation*deviation)/(math.Pi*math.Pi)))
}

// util func 'E'
func calcE(rating float64, rating_opponent float64, deviation_opponent float64) float64 {
	return 1.0 / (1.0 + math.Exp(-calcG(deviation_opponent)*(rating-rating_opponent)))
}

// Update rating based on current results list, and clear results.
func (g *Glicko2) Update() {

	// merge wins, losses, draws slices for convenience
	results := append(append(g.wins, g.losses...), g.draws...)

	// Note that if a player does not compete during the rating period, then
	// only Step 6 applies.
	if len(results) == 0 {
		g.deviation = math.Sqrt((g.deviation * g.deviation) + (g.volatility * g.volatility))
		return
	}

	// Step 1. Determine a rating and RD for each player at the onset of the
	// rating period. The system constant which constrains the change in
	// volatility over time, needs to be set prior to application of the system.
	// Reasonable choices are between 0.3 and 1.2, though the system should be
	// tested to decide which value results in greatest predictive accuracy
	// ... (ratings already stored in instance)

	// Step 2. For each player, convert the ratings and RD's onto the Glicko-2
	// scale.
	// ... (ratings already stored in G2 format)

	// Step 3.  Compute the quantity v. This is the estimated variance of the
	// team's/player's rating based only on game outcomes.
	variance := 0.0
	for _, r := range results {
		g_i := calcG(r.deviation)
		e_i := calcE(g.rating, r.rating, r.deviation)
		variance += (g_i * g_i) * e_i * (1.0 - e_i)
	}
	variance = 1.0 / variance

	// Step 4. Compute the quantity 'delta', the estimated improvement in rating
	// by comparing the pre-period rating to the performance rating based only
	// on game outcomes.
	delta := 0.0
	for _, r := range g.wins {
		delta += calcG(r.deviation) * (1.0 - calcE(g.rating, r.rating, r.deviation))
	}
	for _, r := range g.losses {
		delta += calcG(r.deviation) * (0.0 - calcE(g.rating, r.rating, r.deviation))
	}
	for _, r := range g.draws {
		delta += calcG(r.deviation) * (0.5 - calcE(g.rating, r.rating, r.deviation))
	}
	delta *= variance

	// Step 5. Determine the new value of the volatility.
	new_volatility := 0.0
	a := math.Log((g.volatility * g.volatility))
	x := 0.0
	x_new := a
	for math.Abs(x-x_new) > 0.0000001 {
		x = x_new
		d := (g.deviation * g.deviation) + variance + math.Exp(x)
		h1 := -(x-a)/(kDVOL*kDVOL) - 0.5*math.Exp(x)/d + 0.5*math.Exp(x)*(delta/d)*(delta/d)
		h2 := -1.0/(kDVOL*kDVOL) - 0.5*math.Exp(x)*((g.deviation*g.deviation)+variance)/(d*d) + 0.5*(delta*delta)*math.Exp(x)*((g.deviation*g.deviation)+variance-math.Exp(x))/(d*d*d)
		x_new = x - h1/h2
	}
	new_volatility = math.Exp(x_new / 2.0)

	// Step 6. Update the rating deviation to the new pre-rating period value.
	pre_deviation := math.Sqrt((g.deviation * g.deviation) + (new_volatility * new_volatility))

	// Step 7. Update the rating and RD to the new values.
	new_deviation := 1.0 / (math.Sqrt(1.0/(pre_deviation*pre_deviation) + 1.0/variance))
	new_rating := 0.0
	for _, r := range g.wins {
		new_rating += calcG(r.deviation) * (1.0 - calcE(g.rating, r.rating, r.deviation))
	}
	for _, r := range g.losses {
		new_rating += calcG(r.deviation) * (0.0 - calcE(g.rating, r.rating, r.deviation))
	}
	for _, r := range g.draws {
		new_rating += calcG(r.deviation) * (0.5 - calcE(g.rating, r.rating, r.deviation))
	}
	new_rating = new_rating * (new_deviation * new_deviation)
	new_rating += g.rating

	// Step 8. Convert ratings and RD's back to original scale.
	g.deviation = new_deviation
	g.volatility = new_volatility
	g.rating = new_rating

	// wipe our result lists
	g.ClearResults()
}
