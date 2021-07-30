
# we write a function that computes x factorial iteratively
function simpleFactorial(x)

	# we check that x is positive
	if x < 0
		error("factorials of non-negative numbers only")
	end

	# we initialize y to 1
	y = 1

	# we loop through all integers from 1 to x and multiply them onto y
	for k = 1:x
		y *= k
	end

	# we return y
 	return y
end