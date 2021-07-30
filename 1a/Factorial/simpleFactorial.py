
# we write a function that computes x factorial iteratively
def simpleFactorial(x):

	# we check that x is positive
	if x < 0:
		raise Exception("factorials of non-negative numbers only")

	# we initialize y to 1
	y = 1

	# we loop through all integers from 1 to x and multiply them onto y
	for k in range(1, x+1):
		y *= k

	# we return y
 	return y