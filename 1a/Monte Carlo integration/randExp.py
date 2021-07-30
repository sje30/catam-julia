
from random import random
from math import exp, log

# we write a function that returns a random vector from [0,1]^d with exponential density
def randExp(d, lam):

	# we generate a uniformly random vector
	x = [random() for i in range(d)]

	# we transform (elementwise) to random numbers in [exp(-lambda),1]
	for i in range(d):
		x[i] = exp(-lam) + (1-exp(-lam))*x[i]
	
	# we now get numbers with exponential density
	for i in range(d):
		x[i] = -log(x[i]) / lam
	return x
