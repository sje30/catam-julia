
include("findLargestInCol.jl")
include("swapRowsV2.jl")

# we write another function that composes A into A = P^{-1}LU where P is stored as a vector and swapRows is more efficient
function PALUdecompV2(A)

    # we get the size of A
    m, n = size(A)

    # we check that A is indeed a square matrix
    if m != n
        error("Input must be a square matrix")
    end

    # we initialize L and U to zero, P to {1,2, ..., n}
    L = zeros(n, n)
    U = zeros(n, n)
    p = collect(1:n)

    # we make a copy of A to work with
    B = copy(A)

    for k = 1:n

        # we find the pivot
        maxk = findLargestInCol(B, k)
        if maxk != k
            swapRowsV2!(B, maxk, k)
            swapRowsV2!(L, maxk, k)
            
            # we swap two elements of P instead of two rows
            temp = p[maxk]
            p[maxk] = p[k]
            p[k] = temp
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

    P = zeros(n,n)
    for i = 1:n
        P[i,p[i]] = 1
    end

    # we return P, L and U
    return P, L, U
end
