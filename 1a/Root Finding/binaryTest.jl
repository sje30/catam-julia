### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 4cb24885-2f27-400e-a20d-b8152f4c59d3
using LinearAlgebra

# ╔═╡ 5e4375cd-a2a4-4027-88a0-a7ae49fbde1c
# we write a function that returns a root of func in the
# interval [low, high] with relative error tol, assuming such a root exists
function binarySearch(func, low, high, tol)

	# we repeat until the tolorance condition is met
	while abs(high - low)/2 > tol * abs(high + low)/2

		# we define mid as the midpoint of the interval [low, high]
		mid = (low + high)/2

		# we check if the value of func at high and mid have the same sign
		if func(high) * func(mid) > 0

			# and reassign [low, high] accordingly
		    high = mid
		else
		    low = mid
		end
	end

	# we return the avarage of low and high as the approximate root
	return (low + high)/2;
end

# ╔═╡ 4533a6ef-85b5-44e2-a381-f60182886903
# we write an improved version of binarySearch that evaluates func fewer times
# and checks if there is definitely a root in the initial interval
function binarySearchV2(func, low, high, tol)

  # we now also store the values of func at low and high
  f_low = func(low)
  f_high = func(high)

  # we check if the initial interval definitely contains a root
  if f_low * f_high > 0
      error("func(low) and func(high) must have different sign")
  end
  
  # the while loop is similar to before
  while abs(high - low)/2 > tol * abs(low + high)/2
    mid = (low + high)/2

    # we only have one evaluation of func per loop
    f_mid = func(mid)
    
    if f_high * f_mid > 0
        high = mid
        f_high = f_mid
        # in this case f_low stays the same
    else
        low = mid
        f_low = f_mid
        # in this case f_high stays the same
    end
  end
 
  return (low + high)/2
end

# ╔═╡ 977bcb22-8089-49f3-931f-be39cbcd950c
f(x) = exp(x)-4x;

# ╔═╡ 25a35c4d-76aa-406b-b6ba-6cbd960c08b9
zeta = 1e-7;

# ╔═╡ d6406dcf-fda4-4fc3-ba27-8f33ac760c80
md"Both implementations find the same approxiamte root in the interval $(0,1)$."

# ╔═╡ 067c0a97-da55-46b9-9476-396b7d60968f
binarySearch(f, 0, 1, zeta)

# ╔═╡ 8a15ea59-e2fc-4534-84dd-52b3c11abeac
binarySearchV2(f, 0, 1, zeta)

# ╔═╡ 031bddca-90a9-43cd-b5d4-e6ccb41f501e
md"Let's test the case where there is no root in the initial interval. Note that binarySearch does not test whether there is a root it gives a bad answer: it is an **unreliable** function."

# ╔═╡ e53a4200-0d48-4d0a-9b60-ac447eff62d4
binarySearch(f, 1, 2, zeta)

# ╔═╡ 57435047-508b-419a-a1b2-8e5cfa4cbfaf
md"BinarySearchV2 on the other hand includes the initial check."

# ╔═╡ a9fd5fbd-8c6e-45b5-9821-ba64175ec3e0
binarySearchV2(f, 1, 2, zeta)

# ╔═╡ aaf5575d-fb60-43b7-858c-46babc9401b1
md"Let's try it for a more complicated function that involves large matrices. We construct a $n\times n$ matrix with random numbers."

# ╔═╡ ebe48c7f-bae4-4262-b792-0581a0757e0d
n = 4000;

# ╔═╡ 5827d97a-5cf3-4578-90ba-11d07afb84d6
A = rand(n,n);

# ╔═╡ ba659a53-9947-4e2d-b615-c3dcd71b3c18
md"Make a symmetric matrix (for real matrices, M' is the transpose of M)."

# ╔═╡ f997e7f0-26d2-4f90-939b-4776a29d5f66
B = A + A';

# ╔═╡ 25142ed0-b0d2-440a-874b-e49fb7fd198c
g(x) = eigmax(exp.(x*B))-2n;

# ╔═╡ 8dfb5f2b-95ef-4701-b90e-2727aa2b2a32
md"""
This function computes a matrix with elements
$A_{ij} = exp(x B_{ij} )$, computes the largest eigenvalue $\lambda$ of $A$ and returns $\lambda - 2n$.
"""

# ╔═╡ f0fdc7d6-9aa3-4a6c-b2e0-f45706d4ae30
g(0), g(1)

# ╔═╡ fe08f690-93a7-46bb-a110-2cb917d12991
md"""
Since $g$ is continuous and $sign(g(0)) \neq sign(g(1))$, it must have a root in the interval $(0,1)$. 
"""

# ╔═╡ 0ff24d6c-9032-4743-9400-f90a70b0bc11
binarySearchV2(g, 0, 1, zeta)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
"""

# ╔═╡ Cell order:
# ╠═5e4375cd-a2a4-4027-88a0-a7ae49fbde1c
# ╠═4533a6ef-85b5-44e2-a381-f60182886903
# ╠═977bcb22-8089-49f3-931f-be39cbcd950c
# ╠═25a35c4d-76aa-406b-b6ba-6cbd960c08b9
# ╟─d6406dcf-fda4-4fc3-ba27-8f33ac760c80
# ╠═067c0a97-da55-46b9-9476-396b7d60968f
# ╠═8a15ea59-e2fc-4534-84dd-52b3c11abeac
# ╟─031bddca-90a9-43cd-b5d4-e6ccb41f501e
# ╠═e53a4200-0d48-4d0a-9b60-ac447eff62d4
# ╟─57435047-508b-419a-a1b2-8e5cfa4cbfaf
# ╠═a9fd5fbd-8c6e-45b5-9821-ba64175ec3e0
# ╟─aaf5575d-fb60-43b7-858c-46babc9401b1
# ╠═ebe48c7f-bae4-4262-b792-0581a0757e0d
# ╠═5827d97a-5cf3-4578-90ba-11d07afb84d6
# ╟─ba659a53-9947-4e2d-b615-c3dcd71b3c18
# ╠═f997e7f0-26d2-4f90-939b-4776a29d5f66
# ╠═4cb24885-2f27-400e-a20d-b8152f4c59d3
# ╠═25142ed0-b0d2-440a-874b-e49fb7fd198c
# ╟─8dfb5f2b-95ef-4701-b90e-2727aa2b2a32
# ╠═f0fdc7d6-9aa3-4a6c-b2e0-f45706d4ae30
# ╟─fe08f690-93a7-46bb-a110-2cb917d12991
# ╠═0ff24d6c-9032-4743-9400-f90a70b0bc11
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
