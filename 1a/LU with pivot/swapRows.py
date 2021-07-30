
# we write a function that swaps rows u and v of some matrix A
def swapRows(A, u, v):

	# we get the size of A
 	n, m = len(A), len(A[0])

 	# we initialize B to zero
 	B = [[0] * m for i in range(n)]

 	# we copy all entries from A to B but swap rows u and v
 	for i in range(n):
 		k = i
		if k == u:
			k = v
		elif k == v:
			k = u
		for j in range(m):
			B[i][j] = A[k][j]

	# we return B
	return B
