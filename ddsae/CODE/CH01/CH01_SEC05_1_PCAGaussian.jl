
using Plots
using LinearAlgebra
using Distributions

xC = [2, 1] # Center of data (mean)
sig = [2, 0.5] # Principal axes

theta = pi/3 # Rotate cloud by pi/3
R = [cos(theta) -sin(theta); sin(theta) cos(theta)] # Rotation matrix

nPoints = 10000 # Create 10,000 points
X = R*diagm(sig)*rand(Normal(), 2, nPoints) + diagm(xC)*ones(2, nPoints); 

p1 = scatter(X[1,:], X[2,:]) # Plot cloud of noisy data

# f_ch01_ex03_1b

Xavg = [sum(X[1,:]); sum(X[2,:])]/nPoints # Compute mean
B = X - Xavg*ones(1,nPoints) # Mean-subtracted Data
U, S, V = svd(B/sqrt(nPoints)) # Find principal components (SVD)

theta = 2pi*(0:0.01:1)
Xstd = hcat([U*[S[1]*cos(t); S[2]*sin(t)] for t in theta]...) # 1-std confidence interval
p2 = plot(Xstd[1,:] .+ Xavg[1], Xstd[2,:] .+ Xavg[2])
plot!(2*Xstd[1,:] .+ Xavg[1], 2*Xstd[2,:] .+ Xavg[2])
plot!(3*Xstd[1,:] .+ Xavg[1], 3*Xstd[2,:] .+ Xavg[2])

# Plot principal components
# p3 = scatter([Tuple(Xavg + U[:,1]*S[1]), Tuple(Xavg + U[:,2]*S[2])])
