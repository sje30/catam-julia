
using Images
using ImageView
using MAT
using LinearAlgebra
using Statistics
using Plots

vars = matread("../../DATA/allFaces.mat")

n = Int(vars["n"])
m = Int(vars["m"])
faces = vars["faces"]
nfaces = Int.(vars["nfaces"])

# We use the first 36 people for training data
trainingFaces = faces[:,1:sum(nfaces[1:36])];
avgFace = mean(trainingFaces, dims = 2) # size n*m by 1

# Compute eigenfaces on mean-subtracted training data
X = trainingFaces - avgFace * ones(1, size(trainingFaces)[2])
U, S, V = svd(X)

imshow(reshape(avgFace, n, m)) # Show avg face
imshow(reshape(U[:,1], n, m))  # Show first eigenface

# Now show eigenface reconstruction of image that was omitted from test set

testFace = faces[:,1+sum(nfaces[1:36])] # First face of person 37
imshow(reshape(testFace, n, m))

testFaceMS = testFace - avgFace
for r = [25, 50, 100, 200, 400, 800, 1600]
    reconFace = avgFace + (U[:,1:r]*(U[:,1:r]'*testFaceMS))
    imshow(reshape(reconFace, n, m))
end


# Project person 2 and 7 onto PC5 and PC6

P1num = 2; # Person number 2
P2num = 7; # Person number 7

P1 = faces[:,1+sum(nfaces[1:P1num-1]):sum(nfaces[1:P1num])]
P2 = faces[:,1+sum(nfaces[1:P2num-1]):sum(nfaces[1:P2num])]

P1 = P1 - avgFace * ones(1, size(P1)[2])
P2 = P2 - avgFace * ones(1, size(P2)[2])

PCAmodes = [5, 6] # Project onto PCA modes 5 and 6
PCACoordsP1 = U[:,PCAmodes]'*P1
PCACoordsP2 = U[:,PCAmodes]'*P2

p1 = scatter(PCACoordsP1[1,:], PCACoordsP1[2,:], mc = :blue, legend = false)
scatter!(PCACoordsP2[1,:], PCACoordsP2[2,:], mc = :red)
