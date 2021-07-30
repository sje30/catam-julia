
from findLargestInCol import *
from swapRowsV2 import *

# we write another function that composes A into A = P^{-1}LU where P is stored as a vector and swapRows is more efficient
def PALUdecompV2(A):

    # we get the size of A
    n = len(A)

    # we check that A is indeed a square matrix
    if n != len(A[0]):
        raise Exception("Input must be a square matrix")

    # we initialize L and U to zero, P to {0,1, ..., n-1}
    L = [[0] * n for i in range(n)]
    U = [[0] * n for i in range(n)]
    P = range(n)

    # we make a copy of A to work with
    B = [[0] * n for i in range(n)]
    for i in range(n):
        for j in range(n):
            B[i][j] = A[i][j]

    for k in range(n):

        # we find the pivot
        maxk = findLargestInCol(B, k)
        if maxk != k:
            swapRowsV2(B, maxk, k)
            swapRowsV2(L, maxk, k)

            # we swap two elements of P instead of two rows
            temp = P[maxk]
            P[maxk] = P[k]
            P[k] = temp
        
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
