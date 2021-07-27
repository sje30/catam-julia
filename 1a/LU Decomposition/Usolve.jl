
# we write a function that solves Ux = y for x where U is upper triangular and y is a vector
function Usolve(U, y)

    # we get the sizes of U and y
    URows, UCols = size(U)
    yRows = size(y)[1]
 
    # we check that U and y ahve appropriate sizes
    if URows != UCols || yRows != URows
        error("The size of U or y is not appropriate")
    end
    
    # we initialize x to y
    x = y;

    # we loop backwards over the rows of U
    for k = URows:-1:1

        # we check that we don't divide by zero
        if U[k,k] == 0
            error("There are zeros on the diagonal of U")
        end

        # we modify x accordingly
        for j = k+1:URows
            x[k] -= U[k,j] * x[j];
        end
        x[k] /= U[k,k];
    end

    # we return x
    return x
end
