
using LinearAlgebra
using Plots
using Images
using ImageView

n = 1000
X = zeros(n, n)
X[250:750, 250:750] .= 1
U, S, V = svd(X)
imshow(X)
p1 = plot(S, yaxis = :log)

nAngles = 12 # sweep through 12 angles, from 0:4:44

for j = 2:nAngles
    Y = imrotate(X, -(j-1)*4*pi/180, axes(X)) # rotate by (j-1)*4
    Y[isnan.(Y)] .= 0 
    U2, S2, V2 = svd(Y)
    plot!(S2)
end
