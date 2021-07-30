
# we write a function that returns a random vector from [0,1]^d with exponential density
function randExp(d, lam)

	# we generate a uniformly random vector
	y = rand(d)

	# we transform (elementwise) to random numbers in [exp(-lambda),1]
	y = exp(-lam) .+ (1-exp(-lam))*y
	
	# we now get numbers with exponential density
	x = -log.(y)/lam
	return x
end
