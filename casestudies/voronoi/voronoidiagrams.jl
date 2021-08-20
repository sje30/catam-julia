### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ d66df1f3-c14a-440b-8148-7f5daa006f7c
using CSV

# ╔═╡ bff18246-4ea2-43c0-9dca-69e855f06b7d
using Colors

# ╔═╡ 2c21b237-c4b7-4de2-b0ce-287bdf252081
using Plots

# ╔═╡ 25c8d94d-0393-4382-bbf4-500135b12f25
using LinearAlgebra

# ╔═╡ 34039790-f50e-11eb-0b84-25496cba179e
begin
	using PlutoUI
	PlutoUI.TableOfContents(title = "Contents")
end

# ╔═╡ 814a424a-96c4-4449-b002-f2e3122cb56d
md"""
# Voronoi diagrams
"""

# ╔═╡ 26bf6d61-25e8-4558-97ea-72185b7dc963
md"""
## Objectives
- Create an algorithm to draw a Voronoi diagram from a list of points
- Analyse the distribution of the number of edges of the polygons in a Voronoi diagram
"""

# ╔═╡ a1f023ab-e2ab-4d74-8067-e364ddeaa7ed
md"""
## What is a Voronoi diagram?

A Voronoi diagram is a diagram constructed in the plane, where given a number of points, the plane is partitioned into sections based on which of these points is closest. An example can be seen below for the approximate locations of Cambridge colleges (specifically, the main porter's lodges of each college):
"""

# ╔═╡ e9845cba-d61a-4150-9698-6dffbdde3138
md"""
Three particular degenerate cases can occur in Voronoi diagrams. The first one I will attempt to reduce the impact of, but the other two I will ignore for the purposes of this project:
- Three (or more) points can be exactly collinear. This does not always pose a problem, particularly if there are other points nearby. Indeed, in the example above, the points representing King's, Corpus Christi, and Pembroke are exactly collinear, but the diagram is still generated without an issue.
- Even worse, two points could coincide, which is guaranteed to break the algorithm. Unsurprisingly, no porter's lodges coincide, with the closest being Corpus Christi and St Catharine's at a distance of the width of Trumpington Street, two pavements and a bit of lawn apart, which is more than enough to be distinguished at this scale.
- Four (or more) points can lie on a circle and so their regions meet at a quadripoint. This is far less likely to occur but requires a special case which I have not programmed into the algorithm. Despite a couple of near misses, there are no exact quadripoints in the dataset of colleges. The nearest is between Clare, King's, St Catharine's, and Queens', with the King's and Queens' regions sharing an edge of length approximately 1 metre (although this is well within errors caused by curvature of the Earth and the fact that porter's lodges are not particularly zero-dimensional)
"""

# ╔═╡ 2b2f564c-03f1-4da0-941e-c08bff8203fc
md"""
## Importing the data
The first step to creating a Voronoi diagram is to get the data, which in this case is stored in *.csv* files. The CSV package allows for the easy import of such data.
"""

# ╔═╡ 3683349f-55da-4725-937c-882d620261ac
md"""
I construct the function `getpoints` to perform this import. Empty vectors are created to store the data: `xs` for the first coordinate of each point, `ys` for the second coordinate of each point, and `names` for names (if they are specified). Then, using the iterator `CSV.Rows`, I read the input file row by row, taking down the values stored. Then, I output the two/three (depending on if names are specified) vectors of data obtained from the file:
"""

# ╔═╡ 00f99f29-fd88-4bdd-875a-83e892cf4182
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

# ╔═╡ 66f26cb1-958e-44e1-8ff2-0e65065347cd
md"""
The main data that I will be using will be 100 integer-valued points between ``(1,1)`` and ``(1000,1000)``, which I now import as `xs` and `ys`.
"""

# ╔═╡ d7e145f0-afd7-4f7b-a570-a20f54444c06
xs, ys = getpoints("voronoipoints.txt")

# ╔═╡ fa9cce06-5c0d-46d8-82a8-110777450737
md"""
## Two simple but inefficient approaches
To get a feel for Voronoi diagrams, I start with two simple approaches to creating approximate Voronoi diagrams.

### Brute force method
The brute force method involves checking every single point in the eventual image, seeing which of the points it is closest to, and colouring it accordingly. This is simple, although horribly inefficient, since for each of one million points it needs to calculate 100 distances, totalling 100 million calculations.

To choose the colours, I use the `Colors` package, which contains the function `distinguishable_colors` to help choose colours that should be reasonably distinguishable from each other. I store these in a list indexed correspondingly with `xs` and `ys`.
"""

# ╔═╡ a5bae7fe-6bd8-49f8-9ccb-3567c4dceeee
md"""
Then, I create a matrix of colours (the `RGB` type), and iterate over each element (columns first for efficiency). The Euclidean distances are calculated with the function `hypot`, which I broadcast over all of the points and look for the minimum value in the resulting vector with `findmin`. I take the index of this value (as `findmin` outputs both the value and its index, I obtain the index by simply taking the second output), and then fill the matrix with the appropriate colour from the list.
```julia
pointcolours[x,y] = colours[findmin(hypot.(xs .- x, ys .- y))[2]]
```
After this, I create a scatter plot (using the `Plots` package), with each location in the appropriate colour, and add on markers for the points defining the Voronoi diagram
"""

# ╔═╡ 20a6f5d1-1df1-402f-bdb0-770e373a2caf
md"""
This I put into a function `bruteforcevoronoi`, which I can then test out on the data imported earlier.
"""

# ╔═╡ 04f8030e-a838-4e32-91c5-af63b50b8ef2
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

# ╔═╡ 16ee482f-2d14-4fa4-84c4-fb02e29e4e5f
bruteforcevoronoi(xs,ys)

# ╔═╡ c7ce5d31-c823-433e-90c7-474e5c64a25e
md"""
This is quite a good Voronoi diagram, although a little slow. Many of the edges don't look very straight, but this is not surprising since the diagram is calculated in a very discrete way so smoothness would be too much to ask for.

### Monte Carlo method
In order to improve the speed, the obvious thing to do is to reduce the sample size. I can do this by randomly sampling from the plane instead of calculating the nearest point everywhere. This I implement with the function `montecarlovoronoi`, with an additional input `n` representing the number of samples to make.
"""

# ╔═╡ 0ecd4b67-aee6-4dfb-94e5-7cc8cae0c01d
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

# ╔═╡ 6ae8754a-9fb3-43a1-adcc-42411be63467
md"""
To test this method, I run the function with 1000, 10000, 100000, and finally 1000000 samples (the final one being the same number of samples as `bruteforcevoronoi` makes).
"""

# ╔═╡ ac20813e-57ec-4f40-bbaa-eeed7557f2f5
plot(
	montecarlovoronoi(1000,xs,ys),
	montecarlovoronoi(10000,xs,ys),
	montecarlovoronoi(100000,xs,ys),
	montecarlovoronoi(1000000,xs,ys), 
	layout = (2,2)
)

# ╔═╡ 6f1c21bc-2803-4f10-ae1a-47fa6a883f19
md"""
From these tests, it is clear to me that anything less than 100000 samples doesn't produce a clear Voronoi diagram, and so this improves on the speed of `bruteforcevoronoi` by about an order of magnitude at most. Even then, the edges are wigglier than in the first instance, making the diagram somewhat less clear.

A problem with both these methods is that they give next to no information about the diagram other than the image representing it. For example, there is no way to know which regions border others other than checking manually from the diagrams, which would be time consuming to do for every region. This prevents me from doing any analysis on the diagram's structure, or efficiently storing the diagram in memory. A cleverer approach will be necessary to achieve this.
"""

# ╔═╡ 5619eeaa-d0ae-4752-987a-abc6b9236725
md"""
## Constructing the Voronoi diagram geometrically
"""

# ╔═╡ 35546877-09ce-4294-acd3-6150a2b3637d
md"""
### A geometric algorithm
A close look at the Voronoi diagram's construction reveals two useful geometric facts about the edges between points:
- All edges are equidistant from the two points whose regions it seperates, i.e. are segments of perpendicular bisectors
- Where edges meet, they are equidistant from three points, so the tripoint must lie at the circumcentre of the three points (the centre of the circle passing through all three)
"""

# ╔═╡ f50845c7-45b1-46a0-9c7f-35303080b036
begin
	diagram₁ = plot(
		[   Shape([(-2,-2),(-2,3),(0,2.5),(2,-1.5)]),
			Shape([(0,2.5),(2,-1.5),(3,-2),(3,3)]),
			Shape([(5,-2),(4.5,3),(85/12,5/12),(7.5,-1.25)]),
			Shape([(4.5,3),(85/12,5/12),(8,2.25)]),
			Shape([(85/12,5/12),(8,2.25),(10,3),(10,-2),(7.5,-1.25)])],
		c = [:pink :lightblue :pink :lightblue :beige],
		linewidth = 0,
		legend = false,
		showaxis = false,
		ticks = false,
		xlims = [-1, 9],
		ylims = [-1, 2],
		size = (1000, 300)
	)
	
	scatter!(
		diagram₁,
		[(0,0),(2,1),(6,0.5),(7,1.5),(8,1)],
		c = :black,
	)

	
	plot!(
		diagram₁,
		[x -> 2.5 - 2x, x -> 0.5x],
		c = [:black :gray],
		linestyle = [:solid :dash]
	)
	
	plot!(
		diagram₁,
		[(0.9,0.45),(0.85,0.55),(0.95,0.6)],
		c = :gray
	)
	
	plot!(
		diagram₁,
		1.0865*cos.(0:0.01π:2.01π) .+ 85/12,
		1.0865*sin.(0:0.01π:2.01π) .+ 5/12,
		c = :gray,
		linestyle = :dash
	)
	
	plot!(
		diagram₁,
		[(4.5,3),(85/12,5/12),(8,2.25),(85/12,5/12),(7.5,-1.25)],
		c = :black
	)
	
	plot!(
		diagram₁,
		[(6,0.5),(85/12,5/12),(7,1.5),(85/12,5/12),(8,1)],
		c = :gray,
		linestyle = :dash
	)
	
	plot!(
		diagram₁,
		[(98/15,7/20),(131/20,17/30)],
		c = :grey
	)
	
	plot!(
		diagram₁,
		[(104/15,19/20),(143/20,29/30)],
		c = :grey
	)
	
	plot!(
		diagram₁,
		[(38/5,37/60),(449/60,4/5)],
		c = :grey
	)
	
	plot!(
		diagram₁,
		Shape([(3,-2),(5,-2),(5,3),(3,3)]),
		c = :white,
		linecolor = :white
	)
end

# ╔═╡ 26dfe1aa-9e61-46dd-953b-3164c4470458
md"""
Consider two points ``\mathbf{p}`` and ``\mathbf{q}`` whose regions share an edge in the Voronoi diagram, and consider the circumcentres of ``\mathbf{p}``, ``\mathbf{q}``, and ``\mathbf{r}`` for all other points ``\mathbf{r}`` which define the diagram. All of these circumcentres must lie on the perpendicular bisector of ``\mathbf{p}`` and ``\mathbf{q}``. Additionally, if any of these circumcentres were on the edge between the regions, then ``\mathbf{r}`` would be closer than ``\mathbf{p}`` or ``\mathbf{q}`` on one side of the line, so this must lie at the end of the edge.

Indeed, for any points ``\mathbf{p}`` and ``\mathbf{q}``, the circumcentres of ``\mathbf{p}`` and ``\mathbf{q}`` with each other point ``\mathbf{r}`` lie on the perpendicular bisector, with the border between the Voronoi regions of ``\mathbf{p}`` and ``\mathbf{q}`` either nonexistent, or one of the line segments between adjacent circumcentres, such as below:
"""

# ╔═╡ 7c392155-a7b1-4dfb-b6bb-bb52e8f071f7
begin
	diagram₂ = scatter(
		[(4,-0.5),(4,1.5)],
		c = :black,
		legend = false,
		showaxis = false,
		ticks = false,
		xlims = [-1, 9],
		ylims = [-1, 2],
		ann = [(4.2,-0.6,"q"),(3.8,1.6,"p")],
		size = (1000, 300)
	)
	
	plot!(
		diagram₂,
		[(-2,0),(10,1)],
		c = :lightgray,
		linestyle = :dash
	)
	
	plot!(
		diagram₂,
		[(4.5,6.5/12),(5,7/12)],
		c = :black
	)
	
	scatter!(
		diagram₂,
		[(1,1/4),(3,5/12),(4.5,6.5/12),(5,7/12),(7.5,9.5/12)],
		c = :lightgray,
		markerstrokewidth = 0
	)
end

# ╔═╡ 406599de-7141-4c59-a294-bffb79973098
md"""
This gives rise to the algorithm that I will implement. For each point ``\mathbf{p}`` of the Voronoi diagram in succession, I will start at a point ``\mathbf{z}`` which I know is on the border of ``\mathbf{p}``'s region (which will be halfway between ``\mathbf{p}`` and the closest other point ``\mathbf{q}``).
"""

# ╔═╡ c5553b17-c7a6-4c3d-92e2-9dff80c28867
begin
	diagram₃ = scatter(
		[(0.5,0.5),(1,1.5),(0.75,1)],
		c = :black,
		shape = [:o, :o, :x],
		markersize = [3, 3, 5],
		legend = false,
		showaxis = false,
		ticks = false,
		xlims = [-1, 3],
		ylims = [-1, 2],
		ann = [(0.7,0.4,"p"),(0.8,1.6,"q"),(0.9,1.1,"z")],
		size = (400, 300)
	)
	
	plot!(
		diagram₃,
		[(-1.25,2),(3.75,-0.5)],
		c = :gray,
		linestyle = :dash
	)
	
	plot!(
		diagram₃,
		[(0.75,1),(1.25,0.75)],
		c = :black,
		arrow = arrow(:closed)
	)
end

# ╔═╡ 98e6d6c3-1623-403a-b066-bdd280aaee4e
md"""
Then, looking in one direction along the perpendicular bisector, I find the point ``\mathbf{r}`` which along with ``\mathbf{p}`` and ``\mathbf{q}`` defines the first circumcentre that I would come across. This circumcentre becomes a tripoint, and I get a new edge to the region to look down, that is the edge between ``\mathbf{p}`` and ``\mathbf{r}``, along their perpendicular bisector.
"""

# ╔═╡ 283f5b27-6bd6-4cc2-98b7-d72377505626
begin
	diagram₄ = scatter(
		[(0.5,0.5),(1,1.5),(3,1),(65/36,17/36)],
		c = [:black, :black, :black, :gray],
		markerstrokewidth = 0,
		legend = false,
		showaxis = false,
		ticks = false,
		xlims = [-1, 3],
		ylims = [-1, 2],
		ann = [(0.7,0.4,"p"),(0.8,1.6,"q"),(2.8,1.1,"r")],
		size = (400, 300)
	)
	
	plot!(
		diagram₄,
		[(-1.25,2),(3.75,-0.5)],
		c = :gray,
		linestyle = :dash
	)
	
	plot!(
		diagram₄,
		[(0.75,1),(65/36,17/36)],
		c = :black
	)
	
	plot!(
		diagram₄,
		[(1.25,3.25),(2.25,-1.75)],
		c = :gray,
		linestyle = :dash
	)
	
	plot!(
		diagram₄,
		[(65/36,17/36),(2,-0.5)],
		c = :black,
		arrow = arrow(:closed)
	)
end

# ╔═╡ 74fe0258-6c8e-4383-9aad-ffcb890e9612
md"""
I continue this all the way around until I return to the start, giving a cycle of neighbours in the order that they are encountered.

However if ``\mathbf{p}`` is on the edge of the diagram, then at some point there will be no circumcentre to be find along the line. In this special case, I return to the same initial point ``\mathbf{z}`` and start to look the other way, until again there is no circumcentre to find. Instead of a cycle of neighbours, this gives a sequence of neighbours bookended by neighbours with which ``\mathbf{p}`` shares a unbounded edge.
"""

# ╔═╡ 4ff3a96d-14dd-4af8-820a-bbb30c3fca15
md"""
### The VoronoiPoint type
To be able to store the data about each point, I create a new type called `VoronoiPoint`, which contains as fields its `x` and `y` coordinates, as well as a vector of neighbours. I also create an outer constructor which allows me to easily initialise a new `VoronoiPoint` with no neighbours.
"""

# ╔═╡ 7d80b224-03ad-4034-af2d-7975b6e0e7a9
begin
	mutable struct VoronoiPoint
    	x::Real
    	y::Real
    	neighbours::Vector{VoronoiPoint}
	end
	VoronoiPoint(x::T, y::T) where T <: Real = VoronoiPoint(x, y, VoronoiPoint[])
end

# ╔═╡ 26502d5d-54c6-4d57-9be4-5e8971635560
md"""
This new type has a subtle problem, which is with its automatic display style. If `p` and `q` is a `VoronoiPoint`, and they neighbour, then:
- To display `p`, Julia automatically displays `p.x`, `p.y`, and the vector `p.neighbours`. This includes `q`, so Julia will have to display `q`
- To display `q`, Julia displays `q.neighbours`, which includes `p`. This creates an infinite loop
In order to fix this, I need to create a new method for `Base.show` (the function determining this display) which does not display the neighbours. I chose the coordinate style `(x,y)`.
"""

# ╔═╡ 8c07108a-49e0-4ef3-873c-e5d6576c99cc
begin
	import Base.show
	show(io::IO, p::VoronoiPoint) = print(io, "(", p.x, ",", p.y, ")")
end

# ╔═╡ 00d09735-0b30-465c-9c39-81209d36265f
VoronoiPoint(4,5)

# ╔═╡ ada943f1-077e-4fa0-9024-915e7d23c2e2
md"""
### Three geometric functions
To be able to implement my algorithm, I need three functions to capture the geometry between `VoronoiPoint`s, for which I will also use the LinearAlgebra package.
"""

# ╔═╡ d3b2bb40-359e-4696-a74d-030afcf4f9c7
md"""
The first function `pos` is very simple, merely assembling the position vector of a `VoronoiPoint` from its `x` and `y` fields.
"""

# ╔═╡ 4b3fc852-caae-4b8d-8582-f308a9a255ca
pos(p::VoronoiPoint) = [p.x, p.y]

# ╔═╡ fc64f356-5550-4d43-8564-0d2002dc8316
md"""
The second function `perpbisector` finds the parameters defining the perpendicular bisector as a line in in the plane. In particular, it outputs two vectors, the midpoint of the two (which lies on the line), and a direction vector. The choice of which direction this vector goes along the line is arbitrary, although it is important to know for later (I have chosen it such that `p` lies to the right and `q` lies to the left).
"""

# ╔═╡ 9b35606b-9175-40a5-99e8-62251e72f3a4
function perpbisector(p::VoronoiPoint, q::VoronoiPoint)
    return ( (pos(p) + pos(q))/2 , [[0,1] [-1,0]] * (pos(p) - pos(q)) )
end

# ╔═╡ f2b1cc32-370f-465c-bab8-15365cf5de69
md"""
The third and most complicated function `circumcentre` calculates the circumcentre of three `VoronoiPoint`s. This is easiest to do as the intersection of two perpendicular bisectors:
```math
\mathbf{y} = \mathbf{x_1} + t_1 \mathbf{v_1}, \quad \mathbf{y} = \mathbf{x_2} + t_2 \mathbf{v_2}
```
Equating these gives:
```math
\mathbf{x_2} - \mathbf{x_1} = t_1 \mathbf{v_1} - t_2 \mathbf{v_2}
```
which is a linear system of two equations in two unknowns ``t_1`` and ``t_2``. If ``\mathbf{v_1}`` and ``\mathbf{v_2}`` are parallel, this is degenerate (meaning that the three points are collinear), and I will return an infinite vector, ensuring that this circumcentre is not found on the line. Otherwise, I let ``M`` be the inverse of the matrix with columns ``\mathbf{v_1}`` and ``\mathbf{v_2}``, leaving:
```math
M(\mathbf{x_2} - \mathbf{x_1}) = \begin{pmatrix} t_1 \\ t_2 \end{pmatrix}
```
This I can solve, and hence find the circumcentre ``\mathbf{y}``.
"""

# ╔═╡ 951bea47-8e23-45f9-b935-882566d3fdc3
function circumcentre(p::VoronoiPoint, q::VoronoiPoint, r::VoronoiPoint)
    (x₁, v₁) = perpbisector(p,q)
    (x₂, v₂) = perpbisector(p,r)
    det([v₁ v₂]) == 0 && return [Inf, Inf]
    M = [v₁ v₂]^-1
    t₁ = (M * (x₂ - x₁))[1]
    return x₁ + t₁*v₁
end

# ╔═╡ 3ffacdd0-510f-4ef5-b934-4ff15b536b7c
md"""
### Adding points to the diagram one by one
To construct the diagram, I have chosen to add each point one by one. This reduces the looping over all points `r` to a smaller loop - indeed it is even smaller since I need only check the neighbours of `q` - but comes at the cost of having to adjust the list of neighbours of all of the points calculated to neighbour `p`.

First I put to use the three geometric functions that I have just defined in order to create the function `findnextpoint`. This function performs the job of looking along the perpendicular bisector to find which point `r` has the closest circumcentre with `p` and `q` to the initial starting point `z`. This I do by dot multiplying `directionvector` (calculated by `perpbisector` and pointing along the line) with the vector from `z` to the circumcentre for each of `q`'s neighbours, giving a measure of displacement along the bisector. If no circumcentres are found in that direction, the `nextpoint` output is `VoronoiPoint(Inf,Inf)`, denoting that the edge goes to infinity, which can be identified by the next function.

Since the algorithm can involve looking both ways along a perpedicular bisector, I use an additional boolean input `reversedirection` to determine whether the default direction given by `perpbisector` should be reversed or not. 
"""

# ╔═╡ c6ff22c9-16d8-494a-8b82-997a61ecf38c
function findnextpoint(p::VoronoiPoint, q::VoronoiPoint, z::Vector{T},
		reversedirection::Bool) where T <: Real
    directionvector = perpbisector(p,q)[2] .* (-1)^reversedirection
    
    mindisplacement = Inf
    nextpoint = VoronoiPoint(Inf,Inf)
    for r ∈ q.neighbours
        r ∈ [p,q] && continue
        displacement = dot(directionvector, circumcentre(p,q,r) - z)
        displacement > 0 && displacement < mindisplacement &&
			(mindisplacement = displacement; nextpoint = r)
    end
    return nextpoint
end

# ╔═╡ 8f9286e4-f49d-4227-9611-9793f484d5dd
md"""
The next function is `addpoint`, which adds a new point at coordinates `x` and `y` relative to a vector `allpoints` listing all of the other points that are in the diagram so far.

The first course of action is to create the new `VoronoiPoint` object, and find the nearest other point to it which can be used as a starting point, similarly to how it is done in the brute force and Monte Carlo methods above.
```julia
p = VoronoiPoint(x, y)
nearestpoint = allpoints[findmin([hypot(x-q.x, y-q.y) for q ∈ allpoints])[2]]
```

Then I can set up initial values for `z` (the point tracing the boundary of `p`'s region) and `q` (the neighbouring point along whose perpendicular bisector with `p` the algorithm is looking), as well as the boolean `reversedirection` to keep track of whether the algorithm is looking in its default direction or not.
```julia
z = perpbisector(p, nearestpoint)[1]
q = nearestpoint
reversedirection = false
```

Now, the propagation can begin. For each iteration, first `q` is added to the end of the list of `p`'s neighbours.
```julia
push!(p.neighbours, q)
```

After that, I look for the next point `r` as found by `findnextpoint`.
```julia
r = findnextpoint(p, q, z, reversedirection)
```
"""

# ╔═╡ 3acc9ae8-c107-4434-b72d-590a1abc8130
md"""
Three different scenarios can occur with `r`:
- `r` could be the special case `VoronoiPoint(Inf,Inf)`. To avoid writing an equality method for `VoronoiPoint`s, I compare their positions only, since I am assuming no two can coincide, hence I check this case with `pos(r) == [Inf,Inf]`. If this occurs, then I start by adding `VoronoiPoint(Inf,Inf)` onto the end of the list of neighbours to mark that the line extends to infinity here. If I have already checked in the other direction too (i.e. `reversedirection == true`), then I am done, otherwise I revert back to the original values of `z` and `q`, but with the direction reversed and `q` taken off the list since it will be added again at the next loop. In order to maintain the order of the list of neighbours, I reverse that too.
```julia
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
```

- `r` could be `nearestpoint`, in which case the point `z` has traced out the entire loop around `p`, so the algorithm can stop (note that in a Voronoi diagram the regions are convex so never share two seperate borders). Before stopping the loop, I reverse the list of neighbours to keep consistency with the first case, ensuring that whenever the algorithm stops `p`'s neighbours will always be in anticlockwise order, which will become important later.
```julia
reverse!(p.neighbours)
break
```

- Otherwise, the algorithm simply needs to repeat with a new point `z` and a new neighbour `q`.
```julia
z = circumcentre(p,q,r)
q = r
```
"""

# ╔═╡ e39cf938-c946-4a65-bb20-3c5c73bb0ef2
md"""
Now that the loop has finished, I have a point `p` with all of its neighbours found in the correct order, and it is ready to be returned. However, the list of neighbours for other points has not yet been updated, which I need to do first before ending the function. This is made simpler by the fact that the neighbours of each point are always in an expected order, specifically:
```math
\mathbf{p} \text{ has neighbours } \dots \mathbf{q_{i-1}}, \mathbf{q_i}, \mathbf{q_{i+1}}, \dots \quad \Rightarrow \quad \mathbf{q_i} \text{ has neighbours } \dots \mathbf{q_{i+1}}, \mathbf{p}, \mathbf{q_{i-1}}, \dots
```

Also, the other neighbours of ``\mathbf{q_i}`` would not have changed in order at all, so all I need to do is find the gap between ``\mathbf{q_{i+1}}`` and ``\mathbf{q_{i-1}}``, and place ``\mathbf{p}`` in it.

For each `qᵢ` (one of the `n` neighbours of `p`) which isn't one of the infinity markers `VoronoiPoint(Inf,Inf)` at either end, I look for the indices of `qᵢ₋₁` and `qᵢ₊₁` amongst its neighbours. Since these could themselves be a `VoronoiPoint(Inf,Inf)`, I make sure to search for them from the correct end of the list of neighbours, that is `qᵢ₋₁` from the end and `qᵢ₊₁` from the start.
```julia
pos(q) == [Inf, Inf] && continue
j = findlast(r -> pos(r) == pos(p.neighbours[mod(i-1,1:n)]), q.neighbours)
k = findfirst(r -> pos(r) == pos(p.neighbours[mod(i+1,1:n)]), q.neighbours)
```

Once I have these indices, I place `p` in the list of neighbours between the two, getting rid of anything that was in between before. Since the list of neighbours can be cyclic, I check the order of the two indices first to make sure I know which way "in between" means.
```julia
if j < k
    q.neighbours = vcat(q.neighbours[j:k], p)
else
    q.neighbours = vcat(q.neighbours[1:k], p, q.neighbours[j:end])
end
```

Finally, the point `p` has been successfully added, with all of the other points updated accordingly. The full function is:
"""

# ╔═╡ aee35cf6-8ef4-4550-b65f-a546416d642f
function addpoint(x::Real, y::Real, allpoints::Vector{VoronoiPoint})
    p = VoronoiPoint(x, y)
    nearestpoint =
		allpoints[findmin([hypot(x-q.x, y-q.y) for q ∈ allpoints])[2]]
    
    z = perpbisector(p, nearestpoint)[1]
    q = nearestpoint
    reversedirection = false
    while true
        push!(p.neighbours, q)
        r = findnextpoint(p, q, z, reversedirection)

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

# ╔═╡ 11cd1d8b-6c81-4b15-b0ef-544bd477baed
md"""
This provides the majority of the heavy lifting for the algorithm, but one final small function `voronoipoints` is required to get from lists of coordinates to a list of `VoronoiPoint`s with all of the neighbours correctly calculated. I begin with the first point with its only neighbour being `VoronoiPoint(Inf,Inf)`.
```julia
points = [VoronoiPoint(xs[1],ys[1],[VoronoiPoint(Inf,Inf)])]
```
Then, one by one, each point is added to the list.
```julia
for i ∈ 2:length(xs)
    push!(points,addpoint(xs[i],ys[i],points))
end
```
In theory, this works, but in practice, one small alteration needs to be made. Although the coordinates of the points from the input are given as integers, calculating the perpendicular bisectors and circumcentres results in non-integer values and inevitable rounding errors, and then the `while` loop in `addpoint` has a tendency to get stuck in an infinite loop bouncing between two points `q` as `z` is inaccurately calculated.

However, there is a fix to this, and that is using `Rational`s, which is a data type storing rational numbers exactly, provided that the numerator and denominator can be stored exactly. Looking back at the `perpbisector` and `circumcentre` functions, I note that they involve only addition, subtraction, multiplication, and division, so rational inputs will guarantee rational outputs. Hence, by turning the integer coordinates into `Rational`s, rounding errors can be removed entirely. It's no wonder that the Ancient Greeks liked them so much!

An issue with using `Rational`s is that with larger input sizes the numerators and denominators only get bigger and bigger, and this can quickly overcome the limit of 2⁶³ - 1, the largest integer storable in the standard `Int64` format. Julia has another numeric type to deal with this problem though, which is `BigInt`, which can store arbitrarily large integers at the cost of more memory. Therefore, whatever form they come in, I convert the `xs` and `ys` to `Rational{BigInt}` form before passing them to `addpoint` in order to mitigate any rounding/overflow errors.
"""

# ╔═╡ 1883f53f-dc01-4eda-9ea6-a1d27bf17cdb
function voronoipoints(xs::Vector{T}, ys::Vector{T}) where T <: Real
	xs, ys = Rational{BigInt}.(xs), Rational{BigInt}.(ys)
    points = [VoronoiPoint(xs[1],ys[1],[VoronoiPoint(Inf,Inf)])]
    for i ∈ 2:length(xs)
        push!(points,addpoint(xs[i],ys[i],points))
    end
    return points
end

# ╔═╡ cf3ddbb7-7a8c-4f4f-8970-c61fffe5f2b7
md"""
The data `xs` and `ys` result in the following list of `VoronoiPoint`s:
"""

# ╔═╡ 4b153157-0ba1-4042-bea9-904e946a6ca2
points = voronoipoints(xs,ys)

# ╔═╡ bbe2a7ab-24aa-4ebb-9323-a10cb4739f03
md"""
I can also look to see that the lists of neighbours are filled in for each point.
"""

# ╔═╡ b63bd719-a709-4a10-be7a-ac075d3ff3c4
points[1].neighbours

# ╔═╡ 6977e1e5-50f0-4da2-9acc-877d4140fa7c
points[12].neighbours

# ╔═╡ 86b670fb-6a4c-406c-abdd-e9e81c460c57
md"""
### Plotting the Voronoi diagram
This achieves my goal of storing a Voronoi diagram in memory efficiently and in a way that can be analysed, as I will look at later. However, a Voronoi diagram is more than an abstract mathematical object; it is a way of visualising data, and so I feel it is necessary to be able to turn this into a actual diagram.

Firstly, I calculate the points with `voronoipoints`, which gives all the data needed to draw the diagram. I also choose a list of colours as before.
```julia
points = voronoipoints(xs,ys)
m = length(xs)
colours = distinguishable_colors(m, lchoices = 50:5:100)
```

From each point, I will calculate the vertices of the polygon defining the region of points closest to it, and use them to create a `Shape` object, which is a type from the package `Plots` used for creating polygons. These will be stored in a vector `polygons`, which I need to create before I start looping over each point.
```julia
polygons = Shape[]
```

Now, for each point `p`, I let `n` be the number of neighbours, and start a list `vertices` to keep track of the vertices of the polygon. In this case, there is no need to use `BigInt`s, so I will stick to the `Rational{Int64}` type to be more memory efficient.
```julia
n = length(p.neighbours)
vertices = Tuple{Rational{Int64}, Rational{Int64}}[]
```

For each neighbour, I need to add the circumcentre between `p`, it, and the next neighbour into the list of vertices.
```julia
q,r = p.neighbours[j], p.neighbours[mod(j+1,1:n)]
push!(vertices,Tuple(circumcentre(p,q,r)))
```

However, special treatment is needed for points whose polygons extend to infinity, since I will have to add more vertices along the border of the diagram such that the shape fills the space fully. This I do by finding the lines of the semi-infinite edges in the form ``\mathbf{x} + t \mathbf{v}``, and finding the values of ``t`` where it intersects the each of the lines defining the edges of the diagram. Since the midpoint of the two points either side of the edge is on the line and also within the bounds of the diagram, I take this to be ``\mathbf{x}``. For the infinite edge at the end of the list of neighbours, this looks like:
```julia
x, v = perpbisector(p.neighbours[n-1],p)
x, v = Rational{Int64}.(x), Rational{Int64}.(v)
tvals = [-x[2]/v[2], (1000-x[1])/v[1], (1000-x[2])/v[2], -x[1]/v[1]]
```

with `tvals` being the values of `t` where the line intersects:
- `y = 0` (bottom edge), at `t = -x[2]/v[2]`
- `x = 1000` (right edge), at `t = (1000-x[1])/v[1]`
- `y = 1000` (top edge), at `t = (1000-x[2])/v[2]`
- `x = 0` (left edge), at `t = -x[1]/v[1]`

Then, I find which is the minimal positive value, and add that vertex to the list.
```julia
t = minimum(tvals[tvals .> 0])
push!(vertices,Tuple(x + t*v))
```

I repeat this for the other semi-infinite edge. Since this gives me two values for each of `x`, `v`, `t`, `tvals`, I use subscripts to differentiate between them (`t₁`, `v₂`, etc.)


This leaves only one possibility for where vertices may be missing, which is in the corners. To find which corners I need to add, first I calculate the number of corners I need, which is the difference between the indices of `t₂` in `t₂vals` and `t₁` in `t₁vals` modulo 4.
```julia
t₁index = findfirst(==(t₁),t₁vals)
t₂index = findfirst(==(t₂),t₂vals)
indexdifference = mod(t₂index - t₁index,4)
```

As I know which indices correspond to which edges, I work around from the edge that t₁index corresponds to fill in each of the corners on the way to the edge that t₂index corresponds to.
```julia
corners = [(0,0), (1000,0), (1000,1000), (0,1000)]
for j ∈ 1:indexdifference
    push!(vertices,corners[mod(t₁index+j, 1:4)])
end
```

I have now ensured that every polygon has all of the vertices it should.
```julia
push!(polygons, Shape(vertices))
```

I combine this all together, plot the shapes as well as black dots for the points, and add an option for naming the points as shown in the Cambridge colleges example at the start of this document, which results in the `voronoi` function.
"""

# ╔═╡ d319f1c6-c329-4148-95c2-51e8814bcb56
function voronoi(xs::Vector{T}, ys::Vector{T};
		names::Vector{String} = String[]) where T <: Real
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
            t₁vals =
				[-x₁[2]/v₁[2], (1000-x₁[1])/v₁[1], (1000-x₁[2])/v₁[2], -x₁[1]/v₁[1]]
            t₁ = minimum(t₁vals[t₁vals .> 0])
            push!(vertices,Tuple(x₁ + t₁*v₁))

            x₂, v₂ = perpbisector(p,p.neighbours[2])
            x₂, v₂ = Rational{Int64}.(x₂), Rational{Int64}.(v₂)
            t₂vals =
				[-x₂[2]/v₂[2], (1000-x₂[1])/v₂[1], (1000-x₂[2])/v₂[2], -x₂[1]/v₂[1]]
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
    return scatter!(
		diagram,
		xs,
		ys,
		c = :black,
		markersize = 2,
		label = false
	)
end

# ╔═╡ 1520465f-d0f8-43b4-bb07-3daaa8c3e715
begin
	namescam, xscam, yscam = getpoints("cambridgecolleges.txt",true)
	voronoi(xscam, yscam; names = namescam)
end

# ╔═╡ a278f976-7446-4c0a-8026-00ac80343759
md"""
Trying it out on the sample data gives exactly the diagram I hoped for:
"""

# ╔═╡ bb9e1fc6-0ff6-46ce-aae7-9926841e6917
voronoi(xs,ys)

# ╔═╡ 19d2d573-0857-456e-bd5b-e52962ce0e50
md"""
In comparison to the other two methods, the diagram is much cleaner with the black outlines to the polygons, as well as having the advantage of memory efficiency and accessibility of its data.
"""

# ╔═╡ cdc7af5b-abcf-4b65-8a7c-274ad64a4bd3
md"""
## The distribution of the number of edges of Voronoi polygons
The `voronoipoints` function gives the means to analyse the Voronoi diagram which the other two functions couldn't. I will put this to use by looking into the distribution of the number of edges of Voronoi polygons.

First, I will consider the distribution for `n` points uniformly randomly distributed in the plane. To try to avoid collinear points and quadripoints, I sample them from ``{0, \frac{1}{n}, \frac{2}{n}, ..., 10}``, although this has the undesirable side-effect of slowing down the calculations as the denominators get larger.
```julia
voronoipoints(rand(0:(1//n):10, n), rand(0:(1//n):10, n))
```

I will ignore any polygons extending to infinity, only counting those which are bounded, and hence counting the number of neighbours suffices to count the edges of the polygon
```julia
neighbourcount = broadcast(
	p -> pos(p.neighbours[1]) == [Inf, Inf] ? 0 : length(p.neighbours), points)
```

I then plot a bar graph from these counts. This is then returned to complete the `voronoidistribution` function.
"""

# ╔═╡ f464f35c-0d4d-4d70-9632-6a09b1928695
function voronoidistribution(points::Vector{VoronoiPoint})
    neighbourcount = broadcast(
		p -> pos(p.neighbours[1]) == [Inf, Inf] ? 0 : length(p.neighbours), points)

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

# ╔═╡ 03348ff9-e422-4908-bd27-db4257511635
md"""
Four samples with `n = 1000` points are shown below, along with an example illustrating a Voronoi diagram with 1000 points sampled in this way:
"""

# ╔═╡ 2c7a67e0-3ead-4988-9633-db0ad673b0a6
n = 1000

# ╔═╡ 80360e43-0038-40b3-ae9c-28ad88959a97
voronoi(rand(1:100//n:1000, n),rand(1:100//n:1000, n))

# ╔═╡ 716d84bf-0271-4f0c-a38f-3cf265dcc99f
plot(
	voronoidistribution(voronoipoints(rand(0:(1//n):10, n), rand(0:(1//n):10, n))),
	voronoidistribution(voronoipoints(rand(0:(1//n):10, n), rand(0:(1//n):10, n))),
	voronoidistribution(voronoipoints(rand(0:(1//n):10, n), rand(0:(1//n):10, n))),
	voronoidistribution(voronoipoints(rand(0:(1//n):10, n), rand(0:(1//n):10, n))),
	layout = (2,2)
)

# ╔═╡ 2939781c-0c22-4d10-9aa6-2218b00c4705
md"""
Most common here are hexagons, with pentagons just behind, and heptagons in third place. This distribution mirrors the results of Tanemura in *Statistical Distributions of Poisson Voronoi Cells in Two and Three Dimensions*, in particular [this figure](https://www.semanticscholar.org/paper/Statistical-Distributions-of-Poisson-Voronoi-Cells-Tanemura/c7a539e69a36b4501ab2a763de34c5d0c17c465e/figure/10), although the uniformly random sampling is exchanged for the slightly different Poisson point process.

I will now look at the number of edges that a Voronoi diagram has when the points are more regularly arranged. I start with a lattice, either square or hexagonal, with the ``\frac{6}{7}`` used as a rational approximation of ``\frac{\sqrt{3}}{2}`` to make the hexagonal lattice approximately equilateral. I then apply some normally distributed randomness with standard deviation `σ` to each point, rounded off to keep the coordinates rational. Then, I generate bar graphs using `voronoidistribution` as before.
"""

# ╔═╡ 0ebcb0f4-159a-4f12-ba9d-f9887762b6e3
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

# ╔═╡ 86663fe9-e192-4876-a61f-22e7647d8abe
md"""
The standard deviations that I have chosen to sample with are `1//1`, `1//2`, `1//5`, and `1//10`:
"""

# ╔═╡ 08d69e9e-958e-4feb-adb8-9dd9019b2bf1
σlist = [1//1, 1//2, 1//5, 1//10]

# ╔═╡ 11949d3b-86cc-4969-b56e-1096f1a102b0
md"""
For the square lattice, a sample is:
"""

# ╔═╡ 1bf7c58c-813a-4a21-a667-46a2e0758616
plot(
	[randomlattice(:square, 30, σ) for σ ∈ σlist]...,
	title = hcat(["σ = $σ" for σ ∈ σlist]...),
	layout = (2,2)
)

# ╔═╡ 269b4fab-c944-425e-9cc1-7f43b03d9505
md"""
And for the hexagonal lattice, with the same standard deviations:
"""

# ╔═╡ 2e5d4be6-53d9-46b0-a5f4-29be3bd55142
plot(
	[randomlattice(:hexagonal, 30, σ) for σ ∈ σlist]...,
	title = hcat(["σ = $σ" for σ ∈ σlist]...),
	layout = (2,2)
)

# ╔═╡ 74dcc761-2448-4d74-af28-756fa473f3ea
md"""
In the perfect square lattice, all of the regions would be squares, although this is misleading, as they all meet at quadripoints, so each actually has 8 neighbours. Even with a small amount of randomness added, the distribution looks broadly similar to that of uniformly randomly chosen points, with the most notable difference being that the proportion of hexagons increases slightly, and the proportion of pentagons decreases slightly as the pattern becomes more regular with lower `σ`.

In contrast, starting with a hexagonal lattice, most of the regions become hexagons by the time that the standard deviation has come down to `1//5`, and almost all are when `σ = 1//10`. I interpret this as an illustration of the greater stability of the hexagonal lattice over the square lattice, which leads to its greater prevalence in nature, for example in honeycomb, or the Giant's Causeway.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
CSV = "~0.8.5"
Colors = "~0.12.8"
Plots = "~1.20.0"
PlutoUI = "~0.7.9"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c3598e525718abcc440f69cc6d5f60dda0a1b61e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.6+5"

[[CSV]]
deps = ["Dates", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode"]
git-tree-sha1 = "b83aa3f513be680454437a0eee21001607e5d983"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.8.5"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "e2f47f6d8337369411569fd45ae5753ca10394c6"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.0+6"

[[ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random", "StaticArrays"]
git-tree-sha1 = "ed268efe58512df8c7e224d2e170afd76dd6a417"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.13.0"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "344f143fa0ec67e47917848795ab19c6a455f32c"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.32.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[DataAPI]]
git-tree-sha1 = "ee400abb2298bd13bfc3df1c412ed228061a2385"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.7.0"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "4437b64df1e0adccc3e5d1adbc3ac741095e4677"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.9"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "92d8f9f208637e8d2d28c664051a00569c01493d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.1.5+1"

[[Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b3bfd02e98aedfa5cf885665493c5598c350cd2f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.10+0"

[[FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "LibVPX_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "3cc57ad0a213808473eafef4845a74766242e05f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.3.1+4"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "35895cf184ceaab11fd778b4590144034a167a2f"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.1+14"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "cbd58c9deb1d304f5a245a0b7eb841a2560cfec6"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.1+5"

[[FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "dba1e8614e98949abfa60480b13653813d8f0157"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.5+0"

[[GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "182da592436e287758ded5be6e32c406de3a2e47"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.58.1"

[[GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "d59e8320c2747553788e4fc42231489cc602fa50"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.58.1+0"

[[GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "58bcdf5ebc057b085e58d95c138725628dd7453c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.1"

[[Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "7bf67e9a481712b3dbe9cb3dac852dc4b1162e02"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+0"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "44e3b40da000eab4ccb1aecdc4801c040026aeb5"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.13"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[IterTools]]
git-tree-sha1 = "05110a2ab1fc5f932622ffea2a003221f4782c18"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.3.0"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "81690084b6198a2e1da36fcfda16eeca9f9f24e4"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.1"

[[JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d735490ac75c5cb9f1b00d8b5509c11984dc6943"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.0+0"

[[LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[LaTeXStrings]]
git-tree-sha1 = "c7f1c695e06c01b95a67f0cd1d34994f3e7db104"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.2.1"

[[Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "a4b12a1bd2ebade87891ab7e36fdbce582301a92"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.6"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[LibVPX_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "12ee7e23fa4d18361e7c2cde8f8337d4c3101bc7"
uuid = "dd192d2f-8180-539f-9fb4-cc70b1dcf69a"
version = "1.10.0+0"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "761a393aeccd6aa92ec3515e428c26bf99575b3b"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+0"

[[Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "340e257aada13f95f98ee352d316c3bed37c8ab9"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.3.0+0"

[[Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "0fb723cd8c45858c22169b2e42269e53271a6df7"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.7"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "4ea90bd5d3985ae1f9a908bd4500ae88921c5ce7"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.0"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7937eda4681660b4d6aeeecc2f7e1c81c8ee4e2f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+0"

[[OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "15003dcb7d8db3c6c857fda14891a539a8f2705a"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.10+0"

[[Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "bfd7d8c7fd87f04543810d9cbd3995972236ba1b"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "1.1.2"

[[Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "501c20a63a34ac1d015d5304da0e645f42d91c9f"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.0.11"

[[Plots]]
deps = ["Base64", "Contour", "Dates", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs"]
git-tree-sha1 = "e39bea10478c6aff5495ab522517fae5134b40e3"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.20.0"

[[PlutoUI]]
deps = ["Base64", "Dates", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "Suppressor"]
git-tree-sha1 = "44e225d5837e2a2345e69a1d1e01ac2443ff9fcb"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.9"

[[PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "cde4ce9d6f33219465b55162811d8de8139c0414"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.2.1"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "ad368663a5e20dbb8d6dc2fddeefe4dae0781ae8"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+0"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[RecipesBase]]
git-tree-sha1 = "b3fb709f3c97bfc6e948be68beeecb55a0b340ae"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.1.1"

[[RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "2a7a2469ed5d94a98dea0e85c46fa653d76be0cd"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.3.4"

[[Reexport]]
git-tree-sha1 = "5f6c21241f0f655da3952fd60aa18477cf96c220"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.1.0"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "a3a337914a035b2d59c9cbe7f1a38aaba1265b02"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.6"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "885838778bb6f0136f8317757d7803e0d81201e4"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.9"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StatsAPI]]
git-tree-sha1 = "1958272568dc176a1d881acb797beb909c785510"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.0.0"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "fed1ec1e65749c4d96fc20dd13bea72b55457e62"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.9"

[[StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "000e168f5cc9aded17b6999a560b7c11dda69095"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.0"

[[Suppressor]]
git-tree-sha1 = "a819d77f31f83e5792a76081eee1ea6342ab8787"
uuid = "fd094767-a336-5f1f-9728-57cf17d0bbfb"
version = "0.2.0"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "d0c690d37c73aeb5ca063056283fde5585a41710"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.5.0"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll"]
git-tree-sha1 = "2839f1c1296940218e35df0bbb220f2a79686670"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.18.0+4"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "cc4bf3fdde8b7e3e9fa0351bdeedba1cf3b7f6e6"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.0+0"

[[libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "acc685bcf777b2202a904cdcb49ad34c2fa1880c"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.14.0+4"

[[libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7a5780a0d9c6864184b3a2eeeb833a0c871f00ab"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "0.1.6+4"

[[libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "c45f4e40e7aafe9d086379e5578947ec8b95a8fb"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+0"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d713c1ce4deac133e3334ee12f4adff07f81778f"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2020.7.14+2"

[[x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "487da2f8f2f0c8ee0e83f39d13037d6bbf0a45ab"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.0.0+3"

[[xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╟─814a424a-96c4-4449-b002-f2e3122cb56d
# ╟─26bf6d61-25e8-4558-97ea-72185b7dc963
# ╟─a1f023ab-e2ab-4d74-8067-e364ddeaa7ed
# ╠═1520465f-d0f8-43b4-bb07-3daaa8c3e715
# ╟─e9845cba-d61a-4150-9698-6dffbdde3138
# ╟─2b2f564c-03f1-4da0-941e-c08bff8203fc
# ╠═d66df1f3-c14a-440b-8148-7f5daa006f7c
# ╟─3683349f-55da-4725-937c-882d620261ac
# ╠═00f99f29-fd88-4bdd-875a-83e892cf4182
# ╟─66f26cb1-958e-44e1-8ff2-0e65065347cd
# ╠═d7e145f0-afd7-4f7b-a570-a20f54444c06
# ╟─fa9cce06-5c0d-46d8-82a8-110777450737
# ╠═bff18246-4ea2-43c0-9dca-69e855f06b7d
# ╟─a5bae7fe-6bd8-49f8-9ccb-3567c4dceeee
# ╠═2c21b237-c4b7-4de2-b0ce-287bdf252081
# ╟─20a6f5d1-1df1-402f-bdb0-770e373a2caf
# ╠═04f8030e-a838-4e32-91c5-af63b50b8ef2
# ╠═16ee482f-2d14-4fa4-84c4-fb02e29e4e5f
# ╟─c7ce5d31-c823-433e-90c7-474e5c64a25e
# ╠═0ecd4b67-aee6-4dfb-94e5-7cc8cae0c01d
# ╟─6ae8754a-9fb3-43a1-adcc-42411be63467
# ╠═ac20813e-57ec-4f40-bbaa-eeed7557f2f5
# ╟─6f1c21bc-2803-4f10-ae1a-47fa6a883f19
# ╟─5619eeaa-d0ae-4752-987a-abc6b9236725
# ╟─35546877-09ce-4294-acd3-6150a2b3637d
# ╟─f50845c7-45b1-46a0-9c7f-35303080b036
# ╟─26dfe1aa-9e61-46dd-953b-3164c4470458
# ╟─7c392155-a7b1-4dfb-b6bb-bb52e8f071f7
# ╟─406599de-7141-4c59-a294-bffb79973098
# ╟─c5553b17-c7a6-4c3d-92e2-9dff80c28867
# ╟─98e6d6c3-1623-403a-b066-bdd280aaee4e
# ╟─283f5b27-6bd6-4cc2-98b7-d72377505626
# ╟─74fe0258-6c8e-4383-9aad-ffcb890e9612
# ╟─4ff3a96d-14dd-4af8-820a-bbb30c3fca15
# ╠═7d80b224-03ad-4034-af2d-7975b6e0e7a9
# ╟─26502d5d-54c6-4d57-9be4-5e8971635560
# ╠═8c07108a-49e0-4ef3-873c-e5d6576c99cc
# ╠═00d09735-0b30-465c-9c39-81209d36265f
# ╟─ada943f1-077e-4fa0-9024-915e7d23c2e2
# ╠═25c8d94d-0393-4382-bbf4-500135b12f25
# ╟─d3b2bb40-359e-4696-a74d-030afcf4f9c7
# ╠═4b3fc852-caae-4b8d-8582-f308a9a255ca
# ╟─fc64f356-5550-4d43-8564-0d2002dc8316
# ╠═9b35606b-9175-40a5-99e8-62251e72f3a4
# ╟─f2b1cc32-370f-465c-bab8-15365cf5de69
# ╠═951bea47-8e23-45f9-b935-882566d3fdc3
# ╟─3ffacdd0-510f-4ef5-b934-4ff15b536b7c
# ╠═c6ff22c9-16d8-494a-8b82-997a61ecf38c
# ╟─8f9286e4-f49d-4227-9611-9793f484d5dd
# ╟─3acc9ae8-c107-4434-b72d-590a1abc8130
# ╟─e39cf938-c946-4a65-bb20-3c5c73bb0ef2
# ╠═aee35cf6-8ef4-4550-b65f-a546416d642f
# ╟─11cd1d8b-6c81-4b15-b0ef-544bd477baed
# ╠═1883f53f-dc01-4eda-9ea6-a1d27bf17cdb
# ╟─cf3ddbb7-7a8c-4f4f-8970-c61fffe5f2b7
# ╠═4b153157-0ba1-4042-bea9-904e946a6ca2
# ╟─bbe2a7ab-24aa-4ebb-9323-a10cb4739f03
# ╠═b63bd719-a709-4a10-be7a-ac075d3ff3c4
# ╠═6977e1e5-50f0-4da2-9acc-877d4140fa7c
# ╟─86b670fb-6a4c-406c-abdd-e9e81c460c57
# ╠═d319f1c6-c329-4148-95c2-51e8814bcb56
# ╟─a278f976-7446-4c0a-8026-00ac80343759
# ╠═bb9e1fc6-0ff6-46ce-aae7-9926841e6917
# ╟─19d2d573-0857-456e-bd5b-e52962ce0e50
# ╟─cdc7af5b-abcf-4b65-8a7c-274ad64a4bd3
# ╠═f464f35c-0d4d-4d70-9632-6a09b1928695
# ╟─03348ff9-e422-4908-bd27-db4257511635
# ╠═2c7a67e0-3ead-4988-9633-db0ad673b0a6
# ╠═80360e43-0038-40b3-ae9c-28ad88959a97
# ╠═716d84bf-0271-4f0c-a38f-3cf265dcc99f
# ╟─2939781c-0c22-4d10-9aa6-2218b00c4705
# ╠═0ebcb0f4-159a-4f12-ba9d-f9887762b6e3
# ╟─86663fe9-e192-4876-a61f-22e7647d8abe
# ╠═08d69e9e-958e-4feb-adb8-9dd9019b2bf1
# ╟─11949d3b-86cc-4969-b56e-1096f1a102b0
# ╠═1bf7c58c-813a-4a21-a667-46a2e0758616
# ╟─269b4fab-c944-425e-9cc1-7f43b03d9505
# ╠═2e5d4be6-53d9-46b0-a5f4-29be3bd55142
# ╟─74dcc761-2448-4d74-af28-756fa473f3ea
# ╟─34039790-f50e-11eb-0b84-25496cba179e
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
