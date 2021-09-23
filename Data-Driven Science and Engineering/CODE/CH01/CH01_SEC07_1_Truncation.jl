
using Images
using ImageView
using LinearAlgebra
using Plots

t = -3:.01:3

Utrue = [cos.(17*t).*exp.(-t.^2) sin.(11*t)]
Strue = [2.0 0.0; 0.0 0.5]
Vtrue = [sin.(5*t).*exp.(-t.^2) cos.(13*t)]

X = Utrue*Strue*Vtrue'
imshow(X)

sigma = 1
Xnoisy = X+sigma*randn(size(X))
imshow(Xnoisy)

U, S, V = svd(Xnoisy)

N = size(Xnoisy)[1]
cutoff = (4/sqrt(3))*sqrt(N)*sigma # Hard threshold
r = sum(S .> cutoff) # Keep modes w/ sig > cutoff
Xclean = U[:,1:r]*diagm(S[1:r])*V[:,1:r]'
imshow(Xclean)

cdS = cumsum(S)/sum(S) # Cumulative energy
r90 = sum(cdS .> 0.90) # Find r to capture 90% energy

X90 = U[:,1:r90]*diagm(S[1:r90])*V[:,1:r90]'
imshow(X90)

# plot singular values

p1 = plot(S, yaxis = :log, legend = false)
p2 = plot(S[1:r], yaxis = :log, legend = false)
     
p3 = plot(cdS, legend = false)
p4 = plot(cdS[1:r90], legend = false)
p5 = plot(cdS[1:r], legend = false)