
# we write a function that swaps rows u and v of some matrix A
function swapRows(A, u, v)

	# we make a copy of A to work with
	B = copy(A)

	# we reassign rows u and v of B
	B[v ,:] = A[u, :]
	B[u ,:] = A[v, :]

	# we return B
	return B
end
