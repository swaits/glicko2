#include "glicko2.h"

#include <cstdio>

int main()
{
	// Glicko-2 Example
	// calculation from http://www.glicko.com/glicko2.doc/example.html

	Glicko2 A(1500.0, 200.0, 0.06);
	Glicko2 B(1400.0,  30.0, 0.06);
	Glicko2 C(1550.0, 100.0, 0.06);
	Glicko2 D(1700.0, 300.0, 0.06);

	A.AddWin(B);
	A.AddLoss(C);
	A.AddResult(D,Glicko2::LOSS); // alternative way to add a result

	A.Update();

	printf("rating = %f, RD = %f\n", A.GetRating(), A.GetDeviation());

	return 0;
}

