
# we write a function that returns a root of func in the
# interval [low, high] with relative error tol, assuming such a root exists
function binarySearch(func, low, high, tol)

	# we repeat until the tolorance condition is met
	while abs(high - low)/2 > tol * abs(high + low)/2

		# we define mid as the midpoint of the interval [low, high]
		mid = (low + high)/2

		# we check if the value of func at high and mid have the same sign
		if func(high) * func(mid) > 0

			# and reassign [low, high] accordingly
		    high = mid
		else
		    low = mid
		end
	end

	# we return the avarage of low and high as the approximate root
	return (low + high)/2;
end
