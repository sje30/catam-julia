
# we write a function that uses Monte Carlo to estimate the volume of the unit hypersphere in d dimensions using n trials
function sphereVolMC(d, n)

	# we initialize the counter variable
	count = 0

	# we perform the Monte Carlo trial n times
	for i = 1:n

		# we generate a vector with d random floats from [0,1]
		x = rand(d)

		# we calculate the squared norm of x
		norm2 = x' * x

		# if x is inside the hypersphere we increment the count
		if norm2 < 1
			count += 1
		end
	end

	# we calculate the estimated volume given by
	vol = 2^d * count / n
	
	# we return the estimated volume
	return vol
end
