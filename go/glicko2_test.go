package glicko2

import (
	"testing"
	"math"
)

func inRange(want float64, have float64, delta float64) bool {
	return math.Abs(want-have) <= delta
}

func TestGlicko2(t *testing.T) {
	a := NewGlicko2(1500.0, 200.0, 0.06)
	b := NewGlicko2(1400.0,  30.0, 0.06)
	c := NewGlicko2(1550.0, 100.0, 0.06)
	d := NewGlicko2(1700.0, 300.0, 0.06)

	a.AddWin(b)
	a.AddLoss(c)
	a.AddLoss(d)

	if a.Rating() != 1500.0 {
		t.Error()
	}
	if a.Deviation() != 200.0 {
		t.Error()
	}

	a.Update()

	if !inRange(a.Rating(),1464.05,0.01) {
		t.Error()
	}
	if !inRange(a.Deviation(),151.516,0.01) {
		t.Error()
	}

	a.Update()

	if !inRange(a.Rating(),1464.05,0.01) {
		t.Error()
	}
	if !inRange(a.Deviation(),151.875,0.01) {
		t.Error()
	}

}
