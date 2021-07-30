
from scipy.special import gamma
from math import pi

# we write a function that returns the exact volume of a hypersphere in d dimensions
def exactVol(d):
    vol = pi**(d/2) / gamma(1 + d/2)
    return vol
