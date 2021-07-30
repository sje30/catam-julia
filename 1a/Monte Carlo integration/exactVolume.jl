
# we need to install a special package in order to use the gamma function
using Pkg
Pkg.add("SpecialFunctions")
using SpecialFunctions

# we write a function that returns the exact volume of a hypersphere in d dimensions
function exactVol(d)
    vol = pi^(d/2) / gamma(1 + d/2)
    return vol
end
