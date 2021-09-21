### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 61078404-224f-44f1-a75a-9b3537ecc95c
# we write a function that decomposes a square matrix A as A = LU
# where L is lower triangular and U is upper triangular
function LUdecomp(A)

    # we get the size of A
    n, m = size(A)

    # we check if A is indeed a square matrix
    if n != m
        error("Input must be a square matrix")
    end

    # we initialize the output matrices
    L = zeros(n, n)
    U = zeros(n, n)

    # we make a copy of A in order not to modify the original
    B = copy(A)

    for k = 1:n

        # we set the entries of the kth row of U
        for j = k:n
            U[k,j] = B[k,j]
        end

        # we check that we don't divide by zero
        if U[k,k] == 0
            error("** A^(k-1)_{k,k} == 0 in LU decomp")
        end

        # we set the entries of the kth column of L
        for i = k:n
           L[i,k] = B[i,k] / U[k,k]
        end

        # we modify A for the next iteration
        for i = k:n
            for j = k:n
                B[i,j] -= L[i,k] * U[k,j]
            end
        end
    end

    # we return L and U
    return (L, U)
end

# ╔═╡ 4996c2fe-068b-11ec-221d-5fdd71b0f050
md"Simple matrix for which there is no LUdecomp:"

# ╔═╡ 41b2c106-e317-4d65-bb61-94cecb4683a2
A = [0.0 2.0; 3.0 1.0];

# ╔═╡ 75d691e3-34e6-4506-b9b6-559c2412d791
md"This will cause an error:"

# ╔═╡ ffa8307d-751a-42d7-8a5d-ce8a3e92ca0d
LUdecomp(A);

# ╔═╡ a2c516ea-c23f-4f25-8e39-b5213e6fb94e
# we write a function that returns the row index of the (absolutely) largest element in column k of the matrix A
function findLargestInCol(A, k)

	# we get column k
	col = A[:,k]

	# we take elementwise absolute value
	absCol = broadcast(abs, col)

	# we get the index of the largest element
	index = argmax(absCol)

	# we return index
	return index
end

# ╔═╡ ca343c99-8fa8-4489-8c57-3e8afc1fbe71
# we write a more efficient function that swaps rows u and v of some matrix A
function swapRowsV2!(A, u, v)

	# we directly swap rows u and v of A without copying
	temp = A[u, :]
	A[u, :] = A[v, :]
	A[v, :] = temp
end

# ╔═╡ e10c36a3-d0c0-4f63-ac43-f1f04eff1e19
# we write another function that composes A into A = P^{-1}LU where P is stored as a vector and swapRows is more efficient
function PALUdecompV2(A)

    # we get the size of A
    m, n = size(A)

    # we check that A is indeed a square matrix
    if m != n
        error("Input must be a square matrix")
    end

    # we initialize L and U to zero, P to {1,2, ..., n}
    L = zeros(n, n)
    U = zeros(n, n)
    p = collect(1:n)

    # we make a copy of A to work with
    B = copy(A)

    for k = 1:n

        # we find the pivot
        maxk = findLargestInCol(B, k)
        if maxk != k
            swapRowsV2!(B, maxk, k)
            swapRowsV2!(L, maxk, k)
            
            # we swap two elements of P instead of two rows
            temp = p[maxk]
            p[maxk] = p[k]
            p[k] = temp
        end
        
        # we proceed with the normal LU decomposition algorithm
        for j = k:n
            U[k,j] = B[k,j]
        end

        # we check that we don't divide by zero
        if U[k,k] == 0
            error("** A^(k-1)_{k,k} == 0 in PALU decomp")
        end

        for i = k:n
           L[i,k] = B[i,k] / U[k,k]
        end

        for i = k:n
            for j = k:n
                B[i,j] -= L[i,k] * U[k,j];
            end
        end
    end
	
	P = zeros(n,n)
	for i = 1:n
		P[i,p[i]] = 1
	end

    # we return P, L and U
    return P, L, U
end

# ╔═╡ a0f23d95-18a5-427f-b52c-ebdb44df8fa3
PA, LA, UA = PALUdecompV2(A);

# ╔═╡ 23babfbd-d571-454e-8598-3fc9a9044baa
LA*UA == PA*A

# ╔═╡ a5570224-5282-48a3-8f5a-7f5f7a9b741c
md"""
Slightly less trivial example where the error appears in step $k=2$. The problem arises because $B_{22} = B_{21} B_{12} / B_{11}$ so in the usual LU decomposition $A^{1}_{22}$ is zero:
"""

# ╔═╡ 1dd12bff-9da3-4f26-ab3c-23a0e2671aa1
B = [1.0 2.0 3.0; 2.0 4.0 2.0; 1.0 3.0 2.0];

# ╔═╡ 5a34190b-5c77-4732-9134-c6bd432c053c
LUdecomp(B)

# ╔═╡ 751479d0-269c-4be3-893c-1317f9707b5f
PB, LB, UB = PALUdecompV2(B);

# ╔═╡ f5229f99-e78b-48e0-853e-ea1b50aa2633
LB*UB == PB*B

# ╔═╡ 3304fcdb-923f-4b21-932d-cdbfa1c4b243
md"Check that LUdecomp of $PB$ gives the same answer:"

# ╔═╡ b76c8925-323f-423d-98b0-a42bb7ef4f60
LUdecomp(PB*B) == (LB, UB)

# ╔═╡ 344175ec-c622-4967-8f4d-4c1507886f7a
md"Bigger matrix..."

# ╔═╡ 7bfae705-78ff-4f4b-8f85-4f623488d632
C = rand(800, 800);

# ╔═╡ 5c497b8f-d2a3-4609-bd5d-891fe21a4714
PC, LC, UC = PALUdecompV2(C);

# ╔═╡ 5c8e5b61-137e-401b-96f5-df3c9ffaa9dd
md"Estimate 'error' as sum of squares of elements of $LU-PA$:"

# ╔═╡ f76c12c0-3a8e-4ef1-b8dc-a5b2eaf8a761
sum((LC*UC-PC*C).^2)

# ╔═╡ Cell order:
# ╠═61078404-224f-44f1-a75a-9b3537ecc95c
# ╟─4996c2fe-068b-11ec-221d-5fdd71b0f050
# ╠═41b2c106-e317-4d65-bb61-94cecb4683a2
# ╟─75d691e3-34e6-4506-b9b6-559c2412d791
# ╠═ffa8307d-751a-42d7-8a5d-ce8a3e92ca0d
# ╠═a2c516ea-c23f-4f25-8e39-b5213e6fb94e
# ╠═ca343c99-8fa8-4489-8c57-3e8afc1fbe71
# ╠═e10c36a3-d0c0-4f63-ac43-f1f04eff1e19
# ╠═a0f23d95-18a5-427f-b52c-ebdb44df8fa3
# ╠═23babfbd-d571-454e-8598-3fc9a9044baa
# ╟─a5570224-5282-48a3-8f5a-7f5f7a9b741c
# ╠═1dd12bff-9da3-4f26-ab3c-23a0e2671aa1
# ╠═5a34190b-5c77-4732-9134-c6bd432c053c
# ╠═f5229f99-e78b-48e0-853e-ea1b50aa2633
# ╠═751479d0-269c-4be3-893c-1317f9707b5f
# ╟─3304fcdb-923f-4b21-932d-cdbfa1c4b243
# ╠═b76c8925-323f-423d-98b0-a42bb7ef4f60
# ╟─344175ec-c622-4967-8f4d-4c1507886f7a
# ╠═7bfae705-78ff-4f4b-8f85-4f623488d632
# ╠═5c497b8f-d2a3-4609-bd5d-891fe21a4714
# ╟─5c8e5b61-137e-401b-96f5-df3c9ffaa9dd
# ╠═f76c12c0-3a8e-4ef1-b8dc-a5b2eaf8a761
