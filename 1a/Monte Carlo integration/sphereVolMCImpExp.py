
from randExp import *

# we write an improoved function that uses Monte Carlo with exponential importance sampling
# to estimate the volume of the unit hypersphere in d dimensions.
# We choose our points x with independent Cartesian components and prob density exp(-lam.xi) / [ lam*((1-exp(-lam)) ].
# We achieve this by taking xi = (1/lam) log (1/y) where y is chosen uniformly in (exp(-lam),1)
def sphereVolMCImpExp(d, n, lam):
	count = 0.0;
	for i in range(n):

		# we generate x according to our distribution
		x = randExp(d, lam)

		# we calculate the squared norm of x and check if x is inside the hypersphere
		norm2 = 0
		for k in x:
			norm2 += k*k

		if norm2 < 1:

			# we compute the density at x
			rho = 1
			for k in x:

				# note that y(i) = exp(-lam * x(i))
				rho *= exp(-lam*k) * lam / (1-exp(-lam))
			count += 1/rho

	vol =  2**d * count / n
	return vol