import Base.show

using Colors
using CSV
using LinearAlgebra
using Plots

function getpoints(path::String)
    xs = Int64[]
    ys = Int64[]
    for row ∈ CSV.Rows(path)
        push!(xs,parse(Int64,row.x))
        push!(ys,parse(Int64,row.y))
    end
    return (xs, ys)
end

function bruteforcevoronoi(xs::Vector{Int64}, ys::Vector{Int64}; xmax::Int64 = 600, ymax::Int64 = 400)
    xmax = max(xmax, maximum(xs))
    ymax = max(ymax, maximum(ys))

    m = length(xs)
    colours = distinguishable_colors(m, lchoices = 50:5:100)

    pointcolours = fill(RGB(0,0,0), (xmax,ymax))
    for y ∈ 1:ymax
        for x ∈ 1:xmax
            pointcolours[x,y] = colours[findmin(hypot.(xs .- x, ys .- y))[2]]
        end
    end

    diagram = scatter(
        [(x,y) for x ∈ 1:xmax, y ∈ 1:ymax][:];
        c = pointcolours[:],
        markersize = 1,
        markerstrokewidth = 0,
        legend = false,
        showaxis = false,
        ticks = false,
        size = (xmax, ymax)
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

function montecarlovoronoi(n::Int64, xs::Vector{Int64}, ys::Vector{Int64}; xmax::Int64 = 600, ymax::Int64 = 400)
    xmax = max(xmax, maximum(xs))
    ymax = max(ymax, maximum(ys))

    m = length(xs)
    colours = distinguishable_colors(m, lchoices = 50:5:100)

    randxs = Int64[]
    randys = Int64[]
    randcolours = RGB[]

    for _ ∈ 1:n
        x, y = rand(1:xmax), rand(1:ymax)
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
        size = (xmax, ymax)
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
    M = [v₁ v₂]^-1
    t₁ = (M * (x₂ - x₁))[1]
    return x₁ + t₁*v₁
end

pos(p::VoronoiPoint) = [p.x, p.y]

function findnextpoint(p::VoronoiPoint, q::VoronoiPoint, z::Vector{T}, dir::Bool) where T <: Real
    directionvector = perpbisector(p,q)[2] .* (-1)^dir
    
    mindisplacement = Inf
    nextpoint = p
    for r ∈ q.neighbours
        r ∈ [p,q] && continue
        displacement = dot(directionvector, circumcentre(p,q,r) - z)
        displacement > 0 && displacement < mindisplacement && (mindisplacement = displacement; nextpoint = r)
    end
    return nextpoint
end

function addpoint(x::Real, y::Real, allpoints::Vector{VoronoiPoint})
    newpoint = VoronoiPoint(x, y)
    nearestpoint = allpoints[findmin([hypot(([x,y] - pos(p))...) for p ∈ allpoints])[2]]
    
    z = perpbisector(newpoint, nearestpoint)[1]
    currentpoint = nearestpoint
    reversedirection = false
    while true
        push!(newpoint.neighbours, currentpoint)
        nextpoint = findnextpoint(newpoint, currentpoint, z, reversedirection)

        # Edge goes to infinity
        if pos(nextpoint) == pos(newpoint)
            push!(newpoint.neighbours, VoronoiPoint(Inf,Inf))
            if reversedirection
                break
            else
                reversedirection = true
                currentpoint = nearestpoint
                z = perpbisector(newpoint, nearestpoint)[1]
                pop!(reverse!(newpoint.neighbours))
                continue
            end

        # Back to start
        elseif pos(nextpoint) == pos(nearestpoint)
            reverse!(newpoint.neighbours)
            break

        else
            z = circumcentre(newpoint, currentpoint, nextpoint)
            currentpoint = nextpoint
        end
    end

    n = length(newpoint.neighbours)
    for i ∈ 1:n
        neighbour = newpoint.neighbours[i]
        pos(neighbour) == [Inf, Inf] && continue
        j = findlast(p -> pos(p) == pos(newpoint.neighbours[mod(i-2,n)+1]), neighbour.neighbours)
        k = findfirst(p -> pos(p) == pos(newpoint.neighbours[i%n+1]), neighbour.neighbours)
        if j < k
            neighbour.neighbours = vcat(neighbour.neighbours[j:k], newpoint)
        else
            neighbour.neighbours = vcat(neighbour.neighbours[1:k], newpoint, neighbour.neighbours[j:end])
        end
    end

    return newpoint
end

function voronoipoints(xs::Vector{Int64}, ys::Vector{Int64})
    # Rational numbers!
    points = [VoronoiPoint(xs[1]//1,ys[1]//1,[VoronoiPoint(Inf,Inf)])]
    for i ∈ 2:length(xs)
        push!(points,addpoint(xs[i]//1,ys[i]//1,points))
    end
    return points
end

function voronoi(xs::Vector{Int64}, ys::Vector{Int64}; xmax::Int64 = 600, ymax::Int64 = 400)
    xmax = max(xmax, maximum(xs))
    ymax = max(ymax, maximum(ys))

    points = voronoipoints(xs,ys)

    m = length(xs)
    colours = distinguishable_colors(m, lchoices = 50:5:100)

    diagram = plot(
        legend = false,
        #showaxis = false,
        #ticks = false,
        size = (xmax, ymax),
        xlims = (0, xmax),
        ylims = (0, ymax)
    )
    for i ∈ 1:m
        point = points[i]
        nbs = point.neighbours
        n = length(nbs)
        vertices = Tuple{Rational{Int64}, Rational{Int64}}[]

        if pos(nbs[1]) == [Inf,Inf]
            startindex, endindex = 2, n-2

            z₁, v₁ = perpbisector(nbs[n-1],point)
            # Values of t₁ where the line z₁ + t₁v₁ intersects the borders
            t₁vals = [-z₁[2]/v₁[2], (xmax-z₁[1])/v₁[1], (ymax-z₁[2])/v₁[2], -z₁[1]/v₁[1]]
            t₁ = minimum(t₁vals[t₁vals .> 0])
            push!(vertices,Tuple(z₁ + t₁*v₁))

            z₂, v₂ = perpbisector(point,nbs[2])
            t₂vals = [-z₂[2]/v₂[2], (xmax-z₂[1])/v₂[1], (ymax-z₂[2])/v₂[2], -z₂[1]/v₂[1]]
            t₂ = minimum(t₂vals[t₂vals .> 0])

            t₁index = findfirst(==(t₁),t₁vals)
            t₂index = findfirst(==(t₂),t₂vals)
            indexdifference = mod(t₂index - t₁index,4)
            corners = [(0,0), (xmax,0), (xmax,ymax), (0,ymax)]
            for j ∈ 1:indexdifference
                push!(vertices,corners[mod(t₁index+j, 1:4)])
            end

            push!(vertices,Tuple(z₂ + t₂*v₂))

        else
            startindex, endindex = 1, n
        end

        for j ∈ startindex:endindex
            p, q = nbs[j], nbs[j%n+1]
            push!(vertices,Tuple(circumcentre(point,p,q)))
        end

        plot!(diagram, Shape(vertices), c = colours[i])
    end

    return plot(diagram)
end