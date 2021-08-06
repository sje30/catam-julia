import Base.show

using Colors
using CSV
using LinearAlgebra
using Plots

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

#= =#

mutable struct VoronoiPoint
    x::Real
    y::Real
    neighbours::Vector{VoronoiPoint}
end
VoronoiPoint(x::T, y::T) where T <: Real = VoronoiPoint(x, y, VoronoiPoint[])
# Important!
show(io::IO, p::VoronoiPoint) = print(io, "(", p.x, ",", p.y, ")")

pos(p::VoronoiPoint) = [p.x, p.y]

function perpbisector(p::VoronoiPoint, q::VoronoiPoint)
    return ( (pos(p) + pos(q))/2 , [[0,1] [-1,0]] * (pos(p) - pos(q)) )
end

function circumcentre(p::VoronoiPoint, q::VoronoiPoint, r::VoronoiPoint)
    (x₁, v₁) = perpbisector(p,q)
    (x₂, v₂) = perpbisector(p,r)
    #= 
    y = x₁ + t₁v₁, y = x₂ + t₂v₂ at point of intersection
    => x₂ - x₁ = t₁v₁ - t₂v₂
    => M(x₂ - x₁) = [t₁, -t₂] where M^-1 has columns v₁, v₂, so Mv₁ = [1, 0] and Mv₂ = [0, 1]
    =#
    det([v₁ v₂]) == 0 && return [Inf, Inf]
    M = [v₁ v₂]^-1
    t₁ = (M * (x₂ - x₁))[1]
    return x₁ + t₁*v₁
end

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

function voronoipoints(xs::Vector{T}, ys::Vector{T}) where T <: Real
    # Rational numbers!
    xs, ys = Rational{BigInt}.(xs), Rational{BigInt}.(ys)
    points = [VoronoiPoint(xs[1],ys[1],[VoronoiPoint(Inf,Inf)])]
    for i ∈ 2:length(xs)
        push!(points,addpoint(xs[i],ys[i],points))
    end
    return points
end

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

function squarepattern(n::Int64, σ::Rational{Int64})
	coords = [(x,y) for x ∈ 1:n, y ∈ 1:n]
	xs,ys = [xy[1] for xy ∈ coords[:]], [xy[2] for xy ∈ coords[:]]
	randxs = xs .+ σ * floor.(Int64, n * randn(n^2))//n
	randys = ys .+ σ * floor.(Int64, n * randn(n^2))//n
	points = voronoipoints(randxs,randys)
end