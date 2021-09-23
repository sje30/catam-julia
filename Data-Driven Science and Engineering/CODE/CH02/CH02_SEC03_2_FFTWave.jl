
using FFTW
using DifferentialEquations
using Plots

# Define spatial domain
c = 2 # Wave speed
L = 20 # Length of domain 
N = 1000 # Number of discretization points
dx = L/N
x = -L/2:dx:L/2-dx # Define x domain

# Define discrete wavenumbers
kappa = (2pi/L)*(-N/2:N/2-1)
kappa = fftshift(kappa) # Re-order fft wavenumbers

# Initial condition 
u0 = sech.(x)       
uhat0 = fft(u0)

# Simulate in Fourier frequency domain
f(u, p, t) = -c*im*kappa.*u
prob = ODEProblem(f, uhat0, (0.0,2.5))
uhat = solve(prob)

# Inverse FFT to bring back to spatial domain
u = zeros(size(uhat))
for k = 1:size(u)[2]
    u[:,k] = real(ifft(uhat[:,k]))
end

# Alternatively, simulate in spatial domain
f2(u, p, t) = -c*real.(ifft(im*kappa.*fft(u)))
prob2 = ODEProblem(f2, u0, (0.0,2.5))
u2 = solve(prob2)

# Plot solution in time
p1 = surface(u)
p2 = surface(hcat(u2.u...))