
using Images
using ImageView
using LinearAlgebra

A = load("../../DATA/dog.jpg")
X = Gray.(A) # Convert RBG -> gray
ny, nx = size(X)

U, S, V = svd(X)

for r = [5, 20, 100] # Truncation value
    Xapprox = U[:, 1:r] * diagm(S)[1:r, 1:r] * V[:, 1:r]' # Approx. image
    imshow(Xapprox)
end