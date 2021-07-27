
# we write a function that solves Ly = b for y where L is lower triangular and b is a vector
def Lsolve(L, b):

    # we get the sizes of L and b
    LRows = len(L)
    bRows = len(b)
 
    # we check that L and b ahve appropriate sizes
    if LRows != len(L[0]) or bRows != LRows:
        raise Exception("The size of L or b is not appropriate")

    # we initialize y to b
    y = [0] * bRows
    for i in range(bRows):
        y[i] = b[i]

    # we loop over the rows of L
    for k in range(LRows):

        # we check that we dont divide by zero
        if L[k][k] == 0:
            raise Exception("There are zeros on the diagonal of L")

        # we modify y accordingly
        for j in range(k):
            y[k] -= L[k][j] * y[j];
        y[k] /= L[k][k];

    # we return y
    return y
