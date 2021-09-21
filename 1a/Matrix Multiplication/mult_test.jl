### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 463264a9-0f9b-43ee-930f-74730e158372
# we write a function that caculates the product of two matrices A and B
function mult(A,B)

	# we find the sizes of A and B
	aRows, aCols = size(A)
	bRows, bCols = size(B)

	# we check if the matrix sizes are consistent with multiplication
	if aCols != bRows
		error("matrix sizes don't agree")
	end

	# we initialize C to a zero matrix of the appropriate size
	C = zeros(aRows, bCols)

	# we loop over all pairs of rows and columns
	for i = 1:aRows
		for j = 1:bCols
			# and for each pair we store their dot pruduct in C
			for k = 1:aCols
				C[i,j] += A[i,k] * B[k,j];
			end
		end
	end

	# we return C as the answer
	return C
end

# ╔═╡ c089bff8-8b2b-420e-95d4-f40026afb897
md"Simple test"

# ╔═╡ 5d274440-f3b4-4b98-953c-340ca2fb8b8e
A = [1 2; 3 4];

# ╔═╡ a8dc36db-ffc4-4068-af75-890dd3a98819
B = [2 1; 1 3];

# ╔═╡ ab386751-af17-41f9-b032-3735fd3492f4
mult(A, B)

# ╔═╡ 1073d7c1-cd7f-41eb-9531-b7a63c2d6286
md"Check with MATLAB built-in multiplication"

# ╔═╡ eb028ed8-2ff5-4c97-8b98-156f45402c7c
A*B

# ╔═╡ 507e8447-6446-44b3-a230-940254bedb6b
md"Two $100\times 100$ matrices of random numbers"

# ╔═╡ 413585fe-dbe5-4351-88b0-57cb415c31e5
time100 = @elapsed mult(rand(100,100), rand(100,100))

# ╔═╡ f014193b-04d6-430f-83c1-2bee5864ea99
md"Two $200\times 200$ matrices of random numbers"

# ╔═╡ 0faabc1c-a618-4351-9876-9fce4ceab769
time200 = @elapsed mult(rand(200,200), rand(200,200))

# ╔═╡ 31917d5e-28cf-4caf-80a4-50e630094901
md"Two $1000\times 1000$ matrices of random numbers"

# ╔═╡ 7c242e1a-c41c-4e1b-b24b-7343417fbfdd
time1000 = @elapsed mult(rand(1000,1000), rand(1000,1000))

# ╔═╡ 695be13b-3dd7-4943-a339-17872c1d128e
md"""
Now compute the ratio of the times taken for the two different sizes
and compare with the theroetical complexity $O(n^3)$, where $n$ is the size of the matrices. Note the prediction does not match exactly because it is valid only as $n$ tends to infinity, but it is a reasonable guide.
"""

# ╔═╡ 99bdb4c4-4af0-410b-a3f8-3e3e8e13d80f
ratio = time1000/time200

# ╔═╡ 25ae1cca-d886-46ca-9e57-7abd83c7ed86
predictedRatio = (1000/200)^3

# ╔═╡ 23559250-2979-40e1-87b1-f48b7eeee335
md"""
The last part shows that MATLAB is rather efficient at dealing with matrices...
"""

# ╔═╡ 426e472d-c146-41de-bf1f-bbe635a4f8cd
time = @elapsed rand(1000,1000)*rand(1000,1000)

# ╔═╡ Cell order:
# ╠═463264a9-0f9b-43ee-930f-74730e158372
# ╟─c089bff8-8b2b-420e-95d4-f40026afb897
# ╠═5d274440-f3b4-4b98-953c-340ca2fb8b8e
# ╠═a8dc36db-ffc4-4068-af75-890dd3a98819
# ╠═ab386751-af17-41f9-b032-3735fd3492f4
# ╟─1073d7c1-cd7f-41eb-9531-b7a63c2d6286
# ╠═eb028ed8-2ff5-4c97-8b98-156f45402c7c
# ╟─507e8447-6446-44b3-a230-940254bedb6b
# ╠═413585fe-dbe5-4351-88b0-57cb415c31e5
# ╟─f014193b-04d6-430f-83c1-2bee5864ea99
# ╠═0faabc1c-a618-4351-9876-9fce4ceab769
# ╟─31917d5e-28cf-4caf-80a4-50e630094901
# ╠═7c242e1a-c41c-4e1b-b24b-7343417fbfdd
# ╟─695be13b-3dd7-4943-a339-17872c1d128e
# ╠═99bdb4c4-4af0-410b-a3f8-3e3e8e13d80f
# ╠═25ae1cca-d886-46ca-9e57-7abd83c7ed86
# ╟─23559250-2979-40e1-87b1-f48b7eeee335
# ╠═426e472d-c146-41de-bf1f-bbe635a4f8cd
