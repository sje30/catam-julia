
# we write a function that decomposes a square matrix A as A = LU
# where L is lower triangular and U is upper triangular
def LUdecomp(A):

    # we get the size of A
    n = len(A)

    # we check if A is indeed a square matrix
    if n != len(A[0]):
        raise Exception("Input must be a square matrix")

    # we initialize the output matrices
    L = [[0] * n for i in range(n)]
    U = [[0] * n for i in range(n)]

    # we make a copy of A in order not to modify the original
    B = [[0] * n for i in range(n)]
    for i in range(n):
        for j in range(n):
            B[i][j] = A[i][j]

    for k in range(n):

        # we set the entries of the kth row of U
        for j in range(k, n):
            U[k][j] = B[k][j]

        # we check that we don't divide by zero
        if U[k][k] == 0:
            raise Exception("** A^(k-1)_{k,k} == 0 in LU decomp")

        # we set the entries of the kth column of L
        for i in range(k, n):
           L[i][k] = B[i][k] / U[k][k]

        # we modify A for the next iteration
        for i in range(k, n):
            for j in range(k, n):
                B[i][j] -= L[i][k] * U[k][j]

    # we return L and U
    return (L, U)
