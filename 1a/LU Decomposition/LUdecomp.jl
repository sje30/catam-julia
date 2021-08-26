
# we write a function that decomposes a square matrix A as A = LU
# where L is lower triangular and U is upper triangular
function LUdecomp(A)

    # we get the size of A
    n, m = size(A)

    # we check if A is indeed a square matrix
    if n != m
        error("Input must be a square matrix")
    end

    # we initialize the output matrices
    L = zeros(n, n)
    U = zeros(n, n)

    # we make a copy of A in order not to modify the original
    B = copy(A)

    for k = 1:n

        # we set the entries of the kth row of U
        for j = k:n
            U[k,j] = B[k,j]
        end

        # we check that we don't divide by zero
        if U[k,k] == 0
            error("** A^(k-1)_{k,k} == 0 in LU decomp")
        end

        # we set the entries of the kth column of L
        for i = k:n
           L[i,k] = B[i,k] / U[k,k]
        end

        # we modify A for the next iteration
        for i = k:n
            for j = k:n
                B[i,j] -= L[i,k] * U[k,j]
            end
        end
    end

    # we return L and U
    return (L, U)
end