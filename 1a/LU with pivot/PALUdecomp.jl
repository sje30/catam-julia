
include("findLargestInCol.jl")
include("swapRows.jl")

# we write a function that decomposes a square matrix A as A = P^{-1}LU
function PALUdecomp(A)

    # we get the size of A
    m, n = size(A)

    # we check that A is indeed a square matrix
    if m != n
        error("Input must be a square matrix")
    end

    # we initialize P to the indentity and L and U to zero
    P = one(A)
    L = zeros(n, n)
    U = zeros(n, n)

    # we make a copy of A to work with
    B = copy(A)

    for k = 1:n

        # we find the pivot
        maxk = findLargestInCol(B, k)
        if maxk != k
            B = swapRows(B, maxk, k)
            L = swapRows(L, maxk, k)
            P = swapRows(P, maxk, k)
        end
        
        # we proceed with the normal LU decomposition algorithm
        for j = k:n
            U[k,j] = B[k,j]
        end

        # we check that we don't divide by zero
        if U[k,k] == 0
            error("** A^(k-1)_{k,k} == 0 in PALU decomp")
        end

        for i = k:n
           L[i,k] = B[i,k] / U[k,k]
        end

        for i = k:n
            for j = k:n
                B[i,j] -= L[i,k] * U[k,j];
            end
        end
    end

    # we return P, L and U
    return P, L, U
end
