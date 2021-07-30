
# we write a function that computes x factorial recursively
function recursiveFactorial(x)

	# we check that x is positive
	if x < 0
		error("factorials of non-negative numbers only")
	end

	# we check if x is either 0 or 1
	if x <= 1

		# we return the asnwer 1
		return 1
	else

		# we recurse
		return x * recursiveFactorial(x - 1)
	end
end
