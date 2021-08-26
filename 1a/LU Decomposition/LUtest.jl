### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ baff755d-1b7f-42ad-b7c4-8e8098ceadf2
# we write a function that solves Ly = b for y where L is lower triangular and b is a vector
function Lsolve(L, b)

    # we get the sizes of L and b
    LRows, LCols = size(L)
    bRows = size(b)[1]
 
    # we check that L and b ahve appropriate sizes
    if LRows != LCols || bRows != LRows
        error("The size of L or b is not appropriate")
    end

    # we initialize y to b
    y = copy(b);

    # we loop over the rows of L
    for k = 1:LRows

        # we check that we dont divide by zero
        if L[k,k] == 0
            error("There are zeros on the diagonal of L")
        end

        # we modify y accordingly
        for j = 1:k-1
            y[k] -= L[k,j] * y[j];
        end
        y[k] /= L[k,k];
    end

    # we return y
    return y
end

# ╔═╡ b62739ea-a4df-4516-88a5-59a159053a26
md"Solve $Ly = b$"

# ╔═╡ 15374d6a-ba4a-402b-acd3-3322e6fb189a
L = [1.0 0.0; 2.0 5.0];

# ╔═╡ 48329efb-5c10-4ada-8baf-b5b69a97fc1f
b = [2.0; 3.0];

# ╔═╡ a8948867-db61-4b3d-9e65-f9213783e1c1
y = Lsolve(L, b)

# ╔═╡ 1f47da5b-668b-4471-88c6-0cdfd623e46d
md"Check Lsolve, this should eval to zero:"

# ╔═╡ 7d9856ad-b34f-4277-a7be-a86428c1c56e
L*y-b

# ╔═╡ 3c84b49b-d112-4e8a-ac59-b1961ff2ac1c
md"Test case: b has the wrong size"

# ╔═╡ 4c6ef08d-f462-424f-93b9-d9e4d1425422
bWrong = [2.0; 3.0; 4.0];

# ╔═╡ e1ae3cd5-f6e1-4d63-82ef-e5cf66fc7f64
Lsolve(L, bWrong)

# ╔═╡ eba7f592-fb39-40c6-80b4-931fab81ec96
md"Test case: L is singular"

# ╔═╡ b4a3f8e3-c332-4977-b2c2-e5874d88ee68
Lwrong = [1.0 2.0; 2.0 5.0];

# ╔═╡ 241572c6-3cdc-4147-b2e0-8a6364bc0545
yWrong = Lsolve(Lwrong, b);

# ╔═╡ a7c3d19d-7207-4f24-8c60-1c7d93e2a8b8
Lwrong*yWrong - b

# ╔═╡ 6f6d27f4-c3cd-4ebe-a69a-d522aa5a9503
md"Should be zero but is not... It only looks at the lower triangle of L."

# ╔═╡ 307b2b77-aca1-418b-9084-4816a02fdcf1
# we write a function that solves Ux = y for x where U is upper triangular and y is a vector
function Usolve(U, y)

    # we get the sizes of U and y
    URows, UCols = size(U)
    yRows = size(y)[1]
 
    # we check that U and y ahve appropriate sizes
    if URows != UCols || yRows != URows
        error("The size of U or y is not appropriate")
    end
    
    # we initialize x to y
    x = copy(y);

    # we loop backwards over the rows of U
    for k = URows:-1:1

        # we check that we don't divide by zero
        if U[k,k] == 0
            error("There are zeros on the diagonal of U")
        end

        # we modify x accordingly
        for j = k+1:URows
            x[k] -= U[k,j] * x[j];
        end		
        x[k] /= U[k,k];
    end

    # we return x
    return x
end

# ╔═╡ 499dd3c6-ab18-47c1-a38f-eaee61e2371f
U = [2.0 1.0; 0.0 3.0];

# ╔═╡ 9aa0e987-a432-431c-9200-9a902de25726
md"solve $Ux=y$, this is now the solution to $LUx = b$."

# ╔═╡ f70a999b-a08f-4622-b018-140ef0d0a3e3
x = Usolve(U, y)

# ╔═╡ a357e6fa-691d-4d49-88b0-f42e6a02c886
md"Check Usolve, this should both eval to zero (up to roundoff):"

# ╔═╡ 0116a06e-1771-4c5f-a73b-174524b25e15
L*U*x - b

# ╔═╡ 5e4a3e9c-659d-46d0-8306-705f9231c0f7
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

# ╔═╡ a5248f09-c39c-4a6a-a327-866ae458b8d0
A = rand(5,5);

# ╔═╡ 3060c850-52ed-499b-b29a-1b00d7276d33
LA, UA = LUdecomp(A);

# ╔═╡ 9ffbfac3-21bc-4a19-a982-d58882a860cc
md"Check LUdecomp, this should eval to zero (up to roundoff):"

# ╔═╡ 040b92ed-bfd9-4a9c-b8e8-82fc955af5a3
LA*UA-A

# ╔═╡ 71e7a466-eea0-4b50-8f16-db774235e704
#we write a function that solves Ax = b for x by LU decomposition
function Asolve(A, b)
	L, U = LUdecomp(A)
	y = Lsolve(L, b)
	x = Usolve(U, y)
	return x
end

# ╔═╡ 1d575359-23c0-4236-bd3f-937400fc57ce
b2 = rand(5);

# ╔═╡ d30c113e-45c6-488d-83ff-c2d557e5f776
x2 = Asolve(A,b2);

# ╔═╡ bf6681d4-03b3-4eaa-99c1-236bf8daaa54
md"Check Asolve, this should eval to zero (up to roundoff):"

# ╔═╡ cc526a1c-8f34-4032-b5ae-548b67cac8bb
 A*x2 - b2

# ╔═╡ 20be458b-7b6c-4aff-822a-71969b013c53
md"This will throw an error..."

# ╔═╡ 5e8286c6-268a-47a2-8b4e-e026b42b5671
C = [0.0 1.0; 1.0 0.0];

# ╔═╡ af0082b7-7ee5-4e7f-9492-7e221a1328ab
LC, UC = LUdecomp(C)

# ╔═╡ 9488d28a-b76c-4863-80da-fcefd5ab2d4d
md"Let's try it with a large matrix."

# ╔═╡ d302f22e-c368-4e17-a31e-abd43db74e30
D = rand(800, 800);

# ╔═╡ 5bb781c8-7af0-4ccc-bb44-fe279127c44d
LD, UD = LUdecomp(D);

# ╔═╡ 1d599c5b-ff5b-42b9-bf79-7b67f5dd0d94
md"Largest divaition from zero in $L_DU_D-D$ is basically zero."

# ╔═╡ db2526a8-1a4a-4c00-a26d-8e55f55f1923
max(abs.(LD*UD-D)...)

# ╔═╡ Cell order:
# ╠═baff755d-1b7f-42ad-b7c4-8e8098ceadf2
# ╟─b62739ea-a4df-4516-88a5-59a159053a26
# ╠═15374d6a-ba4a-402b-acd3-3322e6fb189a
# ╠═48329efb-5c10-4ada-8baf-b5b69a97fc1f
# ╠═a8948867-db61-4b3d-9e65-f9213783e1c1
# ╟─1f47da5b-668b-4471-88c6-0cdfd623e46d
# ╠═7d9856ad-b34f-4277-a7be-a86428c1c56e
# ╟─3c84b49b-d112-4e8a-ac59-b1961ff2ac1c
# ╠═4c6ef08d-f462-424f-93b9-d9e4d1425422
# ╠═e1ae3cd5-f6e1-4d63-82ef-e5cf66fc7f64
# ╟─eba7f592-fb39-40c6-80b4-931fab81ec96
# ╠═b4a3f8e3-c332-4977-b2c2-e5874d88ee68
# ╠═241572c6-3cdc-4147-b2e0-8a6364bc0545
# ╠═a7c3d19d-7207-4f24-8c60-1c7d93e2a8b8
# ╟─6f6d27f4-c3cd-4ebe-a69a-d522aa5a9503
# ╠═307b2b77-aca1-418b-9084-4816a02fdcf1
# ╠═499dd3c6-ab18-47c1-a38f-eaee61e2371f
# ╟─9aa0e987-a432-431c-9200-9a902de25726
# ╠═f70a999b-a08f-4622-b018-140ef0d0a3e3
# ╟─a357e6fa-691d-4d49-88b0-f42e6a02c886
# ╠═0116a06e-1771-4c5f-a73b-174524b25e15
# ╠═5e4a3e9c-659d-46d0-8306-705f9231c0f7
# ╠═a5248f09-c39c-4a6a-a327-866ae458b8d0
# ╠═3060c850-52ed-499b-b29a-1b00d7276d33
# ╟─9ffbfac3-21bc-4a19-a982-d58882a860cc
# ╠═040b92ed-bfd9-4a9c-b8e8-82fc955af5a3
# ╠═71e7a466-eea0-4b50-8f16-db774235e704
# ╠═1d575359-23c0-4236-bd3f-937400fc57ce
# ╠═d30c113e-45c6-488d-83ff-c2d557e5f776
# ╟─bf6681d4-03b3-4eaa-99c1-236bf8daaa54
# ╠═cc526a1c-8f34-4032-b5ae-548b67cac8bb
# ╟─20be458b-7b6c-4aff-822a-71969b013c53
# ╠═5e8286c6-268a-47a2-8b4e-e026b42b5671
# ╠═af0082b7-7ee5-4e7f-9492-7e221a1328ab
# ╟─9488d28a-b76c-4863-80da-fcefd5ab2d4d
# ╠═d302f22e-c368-4e17-a31e-abd43db74e30
# ╠═5bb781c8-7af0-4ccc-bb44-fe279127c44d
# ╟─1d599c5b-ff5b-42b9-bf79-7b67f5dd0d94
# ╠═db2526a8-1a4a-4c00-a26d-8e55f55f1923
