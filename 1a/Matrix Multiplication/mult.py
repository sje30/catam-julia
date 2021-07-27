
# we write a function that caculates the product of two matrices A and B
def mult(A,B):

	# we find the sizes of A and B
	aRows, aCols = len(A), len(A[0])
	bRows, bCols = len(B), len(B[0])

	# we check if the matrix sizes are consistent with multiplication
	if aCols != bRows:
		raise Exception("matrix sizes don't agree")

	# we initialize C to a zero matrix of the appropriate size
	C = [[0] * bCols for i in range(aRows)]

	# we loop over all pairs of rows and columns
	for i in range(aRows):
		for j in range(bCols):
			# and for each pair we store their dot pruduct in C
			for k in range(aCols):
				C[i][j] += A[i][k] * B[k][j];

	# we return C as the answer
	return C
