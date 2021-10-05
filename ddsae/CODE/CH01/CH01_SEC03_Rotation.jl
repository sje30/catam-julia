
using Plots
using LinearAlgebra

theta = [pi/15, -pi/9, -pi/20] 
Sigma = diagm([3.0, 1.0, 0.5]) # scale x, then y, then z

Rx = [1 0 0; 0 cos(theta[1]) -sin(theta[1]);  0 sin(theta[1]) cos(theta[1])] # rotate about x-axis
Ry = [cos(theta[2]) 0 sin(theta[2]); 0 1 0; -sin(theta[2]) 0 cos(theta[2])] # rotate about y-axis
Rz = [cos(theta[3]) -sin(theta[3]) 0; sin(theta[3]) cos(theta[3]) 0; 0 0 1] # rotate about z-axis

X = Rz*Ry*Rx*Sigma

# Plot sphere
n = 100
u = range(0, stop = 2pi, length = n)
v = range(0, stop = pi, length = n)

x = cos.(u) * sin.(v)'
y = sin.(u) * sin.(v)'
z = ones(n) * cos.(v)'

p1 = plot(x, y, z, legend = false)

xR = zeros(n, n)
yR = zeros(n, n)
zR = zeros(n, n)

for i = 1:n
    for j = 1:n
        vecR = X*[x[i,j]; y[i,j]; z[i,j]]
        xR[i,j] = vecR[1]
        yR[i,j] = vecR[2]
        zR[i,j] = vecR[3]        
    end
end

p2 = plot(xR, yR, zR, legend = false)