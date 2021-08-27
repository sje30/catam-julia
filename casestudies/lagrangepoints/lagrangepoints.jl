using DifferentialEquations
using NLsolve
using Plots

# The range of values α = M₂/(M₁+M₂) where the Lagrange points will be found
αvals = 0.001:0.001:0.5
# The number of values of α
nαvals = length(αvals)
# Will store the positions of the Lagrange points
lagrangepoints = zeros(Float64, nαvals, 10);

for i ∈ 1:nαvals
    # Set the value of α = M₂/(M₁+M₂)
	α = αvals[i]
	
    # Set up the function for NLsolve to use
	function evalF!(F, X)
		x, y = X
		F[1] = x -
			(1 - α)*(x + α)/√((x + α)^2 + y^2)^3 -
			α*(x + α - 1)/√((x + α - 1)^2 + y^2)^3
		F[2] = y -
			(1 - α)*y/√((x + α)^2 + y^2)^3 -
			α*y/√((x + α - 1)^2 + y^2)^3
	end
	
    # Run nlsolve at each of the five predetermined starting positions to find the five Lagrange points
	lagrangepoints[i,1:2 ] = nlsolve(evalF!, [ 0.0, 0.0], autodiff=:forward).zero
	lagrangepoints[i,3:4 ] = nlsolve(evalF!, [ 1.0, 0.0], autodiff=:forward).zero
	lagrangepoints[i,5:6 ] = nlsolve(evalF!, [-1.0, 0.0], autodiff=:forward).zero
	lagrangepoints[i,7:8 ] = nlsolve(evalF!, [ 0.0, 1.0], autodiff=:forward).zero
	lagrangepoints[i,9:10] = nlsolve(evalF!, [ 0.0,-1.0], autodiff=:forward).zero
	
end

# Plot the values of α against the coordinates of the Lagrange points,
#  both as found numerically, and as approximated theoretically
function locationplots()
    return plot(
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
end

# Calculates the acceleration of m, given position r and velocity v, with p a vector of parameters
function acceleration(r, v, p)
    # Parameters for the system
    G, M₁, M₂, r₁, r₂, Ω = p

    # The four forces (including fictitious) acting on m
    gravitational₁ = - ( G * M₁ / hypot((r - r₁)...)^3 ) .* (r - r₁)
    gravitational₂ = - ( G * M₂ / hypot((r - r₂)...)^3 ) .* (r - r₂)
    coriolis = - 2Ω .* [[0, -1] [1, 0]] * v
    centrifugal = (Ω^2) .* r
    return gravitational₁ + gravitational₂ + coriolis + centrifugal
end

# Sets up the derivative function for DifferentialEquations to use
function derivative!(du, u, p, t)
    du[1] = u[3]
    du[2] = u[4]
    du[3], du[4] = acceleration(u[1:2], u[3:4], p)
end

# Uses DifferentialEquations to simulate the trajectory of m for time T with initial conditions
#  r₀ and v₀, and parameters α and M₁
function simulate(α, G, r₀, v₀, T)
    # M₂ is the mass of the other large stationary body
    M₂ = M₁ * α/(1-α)

    # r₁ and r₂ are the positions of M₁ and M₂
    r₁ = [-α, 0]
    r₂ = [1-α, 0]

	# G is the gravitational constant, which is 1 for an appropriate system of units
	G = 1
    # Ω is the magnitude of the angular velocity of the rotating frame of reference
    Ω = √(G * (M₁ + M₂))

    # DifferentialEquations simulates the mass for time T
    return solve(ODEProblem(derivative!, vcat(r₀, v₀), (0.0, float(T)), [G, M₁, M₂, r₁, r₂, Ω]))
end

# Creates a diagram of the Sun/Earth/Moon system to test the simulation
function moondiagram()
    diagram = plot(
		simulate(3e-6, 39, [1.003, 0.0], [0.0, 0.215], 1/12),
		vars = (1,2),
		linecolor = :white,
		linewidth = 1,
		arrow = true,
		bg = :black,
		ticks = false,
		showaxis = false,
		legend = false,
		xlims = [0.995, 1.005],
		ylims = [-0.005, 0.005]
	)
	
	scatter!(
		diagram,
		[(1-(3e-6),0)],
		markercolor = :aqua,
		markersize = 4
	)

    return diagram
end

# Plots the trajectory of m starting near Lₙ up to time T, with parameters α and M₁
function trajectory(α, M₁, n, T, lims = [2,1])
	i = findfirst(≥(α), αvals)
    simulatedtrajectory = simulate(αvals[i], M₁, lagrangepoints[i, (2n-1):2n], [0.0, 0.0], T)
	
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
		markersize = [3, 10, 4]
	)
	
	return diagram
end