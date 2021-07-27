
# we write a function that applies Euler's method to solve y' = f(x,y)
# in the interval [x0, x1] with y(x0) = y0 with n steps
def eulerSolve(f, x0, y0, x1, n):

    # we compute the step size h
    h = (x1 - x0)/n

    # we initialize the outpur vectors
    x = [0] * (n+1)
    y = [0] * (n+1)
    x[0] = x0
    y[0] = y0
    
    # we interate over the interval in n steps of length h
    for i in range(n):
    	# and calculate x and y accordingly
        y[i+1] = y[i] + h * f(x[i], y[i])
        x[i+1] = x[i] + h

    # we return the data points of the calculated function y(x)
    return (x, y)