
# we write a function that applies Euler's method to solve y' = f(x,y)
# in the interval [x0, x1] with y(x0) = y0 with n steps
function eulerSolve(f, x0, y0, x1, n)

    # we compute the step size h
    h = (x1 - x0)/n

    # we initialize the outpur vectors
    x = zeros(n+1)
    y = zeros(n+1)
    x[1] = x0
    y[1] = y0
    
    # we interate over the interval in n steps of length h
    for i = 1:n
    	# and calculate x and y accordingly
        y[i+1] = y[i] + h * f(x[i], y[i])
        x[i+1] = x[i] + h
    end

    # we return the data points of the calculated function y(x)
    return (x, y)
end