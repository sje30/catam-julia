
using Plots

dx = 0.01
L = 10
x = 0:dx:L
n = length(x)
nquart = Int(floor(n/4))

f = zeros(n)
f[nquart:3nquart] .= 1

A0 = (2nquart+1)*dx*2/L
fFS = A0/2

for k = 1:100
    Ak = sum(f.*cos.(2pi*k*x/L))*dx*2/L
    Bk = sum(f.*sin.(2pi*k*x/L))*dx*2/L
    global fFS = Ak*cos.(2pi*k*x/L) .+ Bk*sin.(2pi*k*x/L) .+ fFS
end

p1 = plot(x, f)
plot!(x, fFS)