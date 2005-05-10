#!/usr/bin/env ruby

require 'glicko2'
require 'test/unit'

class TestGlicko2 < Test::Unit::TestCase

	def test_simple
		a = Glicko2.new(1500.0, 200.0, 0.06)
		b = Glicko2.new(1400.0,  30.0, 0.06)
		c = Glicko2.new(1550.0, 100.0, 0.06)
		d = Glicko2.new(1700.0, 300.0, 0.06)
		
		a.add_win(b)
		a.add_loss(c)
		a.add_result(d,0.0)
		
		assert_equal(1500.0, a.rating)
		assert_equal(200.0, a.deviation)
		
		a.update()
		
		assert_in_delta(1464.05,a.rating,0.01)
		assert_in_delta(151.516,a.deviation,0.01)
	end
end

