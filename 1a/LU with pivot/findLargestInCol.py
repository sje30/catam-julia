
# we write a function that returns the row index of the (absolutely) largest element in column k of the matrix A
def findLargestInCol(A, k):

	# we initialize the index and the current maximum
	index = 0
	curMax = abs(A[0][k])

	# we loop through the rows of A keeping track of the largest value at position k we have seen so far
	for i, row in enumerate(A):
		val = abs(row[k])
		if val > curMax:
			curMax = val
			index = i

	# we return the index
	return index
