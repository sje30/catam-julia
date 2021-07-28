
# we write a function that caculates the product of two matrices A and B
function mult(A,B)

	# we find the sizes of A and B
	aRows, aCols = size(A)
	bRows, bCols = size(B)

	# we check if the matrix sizes are consistent with multiplication
	if aCols != bRows
		error("matrix sizes don't agree")
	end

	# we initialize C to a zero matrix of the appropriate size
	C = zeros(aRows, bCols)

	# we loop over all pairs of rows and columns
	for i = 1:aRows
		for j = 1:bCols
			# and for each pair we store their dot product in C
			for k = 1:aCols
				C[i,j] += A[i,k] * B[k,j]
			end
		end
	end

	# we return C as the answer
	return C
end
