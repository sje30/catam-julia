
from findLargestInCol import *
from swapRows import *

# we write a function that decomposes a square matrix A as A = P^{-1}LU
def PALUdecomp(A):

    # we get the size of A
    n = len(A)

    # we check that A is indeed a square matrix
    if n != len(A[0]):
        raise Exception("Input must be a square matrix")

    # we initialize P to the indentity and L and U to zero
    P = [[0] * n for i in range(n)]
    for i in range(n):
        P[i][i] = 1
    L = [[0] * n for i in range(n)]
    U = [[0] * n for i in range(n)]

    # we make a copy of A to work with
    B = [[0] * n for i in range(n)]
    for i in range(n):
        for j in range(n):
            B[i][j] = A[i][j]

    for k in range(n):

        # we find the pivot
        maxk = findLargestInCol(B, k)
        if maxk != k:
            B = swapRows(B, maxk, k)
            L = swapRows(L, maxk, k)
            P = swapRows(P, maxk, k)
        
        # we proceed with the normal LU decomposition algorithm
        for j in range(k, n):
            U[k][j] = B[k][j]

        # we check that we don't divide by zero
        if U[k][k] == 0:
            raise Exception("** A^(k-1)_{k,k} == 0 in PALU decomp")

        for i in range(k, n):
           L[i][k] = B[i][k] / U[k][k]

        for i in range(k, n):
            for j in range(k, n):
                B[i][j] -= L[i][k] * U[k][j];

    # we return P, L and U
    return P, L, U
