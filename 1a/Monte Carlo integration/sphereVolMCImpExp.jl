
include("randExp.jl")

# we write an improoved function that uses Monte Carlo with exponential importance sampling
# to estimate the volume of the unit hypersphere in d dimensions.
# We choose our points x with independent Cartesian components and prob density exp(-lam.xi) / [ lam*((1-exp(-lam)) ].
# We achieve this by taking xi = (1/lam) log (1/y) where y is chosen uniformly in (exp(-lam),1)
function sphereVolMCImpExp(d, n, lam)
	count = 0.0
	for i = 1:n

		# we generate x according to our distribution
		x = randExp(d, lam)

		# we calculate the squared norm of x and check if x is inside the hypersphere
		norm2 = x' * x
		if norm2 < 1

			# we compute the density at x
			rho = 1
			for i = 1:d

				# note that y(i) = exp(-lam * x(i))
				rho *= exp(-lam*x[i]) * lam / (1-exp(-lam))
			end
			count += 1/rho
		end
	end
	vol =  2^d * count / n
	return vol
end