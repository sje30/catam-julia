using Plots

"""
    randomwalks1d(m,n,stepfunction)

Simulate `m` random walks of length `n`, and plot the positions against time.

Each random step is determined by `stepfunction`.

# Example
```julia-repl
julia> randomwalks1d(5, 100, m -> rand([-1,1],m))
```
"""
function randomwalks1d(m,n,stepfunction)
	walks = zeros(m,n+1)
	for step ∈ 1:n
		walks[:,step+1] = walks[:,step] + stepfunction(m)
	end
	
	return plot(
		0:n,
		[walks[walk,:] for walk ∈ 1:m],
		legend = false
	)
end

"""
    randomwalk2d(n)

Simulate a two dimensional simple symmetric random walk of length `n`, and plot the path.

# Example
```julia-repl
julia> randomwalk2d(100)
```
"""
function randomwalk2d(n)
	walk = fill((0,0),(n+1))
	for step ∈ 1:n
		walk[step+1] = walk[step] .+ rand([(-1,0),(1,0),(0,-1),(0,1)])
	end
	
	return plot(walk, legend = false, aspect_ratio = :equal)
end

"""
    randomwalk3d(n)

Simulate a three dimensional simple symmetric random walk of length `n`, and plot the path.

# Example
```julia-repl
julia> randomwalk3d(100)
```
"""
function randomwalk3d(n)
	walk = fill((0,0,0),(n+1))
	for step ∈ 1:n
		walk[step+1] = walk[step] .+
			rand([(-1,0,0),(1,0,0),(0,-1,0),(0,1,0),(0,0,-1),(0,0,1)])
	end
	
	return plot(walk, legend = false, aspect_ratio = :equal)
end

"""
    Yₙdistribution(samplesize, n)

Simulate `samplesize` one dimensional simple symmetric random walks of length `n`, and plot a histogram of their endpoints compared to a standard normal distribution.

# Example
```julia-repl
julia> Yₙdistribution(10000, 10000)
```
"""
function Yₙdistribution(samplesize, n)
	Yₙs = [sum(rand([-1,1],n)) for _ ∈ 1:samplesize]
	distribution = stephist(
        Yₙs ./ √n,
        bins = -3:0.2:3,
        norm = :pdf,
        xticks = -3:1:3,
        showaxis = :x,
		legend = false,
        yticks = false
    )
	return plot!(
        distribution,
        x -> exp(-(x^2)/2)/√(2π),
        c = :black
    )
end

"""
    randomdirection(d)

Pick a random direction in one of the positive or negative coordinate axes in `d` dimensions.

# Examples
```julia-repl
julia> randomdirection(3)
3-element Vector{Float64}:
  0.0
  0.0
 -1.0

julia> randomdirection(4)
4-element Vector{Float64}:
 0.0
 1.0
 0.0
 0.0
```
"""
function randomdirection(d)
	x = zeros(d)
	x[rand(1:d)] = rand([1,-1])
	return x
end

"""
    returnprobability(samplesize, nₘₐₓ, d)

Simulate `samplesize` `d` dimensional simple symmetric random walks for up to `nₘₐₓ` steps.

Find when (if ever) they return to the origin, and return a vector representing this.

# Example
```julia-repl
julia> returnprobability(1000, 100, 2)
51-element Vector{Float64}:
 0.0
 0.234
 [...]
 0.585
 0.585
```
"""
function returnprobability(samplesize, nₘₐₓ, d)
    returnfrequencies = zeros(nₘₐₓ ÷ 2)
    for _ ∈ 1:samplesize
        y = zeros(d)
        for halfn ∈ 1:(nₘₐₓ ÷ 2)
            y += randomdirection(d) + randomdirection(d)
            all(y .== 0) && (returnfrequencies[halfn:end] .+= 1; break)
        end
    end
    return vcat(0, returnfrequencies ./ samplesize)
end

"""
    plotreturnprobabilities(samplesize, nₘₐₓ, ds)

Plot a graph of `n` against the approximate proportion of random walks of dimension `d` which return to the origin in at most `n` steps, for `n` up to `nₘₐₓ` and `d` in `ds`.

# Example
```julia-repl
plotreturnprobabilities(1000, 10000, 1:4)
```
"""
function plotreturnprobabilities(samplesize, nₘₐₓ, ds)
	returnprobs = [returnprobability(samplesize, nₘₐₓ, d) for d ∈ ds]
    plot(
        0:2:nₘₐₓ,
        returnprobs,
		label = hcat(
			["d = $d, p ≈ $(returnprobs[i][end])" for (d,i) ∈ enumerate(ds)]...),
        ylims = (0,1)
    )
end

"""
    solvequadratic(a,b,c)

Solve the quadratic `ax² + bx + c = 0`, outputting the two solutions as a tuple.

# Examples
```julia-repl
julia> solvequadratic(1,2,1)
(-1.0 + 0.0im, -1.0 - 0.0im)

julia> solvequadratic(4,5,6)
(-0.625 + 1.0532687216470449im, -0.625 - 1.0532687216470449im) 
```
"""
solvequadratic(a,b,c) = Tuple([(-b + ε * √complex(b^2 - 4a*c))/2a for ε ∈ [1,-1] ])

"""
    laplace◯(x, samplesize, r, ϕ, σ)

Approximate the value of `f(x)` for the harmonic function `f` given for `abs(z) == r` by `f(z) = ϕ(z)`, using `samplesize` Gaussian random walks with steps of standard deviation `σ`.

# Example
```julia-repl
julia> laplace◯(0.2+0.3im, 1000, 1, imag, 0.1)     
0.28950478317730216
```
"""
function laplace◯(x, samplesize, r, ϕ, σ)
    ϕtotal = 0
    for _ ∈ 1:samplesize
        z = x
        while abs(z) < r
            z += σ*complex(randn(2)...)
        end
        # Shrink z towards x
        w = solvequadratic(conj(x) - conj(z), x*conj(z) - conj(x)*z, r^2 * (z - x))[2]
        ϕtotal += ϕ(w)
    end
    return ϕtotal / samplesize
end

"""
    plotlaplace◯(gridsize, samplesize, r, ϕ, σ)

Plot the results of `laplace◯` as evaluated on a square grid with `gridsize` graduations, restricted to the circle of radius `r` centred at the origin.

# Example
```julia-repl
julia> plotlaplace◯(20, 1000, 1, imag, 0.1)
```
"""
function plotlaplace◯(gridsize, samplesize, r, ϕ, σ)
    graduations = range(-r, r, length = gridsize)
    solutionplot = wireframe(
        graduations,
        graduations,
        (x,y) -> hypot(x,y) ≤ r ? laplace◯(x+y*im, samplesize, r, ϕ, σ) : NaN,
        c = :black,
        legend = false
    )

    θs = 0:0.01π:2.01π
    z(θ) = r*exp(im*θ)
    return plot!(solutionplot, r.*cos.(θs), r.*sin.(θs), ϕ.(z.(θs)), c = :black)
end

"""
    rectanglefunction(xₘᵢₙ, xₘₐₓ, yₘᵢₙ, yₘₐₓ, ϕxₘᵢₙ, ϕxₘₐₓ, ϕyₘᵢₙ, ϕyₘₐₓ)

Create a function defined on the border of the rectangle in the complex plane bounded by `xₘᵢₙ`, `xₘₐₓ`, `yₘᵢₙ`, `yₘₐₓ`.

`ϕxₘᵢₙ`, `ϕxₘₐₓ`, `ϕyₘᵢₙ`, `ϕyₘₐₓ` give the value of the function along the corresponding edges. At the corners, `ϕxₘᵢₙ` and `ϕxₘₐₓ` take precedence if there is discontinuity.

# Example
```julia-repl
julia> f = rectanglefunction(-1,1,-1,1,cos,cos,∘(-,cos),∘(-,cos));

julia> f(1+0.8im)
0.6967067093471654

julia> f(-0.4+1im)
-0.9210609940028851
```
"""
function rectanglefunction(xₘᵢₙ, xₘₐₓ, yₘᵢₙ, yₘₐₓ, ϕxₘᵢₙ, ϕxₘₐₓ, ϕyₘᵢₙ, ϕyₘₐₓ)
    return z -> real(z) == xₘᵢₙ ? ϕxₘᵢₙ(imag(z)) :
                real(z) == xₘₐₓ ? ϕxₘₐₓ(imag(z)) :
                imag(z) == yₘᵢₙ ? ϕyₘᵢₙ(real(z)) :
                imag(z) == yₘₐₓ ? ϕyₘₐₓ(real(z)) :
                NaN
end

"""
    laplace□(x, samplesize, boundary, ϕ, σ)

Approximate the value of `f(x)` for the harmonic function `f` given on the rectangle defined by `boundary` by `f(z) = ϕ(z)`, using `samplesize` Gaussian random walks with steps of standard deviation `σ`.

# Example
```julia-repl
julia> laplace□(0.1+0.1im, 1000, (-1,1,-1,1), abs, 0.1)
1.0822962717434006
```
"""
function laplace□(x, samplesize, boundary, ϕ, σ)
    xₘᵢₙ, xₘₐₓ, yₘᵢₙ, yₘₐₓ = boundary
    (real(x) ∈ (xₘᵢₙ,xₘₐₓ) || imag(x) ∈ (yₘᵢₙ,yₘₐₓ)) && return ϕ(x)
    ϕtotal = 0
    for _ ∈ 1:samplesize
        z = x
        while (xₘᵢₙ < real(z) < xₘₐₓ) && (yₘᵢₙ < imag(z) < yₘₐₓ)
            z += σ * complex(randn(2)...)
        end
        # Shrink z towards x
        tvals = [
            (xₘᵢₙ - real(x))/(real(z) - real(x)), (xₘₐₓ - real(x))/(real(z) - real(x)),
            (yₘᵢₙ - imag(x))/(imag(z) - imag(x)), (yₘₐₓ - imag(x))/(imag(z) - imag(x))
        ]
        t = minimum(tvals[tvals .≥ 0])
        w = round(x + t*(z-x), digits = 3)
        ϕtotal += ϕ(w)
    end
    return ϕtotal / samplesize
end

"""
    plotlaplace□(gridsize, samplesize, boundary, ϕ, σ)

Plot the results of `laplace□` as evaluated on a rectangular grid with `gridsize` graduations.

# Example
```julia-repl
julia> plotlaplace□(20, 1000, (-1,1,-1,1), abs, 0.1)
```
"""
function plotlaplace□(gridsize, samplesize, boundary, ϕ, σ)
    return wireframe(
        range(boundary[1], boundary[2], length = gridsize),
        range(boundary[3], boundary[4], length = gridsize),
        (x,y) -> laplace□(x+y*im, samplesize, boundary, ϕ, σ),
        c = :black,
        legend = false
    )
end