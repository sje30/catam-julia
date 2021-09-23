
using Images
using ImageView
using LinearAlgebra
using Plots

n = 1000 # 1000 x 1000 square
X = zeros(n, n)
X[250:750, 250:750] .= 1
imshow(X)

Xrot = imrotate(X, -pi/18, axes(X))
Xrot[isnan.(Xrot)] .= 0
imshow(Xrot)

U, S, V = svd(X) # SVD well-aligned square
U2, S2, V2 = svd(Xrot) # SVD rotated square
p1 = plot(S, yaxis = :log)
p2 = plot(S2, yaxis = :log)