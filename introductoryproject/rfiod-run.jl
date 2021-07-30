using Plots
using PrettyTables

include("rfiod.jl")
using Main.RFIOD

io = stdout
# Uncomment below to save to file instead
# io = open("output.txt", "w")

F₁(x) = 2x - 3sin(x) + 5
F₁′(x) = 2 - 3cos(x)
F₁root = -2.8832368725582835

F₂(x) = x^3 - 8.5x^2 + 20x - 8
F₂′(x) = 3x^2 - 17x + 20
F₂root = 4

# -- Question 1 -- #

q1plot = plot(F₁, -5:0.1:5, framestyle=:origin, legend = false, title = "F₁(x) = 2x - 3sin(x) + 5 has a single real root in [-5,5]")
# F₁′(x) > 0 outside of this interval with F₁(-5) < 0, F₁(5) > 0, so no roots outside

# -- Binary Search Programming Task -- #
println(io, "-- Binary Search Programming Task --")

# Initial interval [-5, 5]
BSresult1 = binarysearch(F₁, -5, 5)
# Initial interval [-5, 5], but with inputs swapped
BSresult2 = binarysearch(F₁, 5, -5)
# Initial interval [-2.88323688, -2.88323687]
BSresult3 = binarysearch(F₁, -2.88323688, -2.88323687)
# Initial interval [-100, 100]
BSresult4 = binarysearch(F₁, -100, 100)

println(io, "Binary search with initial interval [a,b]")
# Table created for display
tabledata = hcat(
    [-5, 5, -2.88323688, -100],
    [5, -5, -2.88323687, 100],
    Plots.unzip([BSresult1, BSresult2, BSresult3, BSresult4])...
)
pretty_table(io, tabledata, header = ["a", "b", "root", "iterations"])

# Initial interval [-1, 1], which does not contain a root
BSresult5 = try binarysearch(F₁, -1, 1) catch ErrorException "Error, root not found" end
println(io, "Binary search with the invalid initial interval [-1, 1] gives:")
show(io, BSresult5)

# -- Question 3 -- #
println(io, "\n\n-- Question 3 --")

f(k) = x -> x - F₁(x)/(2+k)

"""
    q3FPI(k, x₀, Nₘₐₓ, [ε])

Run the fixed point iteration algorithm used in Question 3, with parameter `k` and starting value `x₀`.

Terminate if consecutive iterations differ by less than `ε`, or after `Nₘₐₓ` iterations.

Outputs a table to the REPL with the results, and returns a staircase/cobweb diagram.

# Examples

```julia-repl
julia> q3FPI(3,-2,10)
Fixed point iteration with k = 3, Nₘₐₓ = 10
┌─────┬──────────┬────────────┬───────────┐
│   n │       xₙ │         ϵₙ │   ϵₙ/ϵₙ₋₁ │
├─────┼──────────┼────────────┼───────────┤
│ 0.0 │     -2.0 │   0.883237 │       0.0 │
│ 1.0 │ -2.74558 │   0.137658 │  0.155857 │
│ 2.0 │ -2.87879 │ 0.00444334 │  0.032278 │
│ 3.0 │ -2.88315 │ 9.00029e-5 │ 0.0202557 │
│ 4.0 │ -2.88324 │ 1.79286e-6 │ 0.0199201 │
│ 5.0 │ -2.88324 │ 3.57019e-8 │ 0.0199133 │
└─────┴──────────┴────────────┴───────────┘
```

"""
function q3FPI(k, x₀, Nₘₐₓ, ε = 1e-5)

    result = fixedpointiteration(f(k), x₀, Nₘₐₓ, ε)
    n = length(result) - 1

    errors = result .- F₁root
    errorratios = [0, (errors[2:(n+1)] ./ errors[1:n])...]
    tabledata = hcat(
        collect(0:n),
        result,
        errors,
        errorratios
    )
    println(io, "Fixed point iteration with k = $k, Nₘₐₓ = $Nₘₐₓ")
    pretty_table(io, tabledata, header = ["n", "xₙ", "ϵₙ", "ϵₙ/ϵₙ₋₁"])

    FPIplot = staircasediagram(f(k), result)
    plot!(FPIplot, title = "k = $k")
    return FPIplot

end

# k = 0, ε = 10⁻⁵, x₀ = -2, Nₘₐₓ = 10
q3plot1 = q3FPI(0, -2, 10)

# k = 4 gives monotonic convergence as f(8)'(x*) > 0
q3plot2 = q3FPI(4, -2, 20)

# k = 2 gives oscillatory convergence as f(1)'(x*) < 0
q3plot3 = q3FPI(2, -2, 20)

# k = 16, Nₘₐₓ = 50
q3FPI(16, -2, 50)

# -- Question 4 -- #
println(io, "\n-- Question 4 --")

g(x) = x - F₂(x)/20

q4result = fixedpointiteration(g, 5, 1000, 1e-5)
# n and xₙ take the final values given below
n = length(q4result) - 1
xₙ = q4result[end]
println(io, "Fixed point iteration to find the double root of
F₂(x) = x³ - 8.5x² + 20x - 8 results in n = $n iterations
with estimated root xₙ = $xₙ")

# -- Question 5 -- #
println(io, "\n-- Question 5 --")

"""
    q5NR(f, x₀, Nₘₐₓ, root, order)

Run the Newton-Raphson algorithm used in Question 5 on the function `f(x) = x - F(x)/F'(x)` starting at `x₀`

Terminate the fixed point iteration after at most Nₘₐₓ iterations.

Outputs a table with errors to `root` and error ratios of order `order`, and returns the vector of iterations.

# Examples

```julia-repl
julia> q5NR(x -> x - sin(x)/cos(x), 3, 10, π, 2)
┌─────┬─────────┬──────────────┬──────────────┐
│   n │      xₙ │           ϵₙ │     ϵₙ/ϵₙ₋₁² │
├─────┼─────────┼──────────────┼──────────────┤
│ 0.0 │     3.0 │    -0.141593 │          0.0 │
│ 1.0 │ 3.14255 │  0.000953889 │    0.0475791 │
│ 2.0 │ 3.14159 │ -2.89316e-10 │ -0.000317963 │
│ 3.0 │ 3.14159 │          0.0 │          0.0 │
│ 4.0 │ 3.14159 │          0.0 │          NaN │
└─────┴─────────┴──────────────┴──────────────┘
5-element Vector{Float64}:
 3.0
 3.142546543074278
 3.141592653300477
 3.141592653589793
 3.141592653589793
```
"""
function q5NR(f, x₀, Nₘₐₓ, root, order)
    result = fixedpointiteration(f, x₀, Nₘₐₓ)
    n = length(result) - 1
    errors = result .- root
    errorratios = [0, (errors[2:(n+1)] ./ errors[1:n].^order)...]
    tabledata = hcat(
        collect(0:n),
        result,
        errors,
        errorratios
    )
    pretty_table(io, tabledata, header = ["n", "xₙ", "ϵₙ", "ϵₙ/ϵₙ₋₁" * (order == 2 ? "²" : "")])
    return result
end

"""
    q5NRgraph(F, result, nlines)
Create a graph from the first `nvalues` iterations of `result`, coming from the Newton-Raphson algorithm on `F`.

# Examples

```julia-repl
julia> q5NRgraph(sin, q5NR(x -> x - sin(x)/cos(x), 3, 10, π, 2), 4)
```    
"""
function q5NRgraph(F, result, nlines)
    NRplot = scatter((result[1],F(result[1])), markercolor = :black, framestyle = :origin,
        title = "Newton-Raphson with x₀ = $(result[1])", legend = false)
    for n = 1:nlines
        plot!(NRplot, [result[n],result[n+1],result[n+1]],
            [F(result[n]), 0, F(result[n+1])], linecolor = :black)
    end
    plot!(NRplot, F, linecolor = :orange)
    return NRplot
end

f₁(x) = x - F₁(x)/F₁′(x)
f₂(x) = x - F₂(x)/F₂′(x)

# x₀ = 0 for F₁ gives divergence
println(io, "Newton-Raphson method for \nF₁(x) = 2x - 3sin(x) + 5 with x₀ = 0")
q5result1 = q5NR(f₁, 0, 10, F₁root, 2)
q5plot1 = q5NRgraph(F₁, q5result1, 4)

# x₀ = -2 for F₁ gives convergence
println(io, "Newton-Raphson method for \nF₁(x) = 2x - 3sin(x) + 5 with x₀ = -2")
q5result2 = q5NR(f₁, -2, 10, F₁root, 2)
q5plot2 = q5NRgraph(F₁, q5result2, 2)

# x₀ = 5 for F₂ gives convergence
println(io, "Newton-Raphson method for \nF₂(x) = x³ - 8.5x² + 20x - 8 with x₀ = 5")
q5result3 = q5NR(f₂, 5, 50, F₂root, 1)
q5plot3 = q5NRgraph(F₂, q5result3, 10)

# Saves images automatically, uncomment to use
#=

# File extension e.g. ".png", ".pdf"
ext = ".pdf"

# Makes a new directory for the images (or ignores the error if one exists already)
try
    mkdir("images")
catch IOError
    nothing
end

# Saves the figures created above
try
    savefig(q1plot,"images\\q1-singleroot$ext")
    savefig(q3plot1,"images\\q3-k0-graph$ext")
    savefig(q3plot2,"images\\q3-k4-graph$ext")
    savefig(q3plot3,"images\\q3-k2-graph$ext")
    savefig(q5plot1,"images\\q5-f1divergence-graph$ext")
    savefig(q5plot2,"images\\q5-f1convergence-graph$ext")
    savefig(q5plot3,"images\\q5-f2convergence-graph$ext")
catch IOError
    println("Failed to save images")
end

=#

io == stdout || close(io)
nothing