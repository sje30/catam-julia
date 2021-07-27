
# we write an improved version of binarySearch that evaluates func fewer times
# and checks if there is definitely a root in the initial interval
def binarySearchV2(func, low, high, tol):

  # we now also store the values of func at low and high
  f_low = func(low)
  f_high = func(high)

  # we check if the initial interval definitely contains a root
  if f_low * f_high > 0:
      raise Exception("func(low) and func(high) must have different sign")
  
  # the while loop is similar to before
  while abs(high - low)/2 > tol * abs(low + high)/2:
    mid = (low + high)/2

    # we only have one evaluation of func per loop
    f_mid = func(mid)
    
    if f_high * f_mid > 0:
        high = mid
        f_high = f_mid
        # in this case f_low stays the same
    else:
        low = mid
        f_low = f_mid
        # in this case f_high stays the same
 
  return (low + high)/2
