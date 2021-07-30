
# we write a function that returns the row index of the (absolutely) largest element in column k of the matrix A
function findLargestInCol(A, k)

	# we get column k
	col = A[:,k]

	# we take elementwise absolute value
	absCol = broadcast(abs, col)

	# we get the index of the largest element
	index = argmax(absCol)

	# we return index
	return index
end
