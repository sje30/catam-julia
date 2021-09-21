
# we write a more efficient function that swaps rows u and v of some matrix A
function swapRowsV2!(A, u, v)

	# we directly swap rows u and v of A without copying
	temp = A[u, :]
	A[u, :] = A[v, :]
	A[v, :] = temp
end
