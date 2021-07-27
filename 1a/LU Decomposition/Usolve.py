
# we write a function that solves Ux = y for x where U is upper triangular and y is a vector
def Usolve(U, y):

    # we get the sizes of U and y
    URows = len(U)
    yRows = len(y)
 
    # we check that U and y ahve appropriate sizes
    if URows != len(U[0]) or yRows != URows:
        raise Exception("The size of U or y is not appropriate")
    
    # we initialize x to y
    x = [0] * yRows
    for i in range(yRows):
        x[i] = y[i]

    # we loop backwards over the rows of U
    for k in range(URows-1, -1, -1):

        # we check that we don't divide by zero
        if U[k][k] == 0:
            raise Exception("There are zeros on the diagonal of U")

        # we modify x accordingly
        for j in range(k+1, URows):
            x[k] -= U[k][j] * x[j];
        x[k] /= U[k][k];

    # we return x
    return x
