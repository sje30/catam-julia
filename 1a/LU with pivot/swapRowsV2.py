
# we write a more efficient function that swaps rows u and v of some matrix A
def swapRowsV2(A, u, v):

	# we directly swap rows u and v of A without copying
	for i, val in enumerate(A[u]):
		A[u][i] = A[v][i]
		A[v][i] = val