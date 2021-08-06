import Base.show

using Colors
using CSV
using LinearAlgebra
using Plots

"""
    getpoints(path::String, [usingnames::Bool])

Read the x and y coordinates from a list in a CSV file at `path`.

Also read the names if `usingnames`.

# Example
```julia-repl
julia> getpoints("points.txt")
```
"""
function getpoints(path::String, usingnames::Bool = false)
    xs = Int64[]
    ys = Int64[]
    names = String[]
    for row ∈ CSV.Rows(path)
        push!(xs,parse(Int64,row.x))
        push!(ys,parse(Int64,row.y))
        if usingnames
            push!(names,row.name)
        end
    end
    return usingnames ? (names, xs, ys) : (xs, ys)
end

"""
    bruteforcevoronoi(xs::Vector{Int64}, ys::Vector{Int64})

Draw a Voronoi diagram from lists of coordinates `xs` and `ys` by individually colouring every square of a 1000x1000 grid.

# Example
```julia-repl
julia> bruteforcevoronoi(rand(1:1000, 10), rand(1:1000, 10))
```
"""
function bruteforcevoronoi(xs::Vector{Int64}, ys::Vector{Int64})
    m = length(xs)
    colours = distinguishable_colors(m, lchoices = 50:5:100)

    pointcolours = fill(RGB(0,0,0), (1000,1000))
    for y ∈ 1:1000
        for x ∈ 1:1000
            pointcolours[x,y] = colours[findmin(hypot.(xs .- x, ys .- y))[2]]
        end
    end

    diagram = scatter(
        [(x,y) for x ∈ 1:1000, y ∈ 1:1000][:];
        c = pointcolours[:],
        markersize = 1,
        markerstrokewidth = 0,
        legend = false,
        showaxis = false,
        ticks = false,
        size = (1000, 1000)
    )
    return scatter!(
        diagram,
        xs,
        ys;
        c = :black,
        markersize = 2,
        markerstrokewidth = 0
    )
end

"""
    montecarlovoronoi(n::Int64, xs::Vector{Int64}, ys::Vector{Int64})

Sample `n` times from a 1000x1000 grid to approximate a Voronoi diagram from lists of coordinates `xs` and `ys`.

# Example
```julia-repl
julia> montecarlovoronoi(100000, rand(1:1000, 10), rand(1:1000, 10))
```
"""
function montecarlovoronoi(n::Int64, xs::Vector{Int64}, ys::Vector{Int64})
    m = length(xs)
    colours = distinguishable_colors(m, lchoices = 50:5:100)

    randxs = Int64[]
    randys = Int64[]
    randcolours = RGB[]

    for _ ∈ 1:n
        x, y = rand(1:1000), rand(1:1000)
        push!(randxs, x)
        push!(randys, y)
        push!(randcolours, colours[findmin(hypot.(xs .- x, ys .- y))[2]])
    end

    diagram = scatter(
        randxs,
        randys;
        c = randcolours,
        markersize = 1,
        markerstrokewidth = 0,
        legend = false,
        showaxis = false,
        ticks = false,
        size = (1000, 1000)
    )
    return scatter!(
        diagram,
        xs,
        ys;
        c = :black,
        markersize = 2,
        markerstrokewidth = 0,
    )
end

"""
    VoronoiPoint(x::Real, y::Real, neighbours::Vector{VoronoiPoint})
    VoronoiPoint(x::Real, y::Real)

Construct a `VoronoiPoint` at the coordinates `x`, `y`, representing a point in a Voronoi diagram.

If no neighbours are specified, default to an empty `Vector{VoronoiPoint}`.

# Examples
```julia-repl
julia> p = VoronoiPoint(3,4)
(3,4)

julia> q = VoronoiPoint(4,5,[p])
(4,5)

julia> p.neighbours
VoronoiPoint[]

julia> q.neighbours
1-element Vector{VoronoiPoint}:
 (3,4)
```
"""
mutable struct VoronoiPoint
    x::Real
    y::Real
    neighbours::Vector{VoronoiPoint}
end
VoronoiPoint(x::T, y::T) where T <: Real = VoronoiPoint(x, y, VoronoiPoint[])

show(io::IO, p::VoronoiPoint) = print(io, "(", p.x, ",", p.y, ")")

"""
    pos(p::VoronoiPoint)

Return the `x` and `y` coordinates of the `VoronoiPoint` `p` as a `Vector`.

# Example
```julia-repl
julia> pos(VoronoiPoint(3,4))
2-element Vector{Int64}:
 3
 4
```
"""
pos(p::VoronoiPoint) = [p.x, p.y]

"""
    perpbisector(p::VoronoiPoint, q::VoronoiPoint)

Return the midpoint of `VoronoiPoint`s `p` and `q`, and direction vector along the perpendicular bisector between of the same length as `p - q` and direction such that `p` is to the right and `q` is to the left.

# Example
```julia-repl
julia> perpbisector(VoronoiPoint(0,1), VoronoiPoint(2,1))
([1.0, 1.0], [0, -2])
```
"""
function perpbisector(p::VoronoiPoint, q::VoronoiPoint)
    return ( (pos(p) + pos(q))/2 , [[0,1] [-1,0]] * (pos(p) - pos(q)) )
end

"""
    circumcentre(p::VoronoiPoint, q::VoronoiPoint, r::VoronoiPoint)

Return the circumcentre of the three `VoronoiPoint`s `p`, `q`, and `r`.

If they are collinear, return `[Inf, Inf]`.

# Example
```julia-repl
julia> circumcentre(VoronoiPoint(0,0), VoronoiPoint(1,0), VoronoiPoint(0,1))
2-element Vector{Float64}:
 0.5
 0.5
```
"""
function circumcentre(p::VoronoiPoint, q::VoronoiPoint, r::VoronoiPoint)
    (x₁, v₁) = perpbisector(p,q)
    (x₂, v₂) = perpbisector(p,r)
    det([v₁ v₂]) == 0 && return [Inf, Inf]
    M = [v₁ v₂]^-1
    t₁ = (M * (x₂ - x₁))[1]
    return x₁ + t₁*v₁
end

"""
    findnextpoint(p::VoronoiPoint, q::VoronoiPoint, z::Vector{T}, reversedirection::Bool) where T <: Real

Find the `r` from `q.neighbours` where the circumcentre of `p`, `q`, and `r` is closest to `z` in the direction determined by `perpbisector`.

If `reversedirection == true`, find `r` based on the opposite direction.

# Examples
```julia-repl
julia> p = VoronoiPoint(0,0)
(0,0)

julia> q = VoronoiPoint(0,1,[p, VoronoiPoint(3,4), VoronoiPoint(-3,4)])    
(0,1)

julia> findnextpoint(p, q, [0, 0.5], false)
(3,4)

julia> findnextpoint(p, q, [0, 0.5], true)
(-3,4)
```
"""
function findnextpoint(p::VoronoiPoint, q::VoronoiPoint, z::Vector{T}, reversedirection::Bool) where T <: Real
    directionvector = perpbisector(p,q)[2] .* (-1)^reversedirection
    
    mindisplacement = Inf
    nextpoint = VoronoiPoint(Inf,Inf)
    for r ∈ q.neighbours
        r ∈ [p,q] && continue
        displacement = dot(directionvector, circumcentre(p,q,r) - z)
        displacement > 0 && displacement < mindisplacement && (mindisplacement = displacement; nextpoint = r)
    end
    return nextpoint
end

"""
    addpoint(x::Real, y::Real, allpoints::Vector{VoronoiPoint})

Add a new `VoronoiPoint` at coordinates `x` and `y`, including calculating all neighbours from `allpoints`.

Also, update neighbour lists of other points in `allpoints` to agree with the new addition.

# Example
```julia-repl
julia> p = VoronoiPoint(1,1)
(1,1)

julia> q = VoronoiPoint(2,2)
(2,2)

julia> p.neighbours = [VoronoiPoint(Inf,Inf), q, VoronoiPoint(Inf,Inf)]
3-element Vector{VoronoiPoint}:
 (Inf,Inf)
 (2,2)
 (Inf,Inf)

julia> q.neighbours = [VoronoiPoint(Inf,Inf), p, VoronoiPoint(Inf,Inf)]
3-element Vector{VoronoiPoint}:
 (Inf,Inf)
 (1,1)
 (Inf,Inf)

julia> r = addpoint(1, 2, [p,q])
(1,2)

julia> p.neighbours
4-element Vector{VoronoiPoint}:
 (Inf,Inf)
 (2,2)
 (1,2)
 (Inf,Inf)

julia> q.neighbours
4-element Vector{VoronoiPoint}:
 (Inf,Inf)
 (1,2)
 (1,1)
 (Inf,Inf)

julia> r.neighbours
4-element Vector{VoronoiPoint}:
 (Inf,Inf)
 (1,1)
 (2,2)
 (Inf,Inf)
```
"""
function addpoint(x::Real, y::Real, allpoints::Vector{VoronoiPoint})
    p = VoronoiPoint(x, y)
    nearestpoint = allpoints[findmin([hypot(x-q.x, y-q.y) for q ∈ allpoints])[2]]
    
    z = perpbisector(p, nearestpoint)[1]
    q = nearestpoint
    reversedirection = false
    while true
        push!(p.neighbours, q)
        r = findnextpoint(p, q, z, reversedirection)

        # Edge goes to infinity
        if pos(r) == [Inf,Inf]
            push!(p.neighbours, r)
            if reversedirection
                break
            else
                reversedirection = true
                q = nearestpoint
                z = perpbisector(p, nearestpoint)[1]
                pop!(reverse!(p.neighbours))
                continue
            end

        # Back to start
        elseif pos(r) == pos(nearestpoint)
            reverse!(p.neighbours)
            break

        else
            z = circumcentre(p,q,r) 
            q = r
        end
    end

    n = length(p.neighbours)
    for i ∈ 1:n
        q = p.neighbours[i]
        pos(q) == [Inf, Inf] && continue
        j = findlast(r -> pos(r) == pos(p.neighbours[mod(i-1,1:n)]), q.neighbours)
        k = findfirst(r -> pos(r) == pos(p.neighbours[mod(i+1,1:n)]), q.neighbours)
        if j < k
            q.neighbours = vcat(q.neighbours[j:k], p)
        else
            q.neighbours = vcat(q.neighbours[1:k], p, q.neighbours[j:end])
        end
    end

    return p
end

"""
    voronoipoints(xs::Vector{T}, ys::Vector{T}) where T <: Real

Calculate the lists of neighbouring regions of a Voronoi diagram with points at coordinates given by `xs` and `ys`.

Return a list of `VoronoiPoint`s containing this information, with `Rational` parameters.

# Example
```julia-repl
voronoipoints([1,2,3],[2,1,3])
julia> points = voronoipoints([1,2,3],[2,1,3])
3-element Vector{VoronoiPoint}:
 (1//1,2//1)
 (2//1,1//1)
 (3//1,3//1)

julia> points[1].neighbours
4-element Vector{VoronoiPoint}:
 (Inf,Inf)
 (2//1,1//1)
 (3//1,3//1)
 (Inf,Inf)

julia> points[2].neighbours
4-element Vector{VoronoiPoint}:
 (Inf,Inf)
 (3//1,3//1)
 (1//1,2//1)
 (Inf,Inf)

julia> points[3].neighbours
4-element Vector{VoronoiPoint}:
 (Inf,Inf)
 (1//1,2//1)
 (2//1,1//1)
 (Inf,Inf)
```
"""
function voronoipoints(xs::Vector{T}, ys::Vector{T}) where T <: Real
    # Rational numbers!
    xs, ys = Rational{BigInt}.(xs), Rational{BigInt}.(ys)
    points = [VoronoiPoint(xs[1],ys[1],[VoronoiPoint(Inf,Inf)])]
    for i ∈ 2:length(xs)
        push!(points,addpoint(xs[i],ys[i],points))
    end
    return points
end

"""
    voronoi(xs::Vector{T}, ys::Vector{T}; [names::Vector{String}]) where T <: Real

Draw a Voronoi diagram from points at coordinates `xs` and `ys` in the region (x,y) ∈ [0,1000]².

Points given `names` in a legend if specified.

# Example
```julia-repl
julia> voronoi(rand(1:1000, 10), rand(1:1000, 10))
```
"""
function voronoi(xs::Vector{T}, ys::Vector{T}; names::Vector{String} = String[]) where T <: Real
    points = voronoipoints(xs,ys)
    m = length(xs)
    colours = distinguishable_colors(m, lchoices = 50:5:100)
    usingnames = !isempty(names)

    polygons = Shape[]
    for p ∈ points
        n = length(p.neighbours)
        vertices = Tuple{Rational{Int64}, Rational{Int64}}[]

        if pos(p.neighbours[1]) == [Inf,Inf]
            startindex, endindex = 2, n-2

            x₁, v₁ = perpbisector(p.neighbours[n-1],p)
            x₁, v₁ = Rational{Int64}.(x₁), Rational{Int64}.(v₁)
            # Values of t₁ where the line x₁ + t₁v₁ intersects the borders
            t₁vals = [-x₁[2]/v₁[2], (1000-x₁[1])/v₁[1], (1000-x₁[2])/v₁[2], -x₁[1]/v₁[1]]
            t₁ = minimum(t₁vals[t₁vals .> 0])
            push!(vertices,Tuple(x₁ + t₁*v₁))

            x₂, v₂ = perpbisector(p,p.neighbours[2])
            x₂, v₂ = Rational{Int64}.(x₂), Rational{Int64}.(v₂)
            t₂vals = [-x₂[2]/v₂[2], (1000-x₂[1])/v₂[1], (1000-x₂[2])/v₂[2], -x₂[1]/v₂[1]]
            t₂ = minimum(t₂vals[t₂vals .> 0])

            t₁index = findfirst(==(t₁),t₁vals)
            t₂index = findfirst(==(t₂),t₂vals)
            indexdifference = mod(t₂index - t₁index,4)
            corners = [(0,0), (1000,0), (1000,1000), (0,1000)]
            for j ∈ 1:indexdifference
                push!(vertices,corners[mod(t₁index+j, 1:4)])
            end

            push!(vertices,Tuple(x₂ + t₂*v₂))

        else
            startindex, endindex = 1, n
        end

        for j ∈ startindex:endindex
            q,r = p.neighbours[j], p.neighbours[mod(j+1,1:n)]
            push!(vertices,Tuple(circumcentre(p,q,r)))
        end

        push!(polygons, Shape(vertices))
    end

    diagram = plot(
        polygons,
        c = colours',
        label = (usingnames ? hcat(names...) : false),
        showaxis = false,
        ticks = false,
        size = (1000, 1000),
        xlims = (0, 1000),
        ylims = (0, 1000)
    )
    return scatter!(diagram, xs, ys, c = :black, markersize = 2, label = false)
end

"""
    voronoidistribution(points::Vector{VoronoiPoint})

Count the number of edges of each of the polygons from a Voronoi diagram, as represented by `points`.

`points` should usually be the output of the function `voronoipoints`.

Display the counts in a bar chart.

# Example
```julia-repl
voronoidistribution(voronoipoints(rand(1:1000, 10), rand(1:1000, 10)))
```
"""
function voronoidistribution(points::Vector{VoronoiPoint})
    neighbourcount = broadcast(p -> pos(p.neighbours[1]) == [Inf, Inf] ? 0 : length(p.neighbours), points)

    m = maximum(neighbourcount)
    total = count(!=(0), neighbourcount)
    return bar(
        1:m,
        [count(==(i), neighbourcount)//total for i ∈ 1:m],
        legend = false,
        xticks = 1:m,
        yticks = 0:0.1:1
    )
end

"""
    randomlattice(shape::Symbol, n::Int64, σ::Rational{Int64})

Create a lattice of `n^2` points, with each perturbed randomly both vertically and horizontally by a normal distribution of standard deviation `σ`.

If `shape == :square`, the lattice is a square lattice.

If `shape == :hexagonal`, the lattice is an approximately equilateral hexagonal lattice.

Return a bar chart of the distribution of edges of the polygons in the Voronoi diagram generated by these points.

# Examples
```julia-repl
julia> randomlattice(:square, 10, 1)

julia> randomlattice(:hexagonal, 20, 1//10)
```
"""
function randomlattice(shape::Symbol, n::Int64, σ::Rational{Int64})
	if shape == :square
		coords = [(x,y) for x ∈ 1:n, y ∈ 1:n]
	elseif shape == :hexagonal
		coords = hcat([(x,(6//7)*y) for x ∈ 1:n, y ∈ 1:2:n],
			[(x+1//2,(6//7)*y) for x ∈ 1:n, y ∈ 2:2:n])
	else
		error("Invalid shape")
	end
	
	xs,ys = [xy[1] for xy ∈ coords[:]], [xy[2] for xy ∈ coords[:]]
	randxs = xs .+ σ * round.(Int64, n * randn(n^2))//n
	randys = ys .+ σ * round.(Int64, n * randn(n^2))//n
	return voronoidistribution(voronoipoints(randxs,randys))
end