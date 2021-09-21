### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 1e037376-8252-41fb-ae95-93bc9011b7fa
# we need to install a special package in order to use the gamma function
using SpecialFunctions

# ╔═╡ 76d6c2d4-e370-4e83-9d04-ca6fc546bdd9
# we write a function that returns the exact volume of a hypersphere in d dimensions
function exactVol(d)
    vol = pi^(d/2) / gamma(1 + d/2)
    return vol
end

# ╔═╡ b58cf6d8-291c-49f4-a61a-51f1a7454651
n = 10000;

# ╔═╡ 2f4a8b5e-f7c9-4abc-b04d-3286207a97b3
dim = 20;

# ╔═╡ 4da795ef-b8d3-4c94-bb89-7eeaca9602fb
md"Exact volume is:"

# ╔═╡ 8d8e10d0-2597-4198-92b1-9ab2ebe4b3c8
exV = exactVol(dim)

# ╔═╡ 6a8c6c37-2a48-47c7-8d40-ca276c8a09d2
# we write a function that returns a random vector from [0,1]^d with exponential density
function randExp(d, lam)

	# we generate a uniformly random vector
	y = rand(d)

	# we transform (elementwise) to random numbers in [exp(-lambda),1]
	y = exp(-lam) .+ (1-exp(-lam))*y
	
	# we now get numbers with exponential density
	x = -log.(y)/lam
	return x
end

# ╔═╡ 8de1cad7-ac2c-42ec-9581-1d7ff06d576d
# we write an improoved function that uses Monte Carlo with exponential importance sampling
# to estimate the volume of the unit hypersphere in d dimensions.
# We choose our points x with independent Cartesian components and prob density exp(-lam.xi) / [ lam*((1-exp(-lam)) ].
# We achieve this by taking xi = (1/lam) log (1/y) where y is chosen uniformly in (exp(-lam),1)
function sphereVolMCImpExp(d, n, lam)
	count = 0.0
	for i = 1:n

		# we generate x according to our distribution
		x = randExp(d, lam)

		# we calculate the squared norm of x and check if x is inside the hypersphere
		norm2 = x' * x
		if norm2 < 1

			# we compute the density at x
			rho = 1
			for i = 1:d

				# note that y(i) = exp(-lam * x(i))
				rho *= exp(-lam*x[i]) * lam / (1-exp(-lam))
			end
			count += 1/rho
		end
	end
	vol =  2^d * count / n
	return vol
end

# ╔═╡ c8381d29-3b9f-4399-9a60-c0b6b620e99c
sphereVolMCImpExp(20, n, 2)

# ╔═╡ 0e1580e1-cdae-498e-ab14-261f8a96a802
md" We do the calculation $m$ times and check mean/variance:"

# ╔═╡ 770e2019-420d-415b-b498-96493ac676bf
m = 1000;

# ╔═╡ dc6e6729-7ce5-45a8-8ecc-b320d283340a
data = [sphereVolMCImpExp(20, n, 2) for i in 1:m];

# ╔═╡ fb6c8ff3-d200-4e48-b9ad-aa34d188e675
mean = sum(data)/m

# ╔═╡ 48b51297-b3fb-4bce-8d41-7af6120b553c
error = mean - exV

# ╔═╡ bb18d766-cdad-45b7-aebb-c59763896bd4
variance = sum(broadcast(x -> (x-mean)^2, data))/m

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[compat]
SpecialFunctions = "~1.6.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "bdc0937269321858ab2a4f288486cb258b9a0af7"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.3.0"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "727e463cfebd0c7b999bbf3e9e7e16f254b94193"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.34.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "a32185f5428d3986f47c2ab78b1f216d5e6cc96f"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.5"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[IrrationalConstants]]
git-tree-sha1 = "f76424439413893a832026ca355fe273e93bce94"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "3d682c07e6dd250ed082f883dc88aee7996bf2cc"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.0"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[SpecialFunctions]]
deps = ["ChainRulesCore", "LogExpFunctions", "OpenSpecFun_jll"]
git-tree-sha1 = "a322a9493e49c5f3a10b50df3aedaf1cdb3244b7"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "1.6.1"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╠═1e037376-8252-41fb-ae95-93bc9011b7fa
# ╠═76d6c2d4-e370-4e83-9d04-ca6fc546bdd9
# ╠═b58cf6d8-291c-49f4-a61a-51f1a7454651
# ╠═2f4a8b5e-f7c9-4abc-b04d-3286207a97b3
# ╟─4da795ef-b8d3-4c94-bb89-7eeaca9602fb
# ╠═8d8e10d0-2597-4198-92b1-9ab2ebe4b3c8
# ╠═6a8c6c37-2a48-47c7-8d40-ca276c8a09d2
# ╠═8de1cad7-ac2c-42ec-9581-1d7ff06d576d
# ╠═c8381d29-3b9f-4399-9a60-c0b6b620e99c
# ╟─0e1580e1-cdae-498e-ab14-261f8a96a802
# ╠═770e2019-420d-415b-b498-96493ac676bf
# ╠═dc6e6729-7ce5-45a8-8ecc-b320d283340a
# ╠═fb6c8ff3-d200-4e48-b9ad-aa34d188e675
# ╠═48b51297-b3fb-4bce-8d41-7af6120b553c
# ╠═bb18d766-cdad-45b7-aebb-c59763896bd4
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
