
using Plots
using LinearAlgebra

dx = 0.001
L = pi
x = L * (-1+dx:dx:1)
n = length(x)
nquart = Int(floor(n/4))

# Define hat function
f = zeros(n);
f[nquart:2*nquart] = 4*(1:nquart+1)/n
f[2*nquart+1:3*nquart] = (-4*(0:nquart-1).+1)/n

p1 = plot(x, f)

# Compute Fourier series

A0 = sum(f) * dx

fFS = A0/2
A = zeros(20)
B = zeros(20)

for k = 1:20
    A[k] = sum(f.*cos.(pi*k*x/L)) * dx
    B[k] = sum(f.*sin.(pi*k*x/L)) * dx
    global fFS = A[k]*cos.(k*pi*x/L) .+ B[k]*sin.(k*pi*x/L) .+ fFS
    plot!(x, fFS)
end

fFS2 = A0/2

kmax = 100
A2 = zeros(kmax+1)
B2 = zeros(kmax+1)
ERR = zeros(kmax+1)

A2[1] = A0/2
ERR[1] = norm(f-fFS)
p2 = plot(x, f)

for k = 1:kmax
    A2[k+1] = sum(f.*cos.(pi*k*x/L)) * dx
    B2[k+1] = sum(f.*sin.(pi*k*x/L)) * dx
    plot!(x, B2[k] * sin.(2k*pi*x/L))
    global fFS2 = A2[k+1]*cos.(k*pi*x/L) .+ B2[k+1]*sin.(k*pi*x/L) .+ fFS2
    ERR[k+1] = norm(f-fFS2)/norm(f)
end

p3 = plot(0:kmax, A2)
p4 = plot(0:kmax, ERR, yaxis = :log)
