### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 42963dd1-8295-4bf3-97ad-2132946ebf35
using NLsolve

# ╔═╡ 5103ba48-9744-4a15-86a9-28298de90338
using Plots

# ╔═╡ 05d2b08e-ebeb-4c22-b2a1-b5b70f400216
using DifferentialEquations

# ╔═╡ 9088e0a6-4e96-4d68-a851-668e753ead58
begin
	using PlutoUI
	PlutoUI.TableOfContents(title = "Contents")
end

# ╔═╡ f52dbad2-fa73-11eb-2071-8521afcace5b
md"""
# Lagrange points
"""

# ╔═╡ c08f5b42-b111-4eb7-84a3-d80157787b02
md"""
## Objectives
- Find the Lagrange points of a system of two large masses numerically _**using the package `NLsolve`**_
- Determine the stability of the points by numerically simulating a third body _**using the package `DifferentialEquations`**_
"""

# ╔═╡ ba5d8c7d-0df5-434b-99ff-696116f9e222
md"""
## What are Lagrange points?

Let ``M_1`` and ``M_2`` be two large masses orbiting each other, with ``M_1`` the larger of the two. These induce gravitational pulls on each other as well as any other bodies that may be in the vicinity.

Now let ``m`` be a much smaller mass. This creates an instance of the three-body problem, but since ``M_1`` are much larger than ``m``, assume that the gravitational effect of ``m`` on each of ``M_1`` and ``M_2`` is negligible, and ignore it. This setup is known as the restricted three-body problem, where in an appropriate rotating frame of reference, with the assumption that the distance between them is constant, ``M_1`` and ``M_2`` are fixed, with ``m`` orbiting around them.

Within this system, there are five points, fixed in the rotating frame of reference, where the net force on ``m`` is zero, meaning that it could theoretically stay in orbit in this position indefinitely. These are the Lagrange points, numbered ``L_1`` to ``L_5``. In this case study, I will approximately find their positions, and determine the stability of the orbit of ``m`` at each of them.
"""

# ╔═╡ 9aa47484-bbb7-4990-a5b5-f57f208bbb5b
begin
	illustration = plot(
		(θ -> (cos(θ) - 0.2, sin(θ))).(0:0.1:2π),
		linestyle = :dash,
		linecolor = :white,
		linewidth = 1,
		bg = :black,
		ticks = false,
		showaxis = false,
		legend = false
	)
	
	plot!(
		illustration,
		Shape([(0.8, -0.07),(0.82,-0.1),(0.78,-0.1)]),
		c = :white,
		markerstrokewidth = 0
	)
	
	scatter!(
		illustration,
		[(0.438,0),(1.271,0),(-1.083,0),(0.3,0.866),(0.3,-0.866)],
		ann = [
			(0.538 , 0.1   , "L₁"),
			(1.171 , 0.1   , "L₂"),
			(-0.983, 0.1   , "L₃"),
			(0.2   , 0.766 , "L₄"),
			(0.2   , -0.766, "L₅")
			],
		markercolor = :white,
		markersize = 3
	)
	
	scatter!(
		illustration,
		[(-0.2,0), (0.8, 0)],
		markercolor = [:yellow, :aqua],
		markersize = [10, 4],
		markerstrokewidth = 0
	)
end

# ╔═╡ 00786027-f20a-4aa8-8d78-493c5890df7c
md"""
An excellent document detailing the positions and stability of the Lagrange points is [The Lagrange Points](https://wmap.gsfc.nasa.gov/media/ContentMedia/lagrange.pdf) written by Neil J. Cornish as part of a NASA program to launch [a probe](https://en.wikipedia.org/wiki/Wilkinson_Microwave_Anisotropy_Probe) into orbit at the second Lagrange point ``L_2`` of the Earth-Sun system. I will make use of several of the results in these notes throughout this case study, and they also serve as a source for much of the mathematics that I use.
"""

# ╔═╡ b25c680f-f667-4434-aabe-64bbd32e7a4f
md"""
## Finding the Lagrange points
To start with, I need to find the frame of reference which I want to work in. This will be rotating around the centre of mass of ``M_1`` and ``M_2``, with angular velocity ``\Omega``. First I let ``\mathbf{r}_1`` and ``\mathbf{r}_2`` be the positions of ``M_1`` and ``M_2`` respectively in this frame of reference. Then, ``M_1`` orbits the centre of mass at a distance of ``\alpha | \mathbf{r}_1 - \mathbf{r}_2 |``, where ``\alpha = \frac{M_2}{M_1 + M_2}``, and the centripetal force from this orbit must exactly be the gravitational force that ``M_2`` exerts on ``M_1``:
```math
M_1 \Omega^2 \left( \frac{M_2}{M_1 + M_2} \right) | \mathbf{r}_1 - \mathbf{r}_2 |
= \frac{G M_1 M_2}{| \mathbf{r}_1 - \mathbf{r}_2 |^2}
```

which rearranges to give:
```math
\Omega^2 | \mathbf{r}_1 - \mathbf{r_2} |^3 = G(M_1 + M_2)
```

Without loss of generality, I can choose units of length, mass, and time, such that ``| \mathbf{r}_1 - \mathbf{r}_2 | = 1`` and ``G = 1``, so:
```math
\Omega = \sqrt{M_1 + M_2}
```

Now that I know the frame of reference, I let ``\mathbf{r}`` be the position of ``m``, and consider the forces acting on it, including the fictitious forces caused by the rotating frame of reference:
- The gravitational force of ``M_1`` is `` - \frac{M_1 m}{| \mathbf{r} - \mathbf{r}_1 |^3}(\mathbf{r} - \mathbf{r}_1) `` (as ``G = 1``)
- The gravitational force of ``M_2`` is `` - \frac{M_2 m}{| \mathbf{r} - \mathbf{r}_2 |^3}(\mathbf{r} - \mathbf{r}_2) ``
- The Coriolis force is `` - 2 m \mathbf{\Omega} \times \dot{\mathbf{r}} ``, where ``\mathbf{\Omega} = \Omega \hat{\mathbf{z}}`` is the angular velocity vector
- The centrifugal force is `` - m \mathbf{\Omega} \times ( \mathbf{\Omega} \times \mathbf{r} ) ``
- The Euler force is `` -  m \dot{\mathbf{\Omega}} \times \mathbf{r}``, but ``\mathbf{\Omega}`` is constant in this model, so this force is zero

I now let ``\mathbf{r} = x \hat{\mathbf{x}} + y \hat{\mathbf{y}}``, with the origin at the centre of mass of ``M_1`` and ``M_2``, and the two large bodies aligned in the direction of ``\hat{\mathbf{x}}``, lying at ``\mathbf{r}_1 = (- \alpha, 0)`` and ``\mathbf{r}_2 = (1 - \alpha, 0)``. Then, the acceleration of the small body ``m`` is:
"""

# ╔═╡ 7ab49c23-1766-454c-8265-295a20422e33
md"""
```math
\begin{align}

\ddot{\mathbf{r}} &= \frac{1}{m} \left[
- \frac{M_1 m}{| \mathbf{r} - \mathbf{r}_1 |^3}(\mathbf{r} - \mathbf{r}_1) 
- \frac{M_2 m}{| \mathbf{r} - \mathbf{r}_2 |^3}(\mathbf{r} - \mathbf{r}_2)
- 2 m \mathbf{\Omega} \times \dot{\mathbf{r}}
- m \mathbf{\Omega} \times ( \mathbf{\Omega} \times \mathbf{r} )
\right] \\ \\

&= 
- \frac{(M_1 + M_2) (1 - \alpha)}{\sqrt{ (x + \alpha)^2 + y^2 }^3}( (x + \alpha) \hat{\mathbf{x}} + y \hat{\mathbf{y}} )
- \frac{(M_1 + M_2) \alpha}{\sqrt{ (x + \alpha - 1)^2 + y^2 }^3}( (x + \alpha - 1) \hat{\mathbf{x}} + y \hat{\mathbf{y}} ) \\
&\quad - 2 \Omega ( \hat{\mathbf{z}} \times (\dot{x} \hat{\mathbf{x}} + \dot{y} \hat{\mathbf{y}}) )
- \Omega^2 ( \hat{\mathbf{z}} \times ( \hat{\mathbf{z}} \times (x \hat{\mathbf{x}} + y \hat{\mathbf{y}}) ) ) \\ \\

&= 
- \frac{\Omega^2 (1 - \alpha)}{\sqrt{ (x + \alpha)^2 + y^2 }^3}( (x + \alpha) \hat{\mathbf{x}} + y \hat{\mathbf{y}} )
- \frac{\Omega^2 \alpha}{\sqrt{ (x + \alpha - 1)^2 + y^2 }^3}( (x + \alpha - 1) \hat{\mathbf{x}} + y \hat{\mathbf{y}} ) \\
&\quad - 2 \Omega ( \dot{x} \hat{\mathbf{y}} - \dot{y} \hat{\mathbf{x}})
- \Omega^2 (- x \hat{\mathbf{x}} - y \hat{\mathbf{y}}) \\ \\

&= \left[ 
\Omega^2 x
- \frac{\Omega^2 (1 - \alpha) (x + \alpha)}{\sqrt{ (x + \alpha)^2 + y^2 }^3}
- \frac{\Omega^2 \alpha (x + \alpha - 1)}{\sqrt{ (x + \alpha - 1)^2 + y^2 }^3}
+ 2 \Omega \dot{y}
\right] \hat{\mathbf{x}} \\
&\quad \left[ 
\Omega^2 y
- \frac{\Omega^2 (1 - \alpha) y}{\sqrt{ (x + \alpha)^2 + y^2 }^3}
- \frac{\Omega^2 \alpha y}{\sqrt{ (x + \alpha - 1)^2 + y^2 }^3}
- 2 \Omega \dot{x}
\right] \hat{\mathbf{y}}

\end{align}
```
"""

# ╔═╡ 207ff5cd-2f24-4aa9-b816-ba476bbad45b
md"""
At a Lagrange point, ``x`` and ``y`` are constant in time, so both ``\dot{\mathbf{r}}`` and ``\ddot{\mathbf{r}}`` are zero. A common factor of ``\Omega^2`` cancels from each component, giving:

```math
x
- \frac{(1 - \alpha) (x + \alpha)}{\sqrt{ (x + \alpha)^2 + y^2 }^3}
- \frac{\alpha (x + \alpha - 1)}{\sqrt{ (x + \alpha - 1)^2 + y^2 }^3}
= 0
```
```math
y
- \frac{(1 - \alpha) y}{\sqrt{ (x + \alpha)^2 + y^2 }^3}
- \frac{\alpha y}{\sqrt{ (x + \alpha - 1)^2 + y^2 }^3}
= 0
```

As a vector equation, this is:
```math
\mathbf{F}(\mathbf{X}) = \mathbf{F}(x,y) = \begin{pmatrix}
x
- \frac{(1 - \alpha) (x + \alpha)}{\sqrt{ (x + \alpha)^2 + y^2 }^3}
- \frac{\alpha (x + \alpha - 1)}{\sqrt{ (x + \alpha - 1)^2 + y^2 }^3} \\
y
- \frac{(1 - \alpha) y}{\sqrt{ (x + \alpha)^2 + y^2 }^3}
- \frac{\alpha y}{\sqrt{ (x + \alpha - 1)^2 + y^2 }^3}
\end{pmatrix} = \mathbf{0} 
```

I will solve this equation numerically using the `NLsolve` package, which finds solutions for non-linear systems of equations such as these.
"""

# ╔═╡ e888671d-e2c0-4f65-a879-4b0222eb99c9
md"""
`NLsolve` requires a specific form of function as an input in order to work. I will be using `evalF!`, as shown below. The function must take two arguments, the first of which is to be modified within the function to take the value `F(X)`, where `X` is the second argument.

```julia
function evalF!(F, X)
	x, y = X
	F[1] = x -
		(1 - α)*(x + α)/√((x + α)^2 + y^2)^3 -
		α*(x + α - 1)/√((x + α - 1)^2 + y^2)^3
	F[2] = y -
		(1 - α)*y/√((x + α)^2 + y^2)^3 -
		α*y/√((x + α - 1)^2 + y^2)^3
end
```

To find each Lagrange point, I will need to choose a starting point for `NLsolve`, for which I will use some rough information about the five points' locations. As the two bodies ``M_1`` and ``M_2`` are at ``(-\alpha, 0)`` and ``(1 - \alpha, 0)`` respectively:
- ``L_1`` lies between the two bodies, so I will start its search at ``(0, 0)``
- ``L_2`` lies in line beyond the smaller body ``M_2``, so I will start its search at ``(1, 0)``
- ``L_3`` lies in line beyond the larger body ``M_1``, so I will start its search at ``(-1, 0)``
- ``L_4`` lies ahead in ``M_2``'s orbit, in this case anticlockwise, so I will start its search at ``(0, 1)``
- ``L_5`` lies behind in ``M_2``'s orbit, in this case clockwise, so I will start its search at ``(0, -1)``

I will also choose a range of values for `α`, and create a matrix `lagrangepoints` which will store the `x` and `y` positions of each of the five Lagrange points for each value of `α`.
"""

# ╔═╡ edf3a2bf-2e75-41a9-8f5e-4e96c987137c
αvals = 0.001:0.001:0.5

# ╔═╡ 3b290eb7-c8f9-4a53-9cd8-2b7a7808818f
nαvals = length(αvals)

# ╔═╡ 76b8b4fc-790a-422a-9226-5c25d89f46ea
lagrangepoints = zeros(Float64, nαvals, 10);

# ╔═╡ 4cddf611-8b43-4351-bb1d-08c29a75003f
md"""
Now I am ready to use `NLsolve`. For each value of `α`, I create the function `evalF!`, and input it into the `nlsolve` function five times, once with each of the five starting points. It requires a way of finding a gradient so that it can converge on the root, which in this instance I provide with the `autodiff` parameter. This tells `nlsolve` to find the gradient using automatic differentiation as provided by the `ForwardDiff` package, which will work well with my function as it is in terms of polynomials, quotients, and square roots. The output of `nlsolve` is a special type containing lots of data about the root-finding operation, but as I only want the root that it has found, I simply take the field `zero`, and save the value in `lagrangepoints` appropriately.
"""

# ╔═╡ afc3d520-d321-4102-8a55-5ea66bdfbedc
for i ∈ 1:nαvals
	α = αvals[i]
	
	function evalF!(F, X)
		x, y = X
		F[1] = x -
			(1 - α)*(x + α)/√((x + α)^2 + y^2)^3 -
			α*(x + α - 1)/√((x + α - 1)^2 + y^2)^3
		F[2] = y -
			(1 - α)*y/√((x + α)^2 + y^2)^3 -
			α*y/√((x + α - 1)^2 + y^2)^3
	end
	
	lagrangepoints[i,1:2 ] = nlsolve(evalF!, [ 0.0, 0.0], autodiff=:forward).zero
	lagrangepoints[i,3:4 ] = nlsolve(evalF!, [ 1.0, 0.0], autodiff=:forward).zero
	lagrangepoints[i,5:6 ] = nlsolve(evalF!, [-1.0, 0.0], autodiff=:forward).zero
	lagrangepoints[i,7:8 ] = nlsolve(evalF!, [ 0.0, 1.0], autodiff=:forward).zero
	lagrangepoints[i,9:10] = nlsolve(evalF!, [ 0.0,-1.0], autodiff=:forward).zero
	
end

# ╔═╡ ea3230da-c9e2-4e86-a36f-b17021b1dc72
md"""
Cornish provides positions of the Lagrange points (first order approximations for ``L_1``, ``L_2``, and ``L_3``, with ``\alpha \ll 1``) as follows:

|Lagrange Point|x|y|
|:---:|:---:|:---:|
|``L₁``|``1 - \left( \frac{\alpha}{3} \right)^\frac{1}{3}``|``0``|
|``L₂``|``1 + \left( \frac{\alpha}{3} \right)^\frac{1}{3}``|``0``|
|``L₃``|``- 1 - \frac{5}{12} \alpha``|``0``|
|``L₄``|``\frac{1}{2} - \alpha``|``\frac{\sqrt{3}}{2}``|
|``L₅``|``\frac{1}{2} - \alpha``|``-\frac{\sqrt{3}}{2}``|

To compare these to my own results, I will plot the `x` and `y` values for each that I have found numerically against the `x` and `y` values that Cornish predicts.
"""

# ╔═╡ a5cf0fb5-8146-4622-8bca-f6e86691aab1
plot(
	plot(αvals, [lagrangepoints[:,1 ], α -> 1 - ∛(α/3)]),
	plot(αvals, [lagrangepoints[:,2 ], α -> 0]),
	plot(αvals, [lagrangepoints[:,3 ], α -> 1 + ∛(α/3)]),
	plot(αvals, [lagrangepoints[:,4 ], α -> 0]),
	plot(αvals, [lagrangepoints[:,5 ], α -> - 1 - 5α/12]),
	plot(αvals, [lagrangepoints[:,6 ], α -> 0]),
	plot(αvals, [lagrangepoints[:,7 ], α -> 1/2 - α]),
	plot(αvals, [lagrangepoints[:,8 ], α -> (√3)/2]),
	plot(αvals, [lagrangepoints[:,9 ], α -> 1/2 - α]),
	plot(αvals, [lagrangepoints[:,10], α -> -(√3)/2]),
	linestyle = [:solid :dash],
	layout = (5,2),
	size = (600, 1000),
	label = ["numerical" "theoretical"],
	yticks = false,
	title = ["L₁ x" "L₁ y" "L₂ x" "L₂ y" "L₃ x" "L₃ y" "L₄ x" "L₄ y" "L₅ x" "L₅ y"]
)

# ╔═╡ b7acb521-51f1-47fa-b0ae-db0676d517e2
md"""
These plots show that the coordinates that I have found line up well with the theoretical locations (for small ``\alpha`` where there are first-order approximations). Although the ``y`` axes of the graphs are not shown (to avoid clutter), the errors seen in the ``y`` coordinate of ``L_4`` and ``L_5`` for small ``\alpha`` are of magnitude ``< 10^{-8}``, so I can safely dismiss them. Because of this, I can confidently say that the numerical values that I have found for the ``x``-coordinates of ``L_1``, ``L_2``, and ``L_3`` for larger ``\alpha`` are also reasonably accurate.
"""

# ╔═╡ 243aa0fb-6162-4fc5-b2f4-ac7a92a86c27
md"""
## Stability of the Lagrange points

Knowing where the Lagrange points are is one thing, but in order to use them their stability is also important. This is possible to do analytically (indeed Cornish does, although glossing over some heavy algebra), but instead I will look to simulate orbits of ``m`` using the package `DifferentialEquations`.
"""

# ╔═╡ 9c1cccd8-0bb2-46c8-a090-9eecae1bdc41
md"""
### Creating the simulation
First, I will need a function to calculate the acceleration of ``m`` given its position, velocity, and the parameters of the system, which are the two masses ``M_1`` and ``M_2``, their positions ``r₁`` and ``r₂``, and the angular velocity ``\Omega``. These I input as a vector of parameters `p`, since this will be the form needed by `DifferentialEquations` later.
"""

# ╔═╡ 964ee58d-7076-4649-b081-026d9652b0ef
function acceleration(r, v, p)
    M₁, M₂, r₁, r₂, Ω = p

    gravitational₁ = - ( M₁ / hypot((r - r₁)...)^3 ) .* (r - r₁)
    gravitational₂ = - ( M₂ / hypot((r - r₂)...)^3 ) .* (r - r₂)
    coriolis = - 2Ω .* [[0, -1] [1, 0]] * v
    centrifugal = (Ω^2) .* r
    return gravitational₁ + gravitational₂ + coriolis + centrifugal
end

# ╔═╡ 576706b3-ac7c-4d6d-93ef-3f3cc71f75f9
md"""
Simialar to `evalF!` above, `DifferentialEquations` expects a special form of function so that it can perform its calculations. It looks to solve an equation of the form
```math
\frac{d\mathbf{u}}{dt} = \mathbf{F}(\mathbf{u}, \mathbf{p}, t)
```

with ``\mathbf{p}`` a vector of parameters. The input function requires four inputs:
- The first input (`du` below) is a vector which will be overwritten with the value of ``\frac{d\mathbf{u}}{dt}`` when it is calculated (much like `NLsolve` requires)
- The second input (`u` below) is the value of ``\mathbf{u}``
- The third input (`p` below) is the vector of parameters ``\mathbf{p}``
- The fourth input (`t` below) is the time ``t``
To get my equations in this form, I let:
```math
\mathbf{u} = \begin{pmatrix} x \\ y \\ \dot{x} \\ \dot{y} \end{pmatrix}, \qquad \mathbf{p} = \begin{pmatrix} M_1 \\ M_2 \\ r_1 \\ r_2 \\ \Omega \end{pmatrix}
```

so that
```math
\frac{d\mathbf{u}}{dt} = \begin{pmatrix} \dot{x} \\ \dot{y} \\ \ddot{x} \\ \ddot{y} \end{pmatrix}
```

with ``\ddot{\mathbf{r}} = \ddot{x} \hat{\mathbf{x}} + \ddot{y} \hat{\mathbf{y}} `` calculated in terms of ``x``, ``y``, ``\dot{x}``, ``\dot{y}``, and the parameters in ``\mathbf{p}`` by `acceleration` above already. This equation is not time dependent, but `DifferentialEquations` still requires the function to have all four inputs.

The function that I have written implement to do this is `derivative!`:
"""

# ╔═╡ 1768e022-8e1a-4978-b6cd-f7612a9d3242
function derivative!(du, u, p, t)
    du[1] = u[3]
    du[2] = u[4]
    du[3], du[4] = acceleration(u[1:2], u[3:4], p)
end

# ╔═╡ 6c900df7-bec6-4f63-9af4-5a0c9e559598
md"""
After this, I need a function to simulate the motion of ``m`` for a given time period, with some input parameters and initial conditions.
- The initial conditions will be `r₀` and `v₀`, which are the initial position ``\mathbf{r}(0)`` and velocity ``\dot{\mathbf{r}}(0)`` of ``m``
- The parameters that I will be able to vary will be `α` and `M₁`, with all other parameters of the system derivable from just these two:
```julia
M₂ = M₁ * α/(1-α)

r₁ = [-α, 0]
r₂ = [1-α, 0]

Ω = √(M₁ + M₂)
```

Then, I need to call `DifferentialEquations` into action. I set up the problem with `ODEProblem`, inputting the function `derivative!`, the initial conditions, the time span, and the parameters:
```julia
ODEProblem(derivative!, vcat(r₀, v₀), (0.0, float(T)), [M₁, M₂, r₁, r₂, Ω])
```

Finally, I use the function `solve` from `DifferentialEquations` to solve the problem, returning the solution. Altogether, this makes up the function `simulate`:
"""

# ╔═╡ 34c1cd0f-b058-43ae-adb8-848268086742
function simulate(α, M₁, r₀, v₀, T)
    M₂ = M₁ * α/(1-α)

    r₁ = [-α, 0]
    r₂ = [1-α, 0]
	
    Ω = √(M₁ + M₂)

    return solve(ODEProblem(
			derivative!,
			vcat(r₀, v₀),
			(0.0, float(T)),
			[M₁, M₂, r₁, r₂, Ω]
		))
end

# ╔═╡ a15b48ee-154c-4199-a115-5a8bd09bd8f4
md"""
To see how well this is working, I put in the parameters of the Sun (``M_1``), Earth (``M_2``) and Moon (``m``) system (albeit in strange units, since I have set ``| \mathbf{r}_1 - \mathbf{r}_2 | = 1`` and ``G = 1``). I plot the resulting trajectory of the Moon over the period of one month with the Earth also plotted (size not to scale):
"""

# ╔═╡ 25f3c52b-1304-405f-b4e9-0e23b44414a2
let
	α = 3e-6 # dimensionless
	M₁ = 39 # AU³ G⁻¹ yr⁻²
	
	r₀ = [1.003, 0.0] # AU
	v₀ = [0.0, 0.215] # AU yr⁻¹
	
	T = 1/12 # yr
	
	diagram = plot(
		simulate(α, M₁, r₀, v₀, T),
		vars = (1,2),
		linecolor = :white,
		linewidth = 1,
		bg = :black,
		ticks = false,
		showaxis = false,
		legend = false,
		xlims = [0.995, 1.005],
		ylims = [-0.005, 0.005],
		size = (600, 600)
	)
	
	scatter!(
		diagram,
		[Tuple(r₀), (1-α,0)],
		markercolor = [:white, :aqua],
		markersize = [2, 4],
		markerstrokewidth = 0
	)
	
	diagram
end

# ╔═╡ 07e8b7ab-e089-4bde-8bd2-e19a4e4581fe
md"""
I am satisfied with this, although it is unlikely that there are negligible errors in the values I have used for the parameters of the system. Now I will look to test the stability of the Lagrange points using this simulation.

The function `trajectory` takes as inputs the two parameters `α` and `M₁`, the number `n` denoting the Lagrange point ``L_n`` from which the simulation will start, and the time `T` to run the simulation until. The optional argument `lims` allows me to manually change the region plotted to better fit the trajectory of `m`, and I also use it to shape the diagram such that distances are to scale.

The value of `α` actually used is taken from `αvals` as the smallest value greater than or equal to the input `α`. Then, the initial position is ``L_n`` as approximated earlier (with the error in its value from the numerical search providing a small perturbation as needed to test stability), and the initial velocity is zero. The trajectory is then plotted, along with markers for ``M_1`` (in yellow), ``M_2`` (in aqua), and the initial position of ``m`` (in white).
"""

# ╔═╡ 88ad767e-549e-47fa-8e50-8389400d7f31
function trajectory(α, M₁, n, T, lims = [2,1])
	i = findfirst(≥(α), αvals)
    simulatedtrajectory = simulate(
		αvals[i],
		M₁,
		lagrangepoints[i, (2n-1):2n],
		[0.0, 0.0],
		T
	)
	
	diagram = plot(
		simulatedtrajectory,
		vars = (1,2),
		linecolor = :white,
		linewidth = 1,
		bg = :black,
		ticks = false,
		showaxis = false,
		legend = false,
        xlims = [-lims[1],lims[1]],
        ylims = [-lims[2],lims[2]],
        size = Tuple(lims) .* round(Int64, 1200/sum(lims))
	)
	
	scatter!(
		diagram,
		[Tuple(simulatedtrajectory.u[1][1:2]), (-α,0), (1-α, 0)],
		markercolor = [:white, :yellow, :aqua],
		markersize = [2, 10, 4],
		markerstrokewidth = 0
	)
	
	return diagram
end

# ╔═╡ 3ec1dcbb-f493-4342-9a0c-23a866128979
md"""
As a first test, I look at ``L_1`` for `α = 0.1` and `M₁ = 1`:
"""

# ╔═╡ f8fd93ea-5277-4e32-bfaf-21ca14a668db
trajectory(0.1, 1, 1, 20)

# ╔═╡ 134b0cef-3701-47cd-a9c8-1b31b0893153
md"""
This is clearly unstable, with ``m`` going into orbit around ``M_2`` instead of staying at ``L_1``. I will now be able to generate many images of the same form to investigate the stability of the Lagrange points.
"""

# ╔═╡ 4d62b539-975a-4fe2-847c-83e3aa1eddf0
md"""
### The effect of `α` on stability
First, I will look at the effect of `α` on stability of the Lagrange points. Fixing `M₁ = 1` for the moment:
- ``L_1`` and ``L_2`` are clearly unstable for all values of `α`. From the few examples below, starting at ``L_1`` tends to result in a stable orbit around ``M_2``, while starting at ``L_2`` is more chaotic, and the orbit can stabilise at either ``M_1`` or ``M_2``.
"""

# ╔═╡ 090755ae-64f7-4984-b1f7-328dfc2984bd
plot(
	trajectory(0.01, 1, 1, 30),
	trajectory(0.01, 1, 2, 90),
	trajectory(0.03, 1, 1, 20),
	trajectory(0.03, 1, 2, 30),
	trajectory(0.1 , 1, 1, 20),
	trajectory(0.1 , 1, 2, 50),
	trajectory(0.3 , 1, 1, 20),
	trajectory(0.3 , 1, 2, 40),
	layout = (4,2),
	size = (900, 900),
	title =
		hcat([["L₁ for α = $α" "L₂ for α = $α"] for α ∈ [0.01, 0.03, 0.1, 0.3]]...)
)

# ╔═╡ 20a8a0f9-ad09-4e3d-ac67-b4fc9b4bcba9
md"""
- ``L_3`` is also unstable, although less so than ``L_1`` and ``L_2``, as the time needed to run the simulation in order to show instability is longer, especially for the smaller values of `α`. For larger `α`, ``m``  reamins in orbit, while for smaller `α` it seems to get thrown spiralling out of orbit.
"""

# ╔═╡ 5f4e3ef8-8ee6-4ca6-9b64-4b62a5d7238d
plot(
	trajectory(0.01, 1, 3, 200, [3,3]),
	trajectory(0.03, 1, 3, 150, [3,3]),
	trajectory(0.1 , 1, 3, 100, [3,3]),
	trajectory(0.3 , 1, 3, 80 , [3,3]),	
	layout = (2,2),
	size = (900, 900),
	title = hcat(["L₃ for α = $α" for α ∈ [0.01, 0.03, 0.1, 0.3]]...)
	)

# ╔═╡ e8b1d4ab-b449-4b6a-9a86-623134f52e73
md"""
- In constrast, ``L_4`` and ``L_5`` are stable for smaller values of `α`, specifically for `α = 0.01` and `α = 0.03` in the examples below (I have run them for `T = 5000` here, but `T` can be arbitrarily large without instability). Even for larger `α`, initial divergence is slower than ``L_1`` and ``L_2``, with the resulting trajectories very chaotic, not resulting in an orbit around either larger body.
"""

# ╔═╡ 2f9dbd3b-892a-4f68-b08d-4f793dd5652d
plot(
	trajectory(0.01, 1, 4, 5000),
	trajectory(0.01, 1, 5, 5000),
	trajectory(0.03, 1, 4, 5000),
	trajectory(0.03, 1, 5, 5000),
	trajectory(0.1 , 1, 4, 100),
	trajectory(0.1 , 1, 5, 100),
	trajectory(0.3 , 1, 4, 100),
	trajectory(0.3 , 1, 5, 100),
	layout = (4,2),
	size = (900, 900),
	title =
		hcat([["L₄ for α = $α" "L₅ for α = $α"] for α ∈ [0.01, 0.03, 0.1, 0.3]]...)
)

# ╔═╡ 362d97b0-7188-46d3-8535-30d4aebd5f74
md"""
From the range of values of `α` for which I have approximations in `lagrangepoints`, I can see that the change from stability to instability happens between `α = 0.038` and `α = 0.039`:
"""

# ╔═╡ c8800aec-8847-42cf-8c0d-c247cb882b2d
plot(
	trajectory(0.038, 1, 4, 300, [1,1]),
	trajectory(0.038, 1, 5, 300, [1,1]),
	trajectory(0.039, 1, 4, 300, [1,1]),
	trajectory(0.039, 1, 5, 300, [1,1]),
	layout = (2,2),
	size = (900, 900),
	title =
		hcat([["L₄ for α = $α" "L₅ for α = $α"] for α ∈ [0.038, 0.039]]...)
)

# ╔═╡ 3fe7a658-8146-49a4-b521-a23edb8964ca
md"""
Although the Lagrange point itself is unstable for `α = 0.039`, the orbit that `m` falls into around it is not. This is a [Lissajous orbit](https://en.wikipedia.org/wiki/Lissajous_orbit), which can also exist around other Lagrange points, however it is easiest to see around ``L_4`` and ``L_5`` when the system is only just unstable.

Another unusual stable orbit can be demonstrated with `α = 0.001` starting near ``L_3``, giving a [horseshoe orbit](https://en.wikipedia.org/wiki/Horseshoe_orbit) as shown below:
"""

# ╔═╡ 8f108448-b1ab-44e9-acb9-7bdd6c4f5619
trajectory(0.001, 1, 3, 3000)

# ╔═╡ b755707e-5283-44bc-b4b6-5e6179f12fc7
md"""
### The effect of `M₁` on stability
Now I will look at the effect of `M₁` on the stability of the Lagrange points. In fact, it has no effect on whether or not they are stable, with ``L_1``, ``L_2``, and ``L_3`` never stable, and ``L_4`` and ``L_5`` losing stability at the same cutoff point, as shown here with `M₁ = 100` in comparison to `M₁ = 1` above:
"""

# ╔═╡ 28641838-64d3-48b6-9f36-7652dd1eed48
plot(
	trajectory(0.038, 100, 4, 30, [1,1]),
	trajectory(0.038, 100, 5, 30, [1,1]),
	trajectory(0.039, 100, 4, 30, [1,1]),
	trajectory(0.039, 100, 5, 30, [1,1]),
	layout = (2,2),
	size = (900, 900),
	title =
		hcat([["L₄ for α = $α, M₁ = 100" "L₅ for α = $α, M₁ = 100"]
			for α ∈ [0.038, 0.039]]...)
)

# ╔═╡ edbda3e1-773f-4595-baa0-dd5866f3b517
md"""
However, as can be seen below (with `α = 0.1`), it does affect the time taken for orbits to destablise:
"""

# ╔═╡ 0c0eab6c-9dce-4569-8ef9-f3afc17bf494
plot(
	trajectory(0.1, 1  , 1, 10),
	trajectory(0.1, 100, 1, 1),
	trajectory(0.1, 1  , 2, 20),
	trajectory(0.1, 100, 2, 2),
	trajectory(0.1, 1  , 3, 60),
	trajectory(0.1, 100, 3, 6),
	trajectory(0.1, 1  , 4, 100),
	trajectory(0.1, 100, 4, 10),
	trajectory(0.1, 1  , 5, 100),
	trajectory(0.1, 100, 5, 10),
	layout = (5,2),
	size = (900,1125),
	title = hcat([["L$i for M₁ = 1, T = $T" "L$i for M₁ = 100, T = $(T÷10)"]
			for (i,T) ∈ [("₁",10), ("₂",20), ("₃",60), ("₄",100), ("₅",10)]]...)
)

# ╔═╡ 3bad4bf4-60d2-4cf9-b631-a8854cd4cdef
md"""
What is notable, however, is how similar the trajectories are when `M₁` is increased by a factor of 100, and `T` is decreased by a factor of 10 (at least, for the less chaotic divergence of ``L_1``, ``L_2``, and ``L_3``). Indeed, as the next diagrams illustrate (with `α = 0.05` this time), the speed of divergence of `m` from the Lagrange point is approximately proportional to ``\frac{1}{\sqrt{M₁}}``:
"""

# ╔═╡ 0431f730-2caa-4902-8e88-ccad08276c3b
plot(
	trajectory(0.05, 1 , 2, 40, [1.5, 1]),
	trajectory(0.05, 4 , 2, 20, [1.5, 1]),
	trajectory(0.05, 16, 2, 10, [1.5, 1]),
	trajectory(0.05, 64, 2, 5 , [1.5, 1]),
	layout = (2,2),
	size = (900,600),
	title = hcat(["L₂ for M₁ = $((40÷T)^2), T = $T" for T ∈ [40, 20, 10, 5]]...)
)

# ╔═╡ 23248c33-9001-461a-8b96-7795ee093a95
md"""
### Theoretical stability
Cornish finds the stability of the Lagrange points theoretically as follows:
- ``L_1``, ``L_2``, and ``L_3`` are always unstable
- ``L_4``, ``L_5`` are stable for ``\frac{M_1}{M_2} ≥ \frac{25 + \sqrt{621}}{2}``, and unstable otherwise

This behaviour matches the behaviour that I have found, even up to the value of the crossover between stability and instability of ``L_4`` and ``L_5``:
```math
\frac{M_1}{M_2} \geq \frac{25 + \sqrt{621}}{2} \quad \Leftrightarrow \quad \alpha = \frac{M_2}{M_1 + M_2} = \frac{1}{\frac{M_1}{M_2} + 1} \leq \frac{2}{27 + \sqrt{621}} = 0.0385...
```

Also, Cornish derives the e-folding rates for divergence from the Lagrange points from the positive eigenvalue of the evolution matrix (i.e ``\tau`` such that divergence is proportional to ``e^{t/\tau}``). These are proportional to ``\Omega``, which is of course proportional to ``\sqrt{M_1}``, explaining the behaviour seen when I varied ``M_1``. Furthermore, the e-folding time is much larger for ``L_3`` than for ``L_1`` and ``L_2``, particularly for ``\frac{M_2}{M_1}`` small, or equivalently for ``\alpha`` small as I observed (Cornish has a small typo here, the eigenvalues for ``L_3`` should be ``\lambda_{\pm} = \pm \Omega \sqrt{\frac{3M_2}{8M_1}}``, not ``\pm \Omega \sqrt{\frac{3M_1}{8M_2}}``, which can be verified as the determinant of the matrix is ``-\frac{21M_1}{8M_2}\Omega^4``).

Therefore, I can be confident in the overall results of this case study, as the behaviour as I have simulated matches the theory exactly.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DifferentialEquations = "0c46a032-eb83-5123-abaf-570d42b7fbaa"
NLsolve = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
DifferentialEquations = "~6.18.0"
NLsolve = "~4.5.1"
Plots = "~1.20.0"
PlutoUI = "~0.7.9"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[AbstractTrees]]
git-tree-sha1 = "03e0550477d86222521d254b741d470ba17ea0b5"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.3.4"

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "f87e559f87a45bece9c9ed97458d3afe98b1ebb9"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.1.0"

[[ArrayInterface]]
deps = ["IfElse", "LinearAlgebra", "Requires", "SparseArrays", "Static"]
git-tree-sha1 = "cdb00a6fb50762255021e5571cf95df3e1797a51"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "3.1.23"

[[ArrayLayouts]]
deps = ["FillArrays", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "0f7998147ff3d112fad027c894b6b6bebf867154"
uuid = "4c555306-a7a7-4459-81d9-ec55ddd5c99a"
version = "0.7.3"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[BandedMatrices]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "d17071d7fc9a98ca2d958cd217e62a17c5eeebed"
uuid = "aae01518-5342-5314-be14-df237901396f"
version = "0.16.10"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[BoundaryValueDiffEq]]
deps = ["BandedMatrices", "DiffEqBase", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "NLsolve", "Reexport", "SparseArrays"]
git-tree-sha1 = "fe34902ac0c3a35d016617ab7032742865756d7d"
uuid = "764a87c0-6b3e-53db-9096-fe964310641d"
version = "2.7.1"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c3598e525718abcc440f69cc6d5f60dda0a1b61e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.6+5"

[[CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[CSTParser]]
deps = ["Tokenize"]
git-tree-sha1 = "b2667530e42347b10c10ba6623cfebc09ac5c7b6"
uuid = "00ebfdb7-1f24-5e51-bd34-a7502290713f"
version = "3.2.4"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "e2f47f6d8337369411569fd45ae5753ca10394c6"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.0+6"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "bdc0937269321858ab2a4f288486cb258b9a0af7"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.3.0"

[[CloseOpenIntervals]]
deps = ["ArrayInterface", "Static"]
git-tree-sha1 = "4fcacb5811c9e4eb6f9adde4afc0e9c4a7a92f5a"
uuid = "fb6a15b2-703c-40df-9091-08a04967cfa9"
version = "0.1.1"

[[ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "9995eb3977fbf67b86d0a0a0508e83017ded03f2"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.14.0"

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

[[Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[CommonMark]]
deps = ["Crayons", "JSON", "URIs"]
git-tree-sha1 = "1060c5023d2ac8210c73078cb7c0c567101d201c"
uuid = "a80b9123-70ca-4bc0-993e-6e3bcb318db6"
version = "0.8.2"

[[CommonSolve]]
git-tree-sha1 = "68a0743f578349ada8bc911a5cbd5a2ef6ed6d1f"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.0"

[[CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "344f143fa0ec67e47917848795ab19c6a455f32c"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.32.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[CompositeTypes]]
git-tree-sha1 = "d5b014b216dc891e81fea299638e4c10c657b582"
uuid = "b152e2b5-7a66-4b01-a709-34e65c35f657"
version = "0.1.2"

[[ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f74e9d5388b8620b4cee35d4c5a618dd4dc547f4"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.3.0"

[[Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[Crayons]]
git-tree-sha1 = "3f71217b538d7aaee0b69ab47d9b7724ca8afa0d"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.0.4"

[[DEDataArrays]]
deps = ["ArrayInterface", "DocStringExtensions", "LinearAlgebra", "RecursiveArrayTools", "SciMLBase", "StaticArrays"]
git-tree-sha1 = "31186e61936fbbccb41d809ad4338c9f7addf7ae"
uuid = "754358af-613d-5f8d-9788-280bf1605d4c"
version = "0.2.0"

[[DataAPI]]
git-tree-sha1 = "ee400abb2298bd13bfc3df1c412ed228061a2385"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.7.0"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "7d9d316f04214f7efdbb6398d545446e246eff02"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.10"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelayDiffEq]]
deps = ["ArrayInterface", "DataStructures", "DiffEqBase", "LinearAlgebra", "Logging", "NonlinearSolve", "OrdinaryDiffEq", "Printf", "RecursiveArrayTools", "Reexport", "UnPack"]
git-tree-sha1 = "6eba402e968317b834c28cd47499dd1b572dd093"
uuid = "bcd4f6db-9728-5f36-b5f7-82caef46ccdb"
version = "5.31.1"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[DiffEqBase]]
deps = ["ArrayInterface", "ChainRulesCore", "DEDataArrays", "DataStructures", "Distributions", "DocStringExtensions", "FastBroadcast", "ForwardDiff", "FunctionWrappers", "IterativeSolvers", "LabelledArrays", "LinearAlgebra", "Logging", "MuladdMacro", "NonlinearSolve", "Parameters", "PreallocationTools", "Printf", "RecursiveArrayTools", "RecursiveFactorization", "Reexport", "Requires", "SciMLBase", "Setfield", "SparseArrays", "StaticArrays", "Statistics", "SuiteSparse", "ZygoteRules"]
git-tree-sha1 = "82144ac50e8c63b3eb3b2b3e9b85b667d1097430"
uuid = "2b5f629d-d688-5b77-993f-72d75c75574e"
version = "6.71.1"

[[DiffEqCallbacks]]
deps = ["DataStructures", "DiffEqBase", "ForwardDiff", "LinearAlgebra", "NLsolve", "OrdinaryDiffEq", "RecipesBase", "RecursiveArrayTools", "StaticArrays"]
git-tree-sha1 = "0972ca167952dc426b5438fc188b846b7a66a1f3"
uuid = "459566f4-90b8-5000-8ac3-15dfb0a30def"
version = "2.16.1"

[[DiffEqFinancial]]
deps = ["DiffEqBase", "DiffEqNoiseProcess", "LinearAlgebra", "Markdown", "RandomNumbers"]
git-tree-sha1 = "db08e0def560f204167c58fd0637298e13f58f73"
uuid = "5a0ffddc-d203-54b0-88ba-2c03c0fc2e67"
version = "2.4.0"

[[DiffEqJump]]
deps = ["ArrayInterface", "Compat", "DataStructures", "DiffEqBase", "FunctionWrappers", "LightGraphs", "LinearAlgebra", "PoissonRandom", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "StaticArrays", "TreeViews", "UnPack"]
git-tree-sha1 = "fb7cb8909880cfa70d134aac3fbd486a908e56ce"
uuid = "c894b116-72e5-5b58-be3c-e6d8d4ac2b12"
version = "7.2.0"

[[DiffEqNoiseProcess]]
deps = ["DiffEqBase", "Distributions", "LinearAlgebra", "Optim", "PoissonRandom", "QuadGK", "Random", "Random123", "RandomNumbers", "RecipesBase", "RecursiveArrayTools", "Requires", "ResettableStacks", "SciMLBase", "StaticArrays", "Statistics"]
git-tree-sha1 = "d6839a44a268c69ef0ed927b22a6f43c8a4c2e73"
uuid = "77a26b50-5914-5dd7-bc55-306e6241c503"
version = "5.9.0"

[[DiffEqPhysics]]
deps = ["DiffEqBase", "DiffEqCallbacks", "ForwardDiff", "LinearAlgebra", "Printf", "Random", "RecipesBase", "RecursiveArrayTools", "Reexport", "StaticArrays"]
git-tree-sha1 = "8f23c6f36f6a6eb2cbd6950e28ec7c4b99d0e4c9"
uuid = "055956cb-9e8b-5191-98cc-73ae4a59e68a"
version = "3.9.0"

[[DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[DiffRules]]
deps = ["NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "85d2d9e2524da988bffaf2a381864e20d2dae08d"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.2.1"

[[DifferentialEquations]]
deps = ["BoundaryValueDiffEq", "DelayDiffEq", "DiffEqBase", "DiffEqCallbacks", "DiffEqFinancial", "DiffEqJump", "DiffEqNoiseProcess", "DiffEqPhysics", "DimensionalPlotRecipes", "LinearAlgebra", "MultiScaleArrays", "OrdinaryDiffEq", "ParameterizedFunctions", "Random", "RecursiveArrayTools", "Reexport", "SteadyStateDiffEq", "StochasticDiffEq", "Sundials"]
git-tree-sha1 = "ececc535bd2aa55a520131d955639288704e3851"
uuid = "0c46a032-eb83-5123-abaf-570d42b7fbaa"
version = "6.18.0"

[[DimensionalPlotRecipes]]
deps = ["LinearAlgebra", "RecipesBase"]
git-tree-sha1 = "af883a26bbe6e3f5f778cb4e1b81578b534c32a6"
uuid = "c619ae07-58cd-5f6d-b883-8f17bd6a98f9"
version = "1.2.0"

[[Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "abe4ad222b26af3337262b8afb28fab8d215e9f8"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.3"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Distributions]]
deps = ["FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns"]
git-tree-sha1 = "3889f646423ce91dd1055a76317e9a1d3a23fff1"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.11"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "a32185f5428d3986f47c2ab78b1f216d5e6cc96f"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.5"

[[DomainSets]]
deps = ["CompositeTypes", "IntervalSets", "LinearAlgebra", "StaticArrays", "Statistics", "Test"]
git-tree-sha1 = "6cdd99d0b7b555f96f7cb05aa82067ee79e7aef4"
uuid = "5b8099bc-c8ec-5219-889f-1d9e522a28bf"
version = "0.5.2"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[DynamicPolynomials]]
deps = ["DataStructures", "Future", "LinearAlgebra", "MultivariatePolynomials", "MutableArithmetics", "Pkg", "Reexport", "Test"]
git-tree-sha1 = "e9d82a6f35d199d3821c069932115e19ca2a2b3d"
uuid = "7c1d4256-1411-5781-91ec-d7bc3513ac07"
version = "0.3.19"

[[EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "92d8f9f208637e8d2d28c664051a00569c01493d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.1.5+1"

[[EllipsisNotation]]
deps = ["ArrayInterface"]
git-tree-sha1 = "8041575f021cba5a099a456b4163c9a08b566a02"
uuid = "da5c29d0-fa7d-589e-88eb-ea29b0a81949"
version = "1.1.0"

[[Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b3bfd02e98aedfa5cf885665493c5598c350cd2f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.10+0"

[[ExponentialUtilities]]
deps = ["ArrayInterface", "LinearAlgebra", "Printf", "Requires", "SparseArrays"]
git-tree-sha1 = "ad435656c49da7615152b856c0f9abe75b0b5dc9"
uuid = "d4d017d3-3776-5f7e-afef-a10c40355c18"
version = "1.8.4"

[[ExprTools]]
git-tree-sha1 = "b7e3d17636b348f005f11040025ae8c6f645fe92"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.6"

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

[[FastBroadcast]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "26be48918640ce002f5833e8fc537b2ba7ed0234"
uuid = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
version = "0.1.8"

[[FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "8c8eac2af06ce35973c3eadb4ab3243076a408e7"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.12.1"

[[FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "8b3c09b56acaf3c0e581c66638b85c8650ee9dca"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.8.1"

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

[[ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "NaNMath", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "b5e930ac60b613ef3406da6d4f42c35d8dc51419"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.19"

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

[[FunctionWrappers]]
git-tree-sha1 = "241552bc2209f0fa068b6415b1942cc0aa486bcc"
uuid = "069b7b12-0de2-55c6-9aab-29f3d0a68a2e"
version = "1.1.2"

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

[[Hwloc]]
deps = ["Hwloc_jll"]
git-tree-sha1 = "92d99146066c5c6888d5a3abc871e6a214388b91"
uuid = "0e44f5e4-bd66-52a0-8798-143a42290a1d"
version = "2.0.0"

[[Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3395d4d4aeb3c9d31f5929d32760d8baeee88aaf"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.5.0+0"

[[IfElse]]
git-tree-sha1 = "28e837ff3e7a6c3cdb252ce49fb412c8eb3caeef"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.0"

[[Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[IntervalSets]]
deps = ["Dates", "EllipsisNotation", "Statistics"]
git-tree-sha1 = "3cc368af3f110a767ac786560045dceddfc16758"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.5.3"

[[IrrationalConstants]]
git-tree-sha1 = "f76424439413893a832026ca355fe273e93bce94"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.0"

[[IterTools]]
git-tree-sha1 = "05110a2ab1fc5f932622ffea2a003221f4782c18"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.3.0"

[[IterativeSolvers]]
deps = ["LinearAlgebra", "Printf", "Random", "RecipesBase", "SparseArrays"]
git-tree-sha1 = "1a8c6237e78b714e901e406c096fc8a65528af7d"
uuid = "42fd0dbc-a981-5370-80f2-aaf504508153"
version = "0.9.1"

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
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d735490ac75c5cb9f1b00d8b5509c11984dc6943"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.0+0"

[[JuliaFormatter]]
deps = ["CSTParser", "CommonMark", "DataStructures", "Pkg", "Tokenize"]
git-tree-sha1 = "01de4719a784d520199608f8996ec8ff11e8fa24"
uuid = "98e50ef6-434e-11e9-1051-2b60c6c9e899"
version = "0.15.7"

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

[[LabelledArrays]]
deps = ["ArrayInterface", "LinearAlgebra", "MacroTools", "StaticArrays"]
git-tree-sha1 = "bdde43e002847c34c206735b1cf860bc3abd35e7"
uuid = "2ee39098-c373-598a-b85f-a56591580800"
version = "1.6.4"

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

[[LightGraphs]]
deps = ["ArnoldiMethod", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "432428df5f360964040ed60418dd5601ecd240b6"
uuid = "093fc24a-ae57-5d10-9952-331d41423f4d"
version = "1.3.5"

[[LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "f27132e551e959b3667d8c93eae90973225032dd"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.1.1"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "3d682c07e6dd250ed082f883dc88aee7996bf2cc"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.0"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[LoopVectorization]]
deps = ["ArrayInterface", "DocStringExtensions", "IfElse", "LinearAlgebra", "OffsetArrays", "Polyester", "Requires", "SLEEFPirates", "Static", "StrideArraysCore", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "6643933c619b292cb1fe566f5a411dddddec3db9"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.63"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "0fb723cd8c45858c22169b2e42269e53271a6df7"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.7"

[[ManualMemory]]
git-tree-sha1 = "9cb207b18148b2199db259adfa923b45593fe08e"
uuid = "d125e4d3-2237-4719-b19c-fa641b8a4667"
version = "0.1.6"

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

[[ModelingToolkit]]
deps = ["AbstractTrees", "ArrayInterface", "ConstructionBase", "DataStructures", "DiffEqBase", "DiffEqCallbacks", "DiffEqJump", "DiffRules", "Distributed", "Distributions", "DocStringExtensions", "DomainSets", "IfElse", "InteractiveUtils", "JuliaFormatter", "LabelledArrays", "Latexify", "Libdl", "LightGraphs", "LinearAlgebra", "MacroTools", "NaNMath", "NonlinearSolve", "RecursiveArrayTools", "Reexport", "Requires", "RuntimeGeneratedFunctions", "SafeTestsets", "SciMLBase", "Serialization", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "SymbolicUtils", "Symbolics", "UnPack", "Unitful"]
git-tree-sha1 = "e9513cadb4451064db50c3ff0216791a14cfdf85"
uuid = "961ee093-0014-501f-94e3-6117800e7a78"
version = "6.2.1"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[MuladdMacro]]
git-tree-sha1 = "c6190f9a7fc5d9d5915ab29f2134421b12d24a68"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.2"

[[MultiScaleArrays]]
deps = ["DiffEqBase", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "OrdinaryDiffEq", "Random", "RecursiveArrayTools", "SparseDiffTools", "Statistics", "StochasticDiffEq", "TreeViews"]
git-tree-sha1 = "258f3be6770fe77be8870727ba9803e236c685b8"
uuid = "f9640e96-87f6-5992-9c3b-0743c6a49ffa"
version = "1.8.1"

[[MultivariatePolynomials]]
deps = ["DataStructures", "LinearAlgebra", "MutableArithmetics"]
git-tree-sha1 = "45c9940cec79dedcdccc73cc6dd09ea8b8ab142c"
uuid = "102ac46a-7ee4-5c85-9060-abc95bfdeaa3"
version = "0.3.18"

[[MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "3927848ccebcc165952dc0d9ac9aa274a87bfe01"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "0.2.20"

[[NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "144bab5b1443545bc4e791536c9f1eacb4eed06a"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.1"

[[NLsolve]]
deps = ["Distances", "LineSearches", "LinearAlgebra", "NLSolversBase", "Printf", "Reexport"]
git-tree-sha1 = "019f12e9a1a7880459d0173c182e6a99365d7ac1"
uuid = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
version = "4.5.1"

[[NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[NonlinearSolve]]
deps = ["ArrayInterface", "FiniteDiff", "ForwardDiff", "IterativeSolvers", "LinearAlgebra", "RecursiveArrayTools", "RecursiveFactorization", "Reexport", "SciMLBase", "Setfield", "StaticArrays", "UnPack"]
git-tree-sha1 = "f2530482ef6447c8ae24c660914436f1ae3917e0"
uuid = "8913a72c-1f9b-4ce2-8d82-65094dcecaec"
version = "0.3.9"

[[OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "c0f4a4836e5f3e0763243b8324200af6d0e0f90c"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.10.5"

[[Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7937eda4681660b4d6aeeecc2f7e1c81c8ee4e2f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+0"

[[OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "15003dcb7d8db3c6c857fda14891a539a8f2705a"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.10+0"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[Optim]]
deps = ["Compat", "FillArrays", "LineSearches", "LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "PositiveFactorizations", "Printf", "SparseArrays", "StatsBase"]
git-tree-sha1 = "7863df65dbb2a0fa8f85fcaf0a41167640d2ebed"
uuid = "429524aa-4258-5aef-a3af-852621145aeb"
version = "1.4.1"

[[Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[OrdinaryDiffEq]]
deps = ["Adapt", "ArrayInterface", "DataStructures", "DiffEqBase", "DocStringExtensions", "ExponentialUtilities", "FastClosures", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "Logging", "LoopVectorization", "MacroTools", "MuladdMacro", "NLsolve", "Polyester", "RecursiveArrayTools", "Reexport", "SparseArrays", "SparseDiffTools", "StaticArrays", "UnPack"]
git-tree-sha1 = "1600070fd4b87cda72a7c22a9ad8f3eec43e72ec"
uuid = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"
version = "5.61.1"

[[PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "4dd403333bcf0909341cfe57ec115152f937d7d8"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.1"

[[ParameterizedFunctions]]
deps = ["DataStructures", "DiffEqBase", "DocStringExtensions", "Latexify", "LinearAlgebra", "ModelingToolkit", "Reexport", "SciMLBase"]
git-tree-sha1 = "c2d9813bdcf47302a742a1f5956d7de274acec12"
uuid = "65888b18-ceab-5e60-b2b9-181511a3b968"
version = "5.12.1"

[[Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "2276ac65f1e236e0a6ea70baff3f62ad4c625345"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.2"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "477bf42b4d1496b454c10cce46645bb5b8a0cf2c"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.0.2"

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

[[PoissonRandom]]
deps = ["Random", "Statistics", "Test"]
git-tree-sha1 = "44d018211a56626288b5d3f8c6497d28c26dc850"
uuid = "e409e4f3-bfea-5376-8464-e040bb5c01ab"
version = "0.4.0"

[[Polyester]]
deps = ["ArrayInterface", "IfElse", "ManualMemory", "Requires", "Static", "StrideArraysCore", "ThreadingUtilities", "VectorizationBase"]
git-tree-sha1 = "81c59c2bed8c8a76843411ddb33e548bf2bcc9b2"
uuid = "f517fe37-dbe3-4b94-8317-1923a5111588"
version = "0.3.8"

[[PositiveFactorizations]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "17275485f373e6673f7e7f97051f703ed5b15b20"
uuid = "85a6dd25-e78a-55b7-8502-1745935b8125"
version = "0.2.4"

[[PreallocationTools]]
deps = ["ArrayInterface", "ForwardDiff", "LabelledArrays"]
git-tree-sha1 = "9e917b108c4aaf47e8606542325bd2ccbcac7ca4"
uuid = "d236fae5-4411-538c-8e31-a6e3d9e00b46"
version = "0.1.0"

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

[[QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "12fbe86da16df6679be7521dfb39fbc861e1dc7b"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.1"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Random123]]
deps = ["Libdl", "Random", "RandomNumbers"]
git-tree-sha1 = "0e8b146557ad1c6deb1367655e052276690e71a3"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.4.2"

[[RandomNumbers]]
deps = ["Random", "Requires"]
git-tree-sha1 = "043da614cc7e95c703498a491e2c21f58a2b8111"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.5.3"

[[RecipesBase]]
git-tree-sha1 = "b3fb709f3c97bfc6e948be68beeecb55a0b340ae"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.1.1"

[[RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "2a7a2469ed5d94a98dea0e85c46fa653d76be0cd"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.3.4"

[[RecursiveArrayTools]]
deps = ["ArrayInterface", "ChainRulesCore", "DocStringExtensions", "LinearAlgebra", "RecipesBase", "Requires", "StaticArrays", "Statistics", "ZygoteRules"]
git-tree-sha1 = "6cf3169ab34096657b79ea7d26f64ad79b3a5ea7"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "2.17.0"

[[RecursiveFactorization]]
deps = ["LinearAlgebra", "LoopVectorization", "Polyester", "StrideArraysCore", "TriangularSolve"]
git-tree-sha1 = "9ac54089f52b0d0c37bebca35b9505720013a108"
uuid = "f2c3362d-daeb-58d1-803e-2bc74f2840b4"
version = "0.2.2"

[[Reexport]]
git-tree-sha1 = "5f6c21241f0f655da3952fd60aa18477cf96c220"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.1.0"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[ResettableStacks]]
deps = ["StaticArrays"]
git-tree-sha1 = "256eeeec186fa7f26f2801732774ccf277f05db9"
uuid = "ae5879a3-cd67-5da8-be7f-38c6eb64a37b"
version = "1.1.1"

[[Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[RuntimeGeneratedFunctions]]
deps = ["ExprTools", "SHA", "Serialization"]
git-tree-sha1 = "cdc1e4278e91a6ad530770ebb327f9ed83cf10c4"
uuid = "7e49a35a-f44a-4d26-94aa-eba1b4ca6b47"
version = "0.5.3"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "bfdf9532c33db35d2ce9df4828330f0e92344a52"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.25"

[[SafeTestsets]]
deps = ["Test"]
git-tree-sha1 = "36ebc5622c82eb9324005cc75e7e2cc51181d181"
uuid = "1bc83da4-3b8d-516f-aca4-4fe02f6d838f"
version = "0.0.1"

[[SciMLBase]]
deps = ["ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "RecipesBase", "RecursiveArrayTools", "StaticArrays", "Statistics", "Tables", "TreeViews"]
git-tree-sha1 = "f4bcc1bc78857e0602de2ec548b08ac73bf29acc"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "1.18.4"

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "Requires"]
git-tree-sha1 = "fca29e68c5062722b5b4435594c3d1ba557072a3"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "0.7.1"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

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

[[SparseDiffTools]]
deps = ["Adapt", "ArrayInterface", "Compat", "DataStructures", "FiniteDiff", "ForwardDiff", "LightGraphs", "LinearAlgebra", "Requires", "SparseArrays", "StaticArrays", "VertexSafeGraphs"]
git-tree-sha1 = "083ad77eeb56e40fd662373f4ba3302a4d90f77f"
uuid = "47a9eef4-7e08-11e9-0b38-333d64bd3804"
version = "1.16.3"

[[SpecialFunctions]]
deps = ["ChainRulesCore", "LogExpFunctions", "OpenSpecFun_jll"]
git-tree-sha1 = "a322a9493e49c5f3a10b50df3aedaf1cdb3244b7"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "1.6.1"

[[Static]]
deps = ["IfElse"]
git-tree-sha1 = "62701892d172a2fa41a1f829f66d2b0db94a9a63"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.3.0"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "3240808c6d463ac46f1c1cd7638375cd22abbccb"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.12"

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

[[StatsFuns]]
deps = ["Rmath", "SpecialFunctions"]
git-tree-sha1 = "ced55fd4bae008a8ea12508314e725df61f0ba45"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.7"

[[SteadyStateDiffEq]]
deps = ["DiffEqBase", "DiffEqCallbacks", "LinearAlgebra", "NLsolve", "Reexport", "SciMLBase"]
git-tree-sha1 = "3df66a4a9ba477bea5cb10a3ec732bb48a2fc27d"
uuid = "9672c7b4-1e72-59bd-8a11-6ac3964bc41f"
version = "1.6.4"

[[StochasticDiffEq]]
deps = ["ArrayInterface", "DataStructures", "DiffEqBase", "DiffEqJump", "DiffEqNoiseProcess", "DocStringExtensions", "FillArrays", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "Logging", "MuladdMacro", "NLsolve", "OrdinaryDiffEq", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "SparseArrays", "SparseDiffTools", "StaticArrays", "UnPack"]
git-tree-sha1 = "d9e996e95ad3c601c24d81245a7550cebcfedf85"
uuid = "789caeaf-c7a9-5a7d-9973-96adeb23e2a0"
version = "6.36.0"

[[StrideArraysCore]]
deps = ["ArrayInterface", "ManualMemory", "Requires", "ThreadingUtilities", "VectorizationBase"]
git-tree-sha1 = "e1c37dd3022ba6aaf536541dd607e8d5fb534377"
uuid = "7792a7ef-975c-4747-a70f-980b88e8d1da"
version = "0.1.17"

[[StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "000e168f5cc9aded17b6999a560b7c11dda69095"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.0"

[[SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"

[[Sundials]]
deps = ["CEnum", "DataStructures", "DiffEqBase", "Libdl", "LinearAlgebra", "Logging", "Reexport", "SparseArrays", "Sundials_jll"]
git-tree-sha1 = "75412a0ce4cd7995d7445ba958dd11de03fd2ce5"
uuid = "c3572dad-4567-51f8-b174-8c6c989267f4"
version = "4.5.3"

[[Sundials_jll]]
deps = ["CompilerSupportLibraries_jll", "Libdl", "OpenBLAS_jll", "Pkg", "SuiteSparse_jll"]
git-tree-sha1 = "013ff4504fc1d475aa80c63b455b6b3a58767db2"
uuid = "fb77eaff-e24c-56d4-86b1-d163f2edb164"
version = "5.2.0+1"

[[Suppressor]]
git-tree-sha1 = "a819d77f31f83e5792a76081eee1ea6342ab8787"
uuid = "fd094767-a336-5f1f-9728-57cf17d0bbfb"
version = "0.2.0"

[[SymbolicUtils]]
deps = ["AbstractTrees", "ChainRulesCore", "Combinatorics", "ConstructionBase", "DataStructures", "DocStringExtensions", "DynamicPolynomials", "IfElse", "LabelledArrays", "LinearAlgebra", "MultivariatePolynomials", "NaNMath", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "TimerOutputs"]
git-tree-sha1 = "591440eabc9407917b1fedd1e929710dba5b0958"
uuid = "d1185830-fcd6-423d-90d6-eec64667417b"
version = "0.13.3"

[[Symbolics]]
deps = ["ConstructionBase", "DiffRules", "Distributions", "DocStringExtensions", "DomainSets", "IfElse", "Latexify", "Libdl", "LinearAlgebra", "MacroTools", "NaNMath", "RecipesBase", "Reexport", "Requires", "RuntimeGeneratedFunctions", "SciMLBase", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "SymbolicUtils", "TreeViews"]
git-tree-sha1 = "6a7d84c33afd675e63f55f6c8859d169b1887c85"
uuid = "0c5d862f-8b57-4792-8d23-62f2024744c7"
version = "3.0.0"

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

[[ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "03013c6ae7f1824131b2ae2fc1d49793b51e8394"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.4.6"

[[TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "209a8326c4f955e2442c07b56029e88bb48299c7"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.12"

[[Tokenize]]
git-tree-sha1 = "eee92eda3cc8e104b7e56ff4c1fcf0d78ca37c89"
uuid = "0796e94c-ce3b-5d07-9a54-7f471281c624"
version = "0.5.18"

[[TreeViews]]
deps = ["Test"]
git-tree-sha1 = "8d0d7a3fe2f30d6a7f833a5f19f7c7a5b396eae6"
uuid = "a2a6695c-b41b-5b7d-aed9-dbfdeacea5d7"
version = "0.3.0"

[[TriangularSolve]]
deps = ["CloseOpenIntervals", "IfElse", "LinearAlgebra", "LoopVectorization", "Polyester", "Static", "VectorizationBase"]
git-tree-sha1 = "369db21d596efc011498549f9d3551273ae4bb68"
uuid = "d5829a12-d9aa-46ab-831f-fb7c9ab06edf"
version = "0.1.2"

[[URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[Unitful]]
deps = ["ConstructionBase", "Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "a981a8ef8714cba2fd9780b22fd7a469e7aaf56d"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.9.0"

[[VectorizationBase]]
deps = ["ArrayInterface", "Hwloc", "IfElse", "Libdl", "LinearAlgebra", "Static"]
git-tree-sha1 = "32a3252a00a8e4aa23129e2c36a237e812f71eeb"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.20.33"

[[VertexSafeGraphs]]
deps = ["LightGraphs"]
git-tree-sha1 = "b9b450c99a3ca1cc1c6836f560d8d887bcbe356e"
uuid = "19fa3120-7c27-5ec5-8db8-b0b0aa330d6f"
version = "0.1.2"

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

[[ZygoteRules]]
deps = ["MacroTools"]
git-tree-sha1 = "9e7a1e8ca60b742e508a315c17eef5211e7fbfd7"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.1"

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
# ╟─f52dbad2-fa73-11eb-2071-8521afcace5b
# ╟─c08f5b42-b111-4eb7-84a3-d80157787b02
# ╟─ba5d8c7d-0df5-434b-99ff-696116f9e222
# ╟─9aa47484-bbb7-4990-a5b5-f57f208bbb5b
# ╟─00786027-f20a-4aa8-8d78-493c5890df7c
# ╟─b25c680f-f667-4434-aabe-64bbd32e7a4f
# ╟─7ab49c23-1766-454c-8265-295a20422e33
# ╟─207ff5cd-2f24-4aa9-b816-ba476bbad45b
# ╠═42963dd1-8295-4bf3-97ad-2132946ebf35
# ╟─e888671d-e2c0-4f65-a879-4b0222eb99c9
# ╠═edf3a2bf-2e75-41a9-8f5e-4e96c987137c
# ╠═3b290eb7-c8f9-4a53-9cd8-2b7a7808818f
# ╠═76b8b4fc-790a-422a-9226-5c25d89f46ea
# ╟─4cddf611-8b43-4351-bb1d-08c29a75003f
# ╠═afc3d520-d321-4102-8a55-5ea66bdfbedc
# ╟─ea3230da-c9e2-4e86-a36f-b17021b1dc72
# ╠═5103ba48-9744-4a15-86a9-28298de90338
# ╠═a5cf0fb5-8146-4622-8bca-f6e86691aab1
# ╟─b7acb521-51f1-47fa-b0ae-db0676d517e2
# ╟─243aa0fb-6162-4fc5-b2f4-ac7a92a86c27
# ╠═05d2b08e-ebeb-4c22-b2a1-b5b70f400216
# ╟─9c1cccd8-0bb2-46c8-a090-9eecae1bdc41
# ╠═964ee58d-7076-4649-b081-026d9652b0ef
# ╟─576706b3-ac7c-4d6d-93ef-3f3cc71f75f9
# ╠═1768e022-8e1a-4978-b6cd-f7612a9d3242
# ╟─6c900df7-bec6-4f63-9af4-5a0c9e559598
# ╠═34c1cd0f-b058-43ae-adb8-848268086742
# ╟─a15b48ee-154c-4199-a115-5a8bd09bd8f4
# ╠═25f3c52b-1304-405f-b4e9-0e23b44414a2
# ╟─07e8b7ab-e089-4bde-8bd2-e19a4e4581fe
# ╠═88ad767e-549e-47fa-8e50-8389400d7f31
# ╟─3ec1dcbb-f493-4342-9a0c-23a866128979
# ╠═f8fd93ea-5277-4e32-bfaf-21ca14a668db
# ╟─134b0cef-3701-47cd-a9c8-1b31b0893153
# ╟─4d62b539-975a-4fe2-847c-83e3aa1eddf0
# ╠═090755ae-64f7-4984-b1f7-328dfc2984bd
# ╟─20a8a0f9-ad09-4e3d-ac67-b4fc9b4bcba9
# ╠═5f4e3ef8-8ee6-4ca6-9b64-4b62a5d7238d
# ╟─e8b1d4ab-b449-4b6a-9a86-623134f52e73
# ╠═2f9dbd3b-892a-4f68-b08d-4f793dd5652d
# ╟─362d97b0-7188-46d3-8535-30d4aebd5f74
# ╠═c8800aec-8847-42cf-8c0d-c247cb882b2d
# ╟─3fe7a658-8146-49a4-b521-a23edb8964ca
# ╠═8f108448-b1ab-44e9-acb9-7bdd6c4f5619
# ╟─b755707e-5283-44bc-b4b6-5e6179f12fc7
# ╠═28641838-64d3-48b6-9f36-7652dd1eed48
# ╟─edbda3e1-773f-4595-baa0-dd5866f3b517
# ╟─0c0eab6c-9dce-4569-8ef9-f3afc17bf494
# ╟─3bad4bf4-60d2-4cf9-b631-a8854cd4cdef
# ╠═0431f730-2caa-4902-8e88-ccad08276c3b
# ╟─23248c33-9001-461a-8b96-7795ee093a95
# ╟─9088e0a6-4e96-4d68-a851-668e753ead58
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
