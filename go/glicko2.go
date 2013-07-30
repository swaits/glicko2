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

const dvolatility float64 = 0.3

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

// util func
func calcG(deviation float64) float64 {
	return 1.0 / (math.Sqrt(1.0 + 3.0*(deviation*deviation)/(math.Pi*math.Pi)))
}

// util func
func calcE(rating float64, rating_opponent float64, deviation_opponent float64) float64 {
	return 1.0 / (1.0 + math.Exp(-calcG(deviation_opponent)*(rating-rating_opponent)))
}

// Update rating based on current results list, and clear results.
func (g *Glicko2) Update() {

	// merge wins, losses, draws slices for convenience
	results := append(append(g.wins, g.losses...), g.draws...)

	// bail if no opponents set
	if len(results) == 0 {
		g.deviation = math.Sqrt((g.deviation * g.deviation) + (g.volatility * g.volatility))
		return
	}

	// compute variance
	variance := 0.0
	for _, r := range results {
		g_i := calcG(r.deviation)
		e_i := calcE(g.rating, r.rating, r.deviation)
		variance += (g_i * g_i) * e_i * (1.0 - e_i)
	}
	variance = 1.0 / variance

	// compute delta
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

	// determine new volatility
	new_volatility := 0.0
	a := math.Log((g.volatility * g.volatility))
	x := 0.0
	x_new := a
	for math.Abs(x-x_new) > 0.0000001 {
		x = x_new
		d := (g.deviation * g.deviation) + variance + math.Exp(x)
		h1 := -(x-a)/(dvolatility*dvolatility) - 0.5*math.Exp(x)/d + 0.5*math.Exp(x)*(delta/d)*(delta/d)
		h2 := -1.0/(dvolatility*dvolatility) - 0.5*math.Exp(x)*((g.deviation*g.deviation)+variance)/(d*d) + 0.5*(delta*delta)*math.Exp(x)*((g.deviation*g.deviation)+variance-math.Exp(x))/(d*d*d)
		x_new = x - h1/h2
	}
	new_volatility = math.Exp(x_new / 2.0)

	// update the rating deviation to the new pre-rating period value
	pre_deviation := math.Sqrt((g.deviation * g.deviation) + (new_volatility * new_volatility))

	// update the rating and deviation
	new_deviation := 1.0 / (math.Sqrt(1.0/(pre_deviation * pre_deviation) + 1.0/variance))
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

	// wipe our result lists
	g.ClearResults()

	// copy new values
	g.deviation = new_deviation
	g.volatility = new_volatility
	g.rating = new_rating
}
