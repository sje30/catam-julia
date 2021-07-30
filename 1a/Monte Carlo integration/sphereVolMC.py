
from random import random

# we write a function that uses Monte Carlo to estimate the volume of the unit hypersphere in d dimensions using n trials
def sphereVolMC(d, n):

	# we initialize the counter variable
	count = 0.0

	# we perform the Monte Carlo trial n times
	for i in range(n):

		# we generate a vector with d random floats from [0,1]
		x = [random() for k in range(d)]

		# we calculat the squared norm of x
		norm2 = 0
		for k in x:
			norm2 += k*k

		# if x is inside the hypersphere we increment the count
		if norm2 < 1:
			count += 1

	# we calculate the estimated volume given by
	vol = 2**d * count / n
	
	# we return the estimated volume
	return vol
