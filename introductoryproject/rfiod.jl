module RFIOD
export binarysearch, fixedpointiteration, staircasediagram

using Plots

"""
    binarysearch(f::Function, a::Real, b::Real, [ε::Real])

Use the binary search algorithm to find a root of `f` between `a` and `b` with maximum trucation error `ε`.

Also returns the number of iterations that the algorithm takes.

# Examples

```julia-repl
julia> binarysearch(sin,3,4)
(3.141590118408203, 17)

julia> abs(ans[1] - π) < 5e-6
true
```
"""
function binarysearch(f::Function, a::Real, b::Real, ε::Real = 5e-6)

    # Checks that the initial interval is valid
    fa, fb = f(a), f(b)
    iszero(fa) && return (a,0)
    iszero(fb) && return (b,0)
    fa * fb < 0 || error("cannot find a root, function must take opposite signs on each end of the interval")

    # Iteratively finds the halfway point of the interval, then keeps the half where the sign of f changes
    N = 0
    while abs(b-a) > 2ε
        N += 1
        m = (a+b)/2
        fm = f(m)
        iszero(fm) && return (m,N)
        (a, b, fa, fb) = ( fa * fm > 0 ? (m, b, fm, fb) : (a, m, fa, fm) )
    end
    # Returns the midpoint of the interval, which is within ε of the root
    return ((a+b)/2,N)

end

"""
    fixedpointiteration(f::Function, x₀::Real, Nₘₐₓ::Int, [ε::Real])

Use the fixed point iteration algorithm to converge on a fixed point of `f`, with starting value `x₀`.

Terminate if consecutive iterations differ by less than `ε`, or after `Nₘₐₓ` iterations.

Returns the sequence resulting from the iteration.

# Examples

```julia-repl
julia> xs = fixedpointiteration(cos, 0, 100)
92-element Vector{Float64}:
 0.0
 1.0
 [...]
 0.7390851332151607

julia> cos(xs[end])
0.7390851332151607
```
"""
function fixedpointiteration(f::Function, x₀::Real, Nₘₐₓ::Int, ε::Real = eps(Float64))

    # Sets up the initial values for the algorithm
    n = 1
    xₙ₋₁ = convert(Float64,x₀)
    xₙ = f(xₙ₋₁)
    xvalues = [xₙ₋₁, xₙ]

    # Iteratively advances the algorithm by evaluating f at the previous result and storing it
    while abs(xₙ₋₁ - xₙ) ≥ ε && n < Nₘₐₓ
        n += 1
        xₙ₋₁, xₙ = xₙ, f(xₙ)
        push!(xvalues,xₙ)
    end
    # Returns the sequence resulting from the algorithm
    return xvalues

end

"""
staircasediagram(f::Function, xvalues::Vector{Float64})

Create a staircase/cobweb diagram from `xvalues`, the results of the fixed point iteration algorithm on `f`.

# Examples

```julia-repl
julia> staircasediagram(cos, fixedpointiteration(cos, 0, 100))
```
"""
function staircasediagram(f::Function, xvalues::Vector{Float64})

    # Finds the scale at which to draw the diagram
    minx, maxx = min(xvalues...), max(xvalues...)
    δ = (maxx - minx)/100
    xticks = (minx - 10δ):δ:(maxx + 10δ)

    # Plots y = x and y = f(x), then adds in a marker for the starting point and the lines given by the sequence
    p = plot([x -> x, f], xticks, legend = false)
    scatter!(p, (xvalues[1], xvalues[1]), markercolor = :black)
    for n = 1:(length(xvalues)-1)
        plot!(p, [xvalues[n], xvalues[n], xvalues[n+1]],
            [xvalues[n], xvalues[n+1], xvalues[n+1]], linecolor = :black)
    end
    # Returns the plot
    return p
    
end

end