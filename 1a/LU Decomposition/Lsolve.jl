
# we write a function that solves Ly = b for y where L is lower triangular and b is a vector
function Lsolve(L, b)

    # we get the sizes of L and b
    LRows, LCols = size(L)
    bRows = size(b)[1]
 
    # we check that L and b ahve appropriate sizes
    if LRows != LCols || bRows != LRows
        error("The size of L or b is not appropriate")
    end

    # we initialize y to b
    y = b;

    # we loop over the rows of L
    for k = 1:LRows

        # we check that we dont divide by zero
        if L[k,k] == 0
            error("There are zeros on the diagonal of L")
        end

        # we modify y accordingly
        for j = 1:k-1
            y[k] -= L[k,j] * y[j];
        end
        y[k] /= L[k,k];
    end

    # we return y
    return y
end
