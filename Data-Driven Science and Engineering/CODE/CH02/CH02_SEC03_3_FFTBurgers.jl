
using FFTW
using DifferentialEquations
using Plots

nu = 0.001 # Diffusion constant

# Define spatial domain
L = 20 # Length of domain 
N = 1000 # Number of discretization points
dx = L/N
x = -L/2:dx:L/2-dx # Define x domain

# Define discrete wavenumbers
kappa = (2pi/L)*(-N/2:N/2-1)
kappa = fftshift(kappa) # Re-order fft wavenumbers

# Initial condition 
u0 = sech.(x)       

# Simulate PDE in spatial domain
f(u, p, t) = real.(-u.*ifft(im*kappa.*fft(u)) + nu*ifft(-(kappa.^2).*fft(u)))
prob = ODEProblem(f, u0, (0.0,2.5))
u = solve(prob)

# Plot solution in time
p1 = surface(hcat(u.u...))