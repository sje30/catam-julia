
# we write a function that computes x factorial recursively
def recursiveFactorial(x):

	# we check that x is positive
	if x < 0:
		raise exception("factorials of non-negative numbers only")

	# we check if x is either 0 or 1
	if x <= 1:

		# we return the asnwer 1
		return 1
	else:

		# we recurse
		return x * recursiveFactorial(x - 1)