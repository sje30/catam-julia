### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 73a77da6-7ec7-4460-9542-bb994676a375
using Plots

# ╔═╡ 25afb2d2-f437-11eb-327c-496dc439ccfa
md"""
# Finding Prime Numbers and Matters of Efficiency
"""

# ╔═╡ b735e72f-1498-4bf7-9f30-93a46aa46392
md"""
## Objectives
- Introduce asymptotic runtime analysis with "big O" notation 
- Compare different approaches for finding prime numbers in regard to their efficiency
- Measure runtimes practically with the tools built into julia
- Statistically varify certain theorems about the distribution of primes
"""

# ╔═╡ 480b1c62-9a1d-4504-8872-c388403bec0b
md"""
## Why do we care about Primes?
There is no doubt that prime numbers play an important role in modern day mathematics. They appear in almost all areas of study and are still not understood as well as their simple definition would suggest. But why should one care about computing primes on a computer?

### Statistical Data inspires Research
Almost all conjectures about the distributions of primes throughout history have been motivated through data. Likewise, new conjectures about the primes inspired by theoretical observations can be checked against a list of small primes, either showing a concrete contradiction or boosting the mathematicians confidence in their conjecture.

### Computational Proofs
Often, proofs about prime numbers are reduced to a finite case check of small primes which then can be checked by a computer.

### Cryptography
Many traditional encryption algorithm make use of the fact that there is no algorithm (yet) for decomposing a number into prime factors quickly. Therefore, there is a big need in cryptography for novel large prime numbers.
"""

# ╔═╡ 6164b325-44b8-478e-a122-a871c44d7ab1
md"""
## Asymptotic Runtime Analysis
When analysing an algorithm theoretically, we are interested in counting the number of "elementary operations" as a function of the input size. An elementary operation, also sometimes called a zero operation, is any algorithmic step that can be performed by the computer in constant time. Elementary operations include addition, multiplication, division, modulus calculations, conditional checks, etc
While the time to perform some of these operations, for example multiplication, does depend on the size of the numbers involved, modern computers have specific processor instructions to run such operations directly on the hardware in negligible time.

### The "Big O" Notation
When counting elementary operations, we are usually only interested in its growth rate with respect to the input size. To express this we make use of the following:

_**Definition:**_ For functions $f,g:\mathbb{R}\to\mathbb{R}$ we say that $f$ is $O(g)$ if there exist constants $M$ and $x_0$ such that $|f(x)| \leq Mg(x)$ for all $x \geq x_0$.

For example, we have:
- The function $x\to 3x^2+100x-3$ is $O(x^2)$
- The function $x\to \log(x!)$ is $O(x\log x)$
- The function $x\to \binom{x}{k}$ is $O(x^k)$ for any fixed $k$
- The function $x\to \sqrt{x} + (\log x)^k$ is $O(\sqrt{x})$ for any fixed $k$

Note that this is just an upper bound on the asymptotic behaviour. A function that is $O(x^2)$ for example could also be $O(x)$ or even smaller. Finding the best upper bound however can generally speaking be very hard.
"""

# ╔═╡ 24f264de-60d8-463b-8907-0a43f8297e52
md"""
## Finding Primes

In this section we will discuss increasingly efficient methods for finding all the prime numbers up to some integer N. We are particularly interested in analyzing the runtime of our algorithms as N grows very large.

### A Naive Approach
In order to check if a given integer n is prime, the most canonical algorithm just counts the number of divisors of n by running though all the integers less than or equal to n. If the number of divisors is exactly 2, we have found ourselves a prime.
"""

# ╔═╡ 53cd01c6-0090-47a0-ad59-63950fe471c1
function isPrime(n)
	count = 0
	for k in 1:n
		if n % k == 0
			count += 1
		end
	end
	return count == 2
end

# ╔═╡ e3525717-d598-4730-9ee0-b65ea09f7ce0
md"""
Now to find all the primes up to N, we can just run through all the positive integers less than or equal to N, add each integer to our list if it passes our primality test.
"""

# ╔═╡ 9f7705cb-775b-4e86-bc70-70b2e852fbc2
function findPrimes(N)
	primes = []
	for n in 1:N
		if isPrime(n)
			append!(primes, n)
		end
	end
	return primes
end

# ╔═╡ 48e8d826-a81c-42fa-910b-abd3d80a230d
md"""
We can check that our code works by making it find all the 25 primes less than one hundred:
"""

# ╔═╡ a3d579fc-b5d9-4662-9823-b171e4a29fab
findPrimes(100)

# ╔═╡ dc109446-aa32-4fb7-8f74-edc0c6f98c6a
md"""
For most applications and in order to have some meaningful statistics, we need many more primes. Let's say we therefore want to use our algorithm to find all primes up to 100,000.
"""

# ╔═╡ a346aa06-7db4-4d7a-aad8-bf005c294c67
@time findPrimes(100000)

# ╔═╡ ba0eae87-4eec-4387-a210-64e0f2126f87
md"""
Our algorithm took about 25 seconds! If we want to go higher, our aim must be to get this time down dramatically. Running the algorithm for one million, we already have no chance of getting a result anytime soon...
"""

# ╔═╡ e5293427-7721-4a89-ab7b-0c8fb4a618cf
md"""
Let's analyze what we have so far. The benefit of an algorithm as simple as the one we wrote, is that it is easy to analyse: Our algorithm calls the function isPrime once for every integer $n$ in the range $1$ to $N$. Since the procedure `isPrime(n)``
 itself runs through all positive integers up to n, the code inside the inner most loop therefore runs approximately $1+2+3+\cdots+N = N(N+1)/2$ times in total. All the operations like checking divisibility or appending to a vector can be taken as elementary and we conclude that our algorithm has time complexity $O(N^2)$.
"""

# ╔═╡ af8fa992-1bc8-4896-8f6c-8edf3f19c475
md"""
We can also analyse our algorithm experimentally. In order to do so, we write a little function that runs any algorithm we give it at equally spaced input values and plots the runtime against input size. Note that in julia we can use the `@elapsed` modifier to get the runtime of any function in seconds and we need to import the package `Plots` to use its plotting functionality:
"""

# ╔═╡ aa777745-618a-4681-b73a-1a1ca978d165
function plotTime(f, step, num)
	inputs = []
	times = []
	for i in 1:num
		append!(inputs, i * step)
		append!(times, @elapsed f(i * step))
	end
	plot(inputs, times, xlabel = "N", ylabel = "time (seconds)", legend = false)
end

# ╔═╡ 656b291e-f430-4e32-a3c9-87553cf2b1a5
plotTime(findPrimes, 5000, 20)

# ╔═╡ 7c8670bf-85f6-438c-b9d7-a9b1ca4a6c01
md"""
The resulting plot clearly demonstrates the quadratic growth we predicted theoretically. It is always useful to also analyse runtime with experimentation, since efficiency is also heavily influenced by things like cache locality, the branch predictor, multithreading features, etc.
"""

# ╔═╡ a4232c06-eb44-4f7c-a8eb-09aa524cc1a7
md"""
### Using All Available Information
One observation that allows us to improve the efficiency of our algorithm is that when checking for the existence of divisors, we only have to check for prime divisors! Since we are finding all the prime numbers in order, whenever we are checking if $n$ is prime, we already have a list of all primes less than $n$ at hand. Let's see how we would write an improved version of the function `isPrime`, which now not only takes a positive integer $n$ as input, but also the list of all primes less than $n$:
"""

# ╔═╡ f4b38f40-6c51-430a-a7fd-5029e3b6ab0f
function isPrimeV2(primes, n)
	if n < 2 return false end
	answer = true
    for p in primes
        if n % p == 0
			answer = false
		end
    end
    return answer
end

# ╔═╡ 17fa50b7-afee-42f9-b622-d18ef1060720
md"""
Note that now we have to exclude the cases $n < 2$ explicitly, as for these inputs the list of smaller primes would be empty. Let's now use this new, improved version of `isPrime` to write an improved `findPrimes` function.
"""

# ╔═╡ 519ce97d-fde8-49c7-8b92-56185bd02333
function findPrimesV2(N)
	primes = []
	for n in 1:N
		if isPrimeV2(primes, n)
			append!(primes, n)
		end
	end
	return primes
end

# ╔═╡ 9e76abdc-ddf9-4edd-a40d-059706f556d0
@time findPrimesV2(100_000)

# ╔═╡ ae3c3fa7-0581-46e1-a3f3-abe49173ed1c
md"""
Surprisingly we find that with this new version of our algorithm, finding all the primes up to 10000 takes about twice as long! But given that we clearly perform fewer iterations of our loop, how could that possibly be?
"""

# ╔═╡ 2b4873be-3cb7-4c2a-b8a0-451baddf428f
md"""
Let's investigate how the runtime complexity of our algorithms has changed. To do so, we will make use of a very famous result about prime numbers:

_**Prime Number Theorem:**_ The number of primes up to $N$ is asymptotically $N/\log N$.
"""


# ╔═╡ c28f9636-7d0c-4bd2-9c4d-bfc127ea06bc
md"""
Instead of $1+2+3+\cdots + N = N(N+1)/2$ iterations of the inner loop we therfore have approximately $2/\log(2) + 3/\log(3) + \cdots + N/\log(N)\leq \frac{N(N+1)/2}{\log((N+1)/2)}$, using concavity of the function $x/\log(x)$ for $x > e^2$. Note that since we only care about the asymptotic behaviour of the expression, there is no problem with dropping the first term of the series to avoid the pole of $x/\log(x)$ at $1$. The runtime complexity is therefore at most $O(N^2/\log(N))$ and as $N$ grows large we have succesfully shaved of a factor of $\log(N)$.
"""

# ╔═╡ ce2733ab-10a6-4e87-aae4-ed30fa346823
md"""
### Using Some Mathematical Insight
Our algorithms can be made much more efficient when considering the following property of a positive integer:


_**Lemma:**_ If an integer $n\geq 2$ has no prime divisor $p \leq \sqrt n$, then it is prime.


It is easy to see why this is the case, since if $n$ were to be composite, it would need to have at least one divisor $d > \sqrt n$, but then the number $n/d$ is also a divisor of $n$ and less than $\sqrt n$. The smallest prime divisor of $n$ is therefore also less than $\sqrt n$, a contradiction.
"""

# ╔═╡ aa396120-1a8d-4d13-9558-1faad05f76c7
md"""
In general, removing unnecessary work is a very effective way of making algorithms more efficient. Especially when it is possible to break out of nested loops early, we can often gain order of magnitudes in performance. Let's see how this translates into our code. Instead of the procedure `isPrime(n)` running through all positive integers up to $n$, we can break out of the loop as soon as we pass $\sqrt n$. Note that we have to be slightly careful, as in the case where $n$ is the square of a prime, it is essential that we still check $\sqrt n$ itself as a divisor.
"""

# ╔═╡ 5f99ba92-7c35-4e6b-a3fc-f42178c43cad
function isPrimeV3(primes, n)
	if n < 2 return false end
	answer = true
    for p in primes
		if p > sqrt(n) break end
        if n % p == 0 answer = false end
    end
    return answer
end

# ╔═╡ 3b53142b-d6bd-49e3-91b5-689cdb1cac01
function findPrimesV3(N)
	primes = []
	for n in 1:N
		if isPrimeV3(primes, n)
			append!(primes, n)
		end
	end
	return primes
end

# ╔═╡ bc2831a1-f808-4bc7-afaf-994abefb5286
@time findPrimesV3(100000)

# ╔═╡ 157a17af-eb12-4d6d-be12-37a1b609005d
md"""
We have reduced the runtime for `findPrimes(100000)` from 25 seconds down to 1 second! And all of that not by using some advanced mathematics, but just removing unnecessary work. Lets see how far we can push our algorithm now:
"""

# ╔═╡ 54c591db-16c9-4c9e-9d01-444558af9c6e
findPrimesV3(1_000_000)
1
# ╔═╡ 6e319277-a897-49aa-9e78-7a905a11dc89
md"""
Finding all primes up to one million in just 13 seconds, that's pretty fast now. Let us also analyse the runtime of our improved version theoretically: Instead of the approximate $2/\log(2) + 3/\log(3) + \cdots + N/\log(N)$ iterations, we now have approximately $\sqrt 2/\log(\sqrt 2) + \sqrt 3/\log(\sqrt 3) + \cdots + \sqrt N/\log(\sqrt N)\leq \frac{N\sqrt{(N+1)/2})}{\log(\sqrt{(N+1)/2})}$, again using concavity, this time of the function $\sqrt x/\log(\sqrt x)$ for $x > e^{2\sqrt 2}$. We get a runtime complexity of $O(N^{3/2}/\log(N))$, a factor $\sqrt N$ better than before. This efficiency gain is much greater than the previous ones, as $\sqrt N$ grows much faster than $\log(N)$ for large $N$.
"""

# ╔═╡ 3ed289cd-6ace-442f-a9b4-7fe109af5e49
md"""
### Don't do any Unnecessary Work
Pushing the idea of removing unnecessary work further, we realise that there is another place where we can break out of the loop early: When we find a prime divisor of $n$, there is no need to continue looking. Instead, as soon as we find a prime that divides $n$ we should immediately break out of the loop.
"""

# ╔═╡ acda705d-1e1a-4b5f-ba15-0c7d3bdbd5d4
function isPrimeV4(primes, n)
    for p in primes
		if p > sqrt(n) return true end
		if n % p == 0 return false end
    end
    return true
end

# ╔═╡ 7ccb1dea-7a69-47f4-964b-fc7799c58b8a
md"""
Similarly, we don't have to check for the case $n < 2$ every time we run `isPrime`. Instead we can just start looking for primes starting at 2, assuming that all values passed to 'isPrime' satisfy $n > 2$ already. In fact, since we know that 2 is the only even prime, let's just add to our initial list of primes and only consider odd $n$ going forth. We just need to add a small check to handle the cases $N < 2$ but that is no problem, since this line is only executed once.
"""

# ╔═╡ 8f73a313-e31d-4087-beb9-1f5c43f44ea1
function findPrimesV4(N)
	if N < 2 return [] end
	primes = [2]
	for n in 3:2:N
		if isPrimeV4(primes, n)
			append!(primes, n)
		end
	end
	return primes
end

# ╔═╡ e9cdb8d0-3daa-4ada-9344-45099f184a64
@time findPrimesV4(100_000)

# ╔═╡ 86076221-f0eb-4434-b15e-abcc7fc54384
@time findPrimesV4(1_000_000)

# ╔═╡ 998e600b-6933-48a9-bcf4-f7c1f981411e
@time findPrimesV4(10_000_000)

# ╔═╡ bf89a580-d02c-4c14-af67-f249071b4d5e
@time findPrimesV4(100_000_000)

# ╔═╡ d1edf66f-856b-463a-af27-775507ee70f2
md"""
Finding all primes up to one million now only takes one tenth of a second and just a 50 second wait gives us all primes up to one hundred million!
"""

# ╔═╡ d22ec8ae-e5de-4b8d-85ac-17c7844f667b
md"""
How about the runtime complexity of this evidently much faster algorithm? Well, things get a bit more tricky to analyse here, as the asymptotic runtime now depends on how often and how early we can break out of the loop, which in turn depends on the distribution of primes in a more complicated way than before. If we count the number of iterations of the inner most loop for odd $N$, we get an estimate of
$h(3)/\log(h(3)) + h(5)/\log(h(5)) + \cdots + h(N)/\log(h(N))$,
where $h(n)$ is the smallest prime divisor of $n$ if $n$ is composite, and $\sqrt n$ if $n$ is prime. 
"""

# ╔═╡ 8eae3bb0-4fa5-4e0f-8336-d28b199ef229
md"""
The last changes we made do not affect the runtime complexity itself, as it only shaves of a constant time factor. Never the less, optimizations like this one are not to be underestimated, as for small values of $N$, say $N < 10^9$ for example, a factor of $20$ is often worth more than a factor of $\log(N)$ for instance.
"""

# ╔═╡ ae8373e9-347d-4d2c-b988-6170ec2040a2
md"""
## Applications
Now that we have a way of finding the first 10 million primes in almost the blink of an eye, lets make use of them to verify some well-known but hard to prove result about their distribution.
"""

# ╔═╡ cdefc0aa-aefa-4c62-b8a9-692331c9bf50
primes = findPrimesV4(100_000_000)

# ╔═╡ ba871ee3-125d-402c-aef0-fe7046bf2bde
md"""
### The Prime Number Theorem
As already mentioned in a previous section, the prime number theorem states that the number of primes up to $N$ is asymptotically given by $N/\log N$. A better estimate with the same asymptotic is the function $N/(\log N-1)$. To see this result visually, let us plot $i(\log p_i-1)/p_i$ against $i$:
"""

# ╔═╡ ed0a598c-84a5-4062-bb7a-1d00added226
function plotPNT(primes)
	data = []
	for (i, p) in enumerate(primes)
		append!(data, i*(log(p)-1)/p)
	end
	
	plot(data, ylims = (0.995,1.015), legend = false)
end

# ╔═╡ 1455bae3-7b50-4f0f-b521-b5aa5b9ba926
plotPNT(primes)

# ╔═╡ 54f33702-08e9-439f-9d28-c783d7c27547
md"""
As predicted, the ratio does seem to tend towards $1$, be that very slowly.
"""

# ╔═╡ 03116ef9-39b9-459e-95cc-c367dedd7896
md"""
### First and Last Digits of Primes in Base 10
Despite their unique properties, prime numbers behave in many ways just like a random subset of the integers with a distribution given by the prime number theorem. For example, looking at the last digits of our primes, we expect all possible digits (the odd digits except five) to approximately appear equally often:
"""

# ╔═╡ 6e66626d-7660-45d6-88c5-497ffce7c81e
histogram(broadcast(x -> x % 10, primes), bins = -0.5:1:9.5, xticks = -1:9, legend = false, norm = :pdf, ylims = (.249,.251))

# ╔═╡ 166c0bb7-e75b-4e32-b3f3-0568e9e3d2b3
md"""
The first digits of primes on the other hand we expect to follow the so-called Benford's Law, since the distribution of the primes gets progressively sparser and therefore lower leading digits are more likely:
"""

# ╔═╡ e5bc63bc-751e-4faa-81ce-db37343baf19
histogram(broadcast(x -> floor(x/10^floor(log10(x))), primes), bins = 0.5:1:9.5, xticks = -1:9, normalize = :pdf, ylims = (.105,.12), legend = false)

# ╔═╡ 9d56672c-f3a0-4705-8e04-6bd2776d46b5
md"""
### The Goldbach Conjecture
The Goldbach Conjecture is one of the most famous open problems about prime numbers. Proposed in 1742 by Christian Goldbach in correspondence with Leonhard Euler, it states that every even integer greater than 2 can be written as the sum of two prime numbers. While the problem remains open to this day, the conjecture is strongly believed to be true, not least because no counter example has been found so far. Let us verify this for the first few even integers:
"""

# ╔═╡ b0ba2f26-291f-4204-942f-2b87cd5ba8a8
function verifyGoldbach(n, primes)
	sums = Set()
	for p in primes
		for q in primes
			if p+q > n break end
			push!(sums, p+q)
		end
	end
	for k = 4:2:n
		if !in(k, sums) return false end
	end
	return true
end		

# ╔═╡ 5c1b3bac-98d2-4d5b-b8ef-85ca8e2a4f80
md"""
Since this algorithm runs in $O(n^2)$ time, we will only be able to check up to about 100000. Using the "Fast Fourier Transform" the time complexity could be brought down to $O(n\log n)$ but would go beyond the scope of this case study.
"""

# ╔═╡ 6d322108-fa1b-41ad-81d6-5f36b6ef2fb1
verifyGoldbach(100000, primes)

# ╔═╡ 6ee5e9b2-2d38-4a92-9e71-660f06bbc7a5
md"""
### Reciprocal Sum of Primes
It is well known that the sum of reciprocals of primes diverges. Moreover, the growth rate of the partial sums is also known. In particular, the quantity

$\sum_{i = 1}^n \frac{1}{p_i} - \log\log n$

is decreasing and tends to a constant $M \approx 0.2614972$, called the Meissel–Mertens constant, as $n$ tends to infinity. Let us verify that this result is consistent with our data:
"""

# ╔═╡ 39b108b3-b41e-44c4-9565-d199c5831746
function plotReciprocal(primes)
	partialSum = 0.0
    data = []
    ## SJE: think this is wrong -- i is the index prime; not N
    ## I think the plot is simpler as below
	for (i, r) in enumerate(broadcast(x -> 1/x, primes))
		partialSum += r
		append!(data, partialSum - log(log(i)))
	end
	
	plot(data, ylims = (0.4, 0.5), legend = false)
end


# ╔═╡ a6ea88df-32ae-406a-9ce2-eedbfff3b77f
begin
    partialSum = 0.0
    data = []
    for p in primes[1:1000]
    partialSum += 1/p
        append!(data, partialSum - log(log(p)))
    end
    plot(data, ylims=(0.25, 0.5),xlabel="Nth prime", ylabel="approximation")
    hline!([0.2615])
end


# ╔═╡ 2eff73ca-34ba-4a86-bc98-8543003fa46f
md"""
The expression does indeed seem to be decreasing and slowly tending towards some positive constant.
"""

# ╔═╡ 577326bc-58c8-4e72-ab94-c2ac8aa2e0c1


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"

[compat]
Plots = "~1.20.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c3598e525718abcc440f69cc6d5f60dda0a1b61e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.6+5"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "e2f47f6d8337369411569fd45ae5753ca10394c6"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.0+6"

[[ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random", "StaticArrays"]
git-tree-sha1 = "ed268efe58512df8c7e224d2e170afd76dd6a417"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.13.0"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "344f143fa0ec67e47917848795ab19c6a455f32c"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.32.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[DataAPI]]
git-tree-sha1 = "ee400abb2298bd13bfc3df1c412ed228061a2385"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.7.0"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "4437b64df1e0adccc3e5d1adbc3ac741095e4677"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.9"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "92d8f9f208637e8d2d28c664051a00569c01493d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.1.5+1"

[[Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b3bfd02e98aedfa5cf885665493c5598c350cd2f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.10+0"

[[FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "LibVPX_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "3cc57ad0a213808473eafef4845a74766242e05f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.3.1+4"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "35895cf184ceaab11fd778b4590144034a167a2f"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.1+14"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "cbd58c9deb1d304f5a245a0b7eb841a2560cfec6"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.1+5"

[[FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "dba1e8614e98949abfa60480b13653813d8f0157"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.5+0"

[[GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "182da592436e287758ded5be6e32c406de3a2e47"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.58.1"

[[GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "eaf96e05a880f3db5ded5a5a8a7817ecba3c7392"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.58.0+0"

[[GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "58bcdf5ebc057b085e58d95c138725628dd7453c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.1"

[[Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "7bf67e9a481712b3dbe9cb3dac852dc4b1162e02"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+0"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "44e3b40da000eab4ccb1aecdc4801c040026aeb5"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.13"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[IterTools]]
git-tree-sha1 = "05110a2ab1fc5f932622ffea2a003221f4782c18"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.3.0"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "81690084b6198a2e1da36fcfda16eeca9f9f24e4"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.1"

[[JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d735490ac75c5cb9f1b00d8b5509c11984dc6943"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.0+0"

[[LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[LaTeXStrings]]
git-tree-sha1 = "c7f1c695e06c01b95a67f0cd1d34994f3e7db104"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.2.1"

[[Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "a4b12a1bd2ebade87891ab7e36fdbce582301a92"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.6"

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

[[LibVPX_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "12ee7e23fa4d18361e7c2cde8f8337d4c3101bc7"
uuid = "dd192d2f-8180-539f-9fb4-cc70b1dcf69a"
version = "1.10.0+0"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "761a393aeccd6aa92ec3515e428c26bf99575b3b"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+0"

[[Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "340e257aada13f95f98ee352d316c3bed37c8ab9"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.3.0+0"

[[Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "0fb723cd8c45858c22169b2e42269e53271a6df7"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.7"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "4ea90bd5d3985ae1f9a908bd4500ae88921c5ce7"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.0"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7937eda4681660b4d6aeeecc2f7e1c81c8ee4e2f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+0"

[[OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "15003dcb7d8db3c6c857fda14891a539a8f2705a"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.10+0"

[[Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "bfd7d8c7fd87f04543810d9cbd3995972236ba1b"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "1.1.2"

[[Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "501c20a63a34ac1d015d5304da0e645f42d91c9f"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.0.11"

[[Plots]]
deps = ["Base64", "Contour", "Dates", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs"]
git-tree-sha1 = "e39bea10478c6aff5495ab522517fae5134b40e3"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.20.0"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "ad368663a5e20dbb8d6dc2fddeefe4dae0781ae8"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+0"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[RecipesBase]]
git-tree-sha1 = "b3fb709f3c97bfc6e948be68beeecb55a0b340ae"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.1.1"

[[RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "2a7a2469ed5d94a98dea0e85c46fa653d76be0cd"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.3.4"

[[Reexport]]
git-tree-sha1 = "5f6c21241f0f655da3952fd60aa18477cf96c220"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.1.0"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "885838778bb6f0136f8317757d7803e0d81201e4"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.9"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StatsAPI]]
git-tree-sha1 = "1958272568dc176a1d881acb797beb909c785510"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.0.0"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "fed1ec1e65749c4d96fc20dd13bea72b55457e62"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.9"

[[StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "000e168f5cc9aded17b6999a560b7c11dda69095"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.0"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "d0c690d37c73aeb5ca063056283fde5585a41710"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.5.0"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll"]
git-tree-sha1 = "2839f1c1296940218e35df0bbb220f2a79686670"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.18.0+4"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "cc4bf3fdde8b7e3e9fa0351bdeedba1cf3b7f6e6"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.0+0"

[[libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "acc685bcf777b2202a904cdcb49ad34c2fa1880c"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.14.0+4"

[[libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7a5780a0d9c6864184b3a2eeeb833a0c871f00ab"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "0.1.6+4"

[[libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "c45f4e40e7aafe9d086379e5578947ec8b95a8fb"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+0"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d713c1ce4deac133e3334ee12f4adff07f81778f"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2020.7.14+2"

[[x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "487da2f8f2f0c8ee0e83f39d13037d6bbf0a45ab"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.0.0+3"

[[xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╟─25afb2d2-f437-11eb-327c-496dc439ccfa
# ╟─b735e72f-1498-4bf7-9f30-93a46aa46392
# ╟─480b1c62-9a1d-4504-8872-c388403bec0b
# ╟─6164b325-44b8-478e-a122-a871c44d7ab1
# ╟─24f264de-60d8-463b-8907-0a43f8297e52
# ╠═53cd01c6-0090-47a0-ad59-63950fe471c1
# ╠═e3525717-d598-4730-9ee0-b65ea09f7ce0
# ╠═9f7705cb-775b-4e86-bc70-70b2e852fbc2
# ╟─48e8d826-a81c-42fa-910b-abd3d80a230d
# ╠═a3d579fc-b5d9-4662-9823-b171e4a29fab
# ╟─dc109446-aa32-4fb7-8f74-edc0c6f98c6a
# ╠═a346aa06-7db4-4d7a-aad8-bf005c294c67
# ╟─ba0eae87-4eec-4387-a210-64e0f2126f87
# ╟─e5293427-7721-4a89-ab7b-0c8fb4a618cf
# ╟─af8fa992-1bc8-4896-8f6c-8edf3f19c475
# ╠═73a77da6-7ec7-4460-9542-bb994676a375
# ╠═aa777745-618a-4681-b73a-1a1ca978d165
# ╠═656b291e-f430-4e32-a3c9-87553cf2b1a5
# ╟─7c8670bf-85f6-438c-b9d7-a9b1ca4a6c01
# ╟─a4232c06-eb44-4f7c-a8eb-09aa524cc1a7
# ╠═f4b38f40-6c51-430a-a7fd-5029e3b6ab0f
# ╟─17fa50b7-afee-42f9-b622-d18ef1060720
# ╠═519ce97d-fde8-49c7-8b92-56185bd02333
# ╠═9e76abdc-ddf9-4edd-a40d-059706f556d0
# ╟─ae3c3fa7-0581-46e1-a3f3-abe49173ed1c
# ╟─2b4873be-3cb7-4c2a-b8a0-451baddf428f
# ╟─c28f9636-7d0c-4bd2-9c4d-bfc127ea06bc
# ╟─ce2733ab-10a6-4e87-aae4-ed30fa346823
# ╟─aa396120-1a8d-4d13-9558-1faad05f76c7
# ╠═5f99ba92-7c35-4e6b-a3fc-f42178c43cad
# ╠═3b53142b-d6bd-49e3-91b5-689cdb1cac01
# ╠═bc2831a1-f808-4bc7-afaf-994abefb5286
# ╟─157a17af-eb12-4d6d-be12-37a1b609005d
# ╠═54c591db-16c9-4c9e-9d01-444558af9c6e
# ╟─6e319277-a897-49aa-9e78-7a905a11dc89
# ╟─3ed289cd-6ace-442f-a9b4-7fe109af5e49
# ╠═acda705d-1e1a-4b5f-ba15-0c7d3bdbd5d4
# ╟─7ccb1dea-7a69-47f4-964b-fc7799c58b8a
# ╠═8f73a313-e31d-4087-beb9-1f5c43f44ea1
# ╠═e9cdb8d0-3daa-4ada-9344-45099f184a64
# ╠═86076221-f0eb-4434-b15e-abcc7fc54384
# ╠═998e600b-6933-48a9-bcf4-f7c1f981411e
# ╠═bf89a580-d02c-4c14-af67-f249071b4d5e
# ╟─d1edf66f-856b-463a-af27-775507ee70f2
# ╟─d22ec8ae-e5de-4b8d-85ac-17c7844f667b
# ╟─8eae3bb0-4fa5-4e0f-8336-d28b199ef229
# ╟─ae8373e9-347d-4d2c-b988-6170ec2040a2
# ╠═cdefc0aa-aefa-4c62-b8a9-692331c9bf50
# ╟─ba871ee3-125d-402c-aef0-fe7046bf2bde
# ╠═ed0a598c-84a5-4062-bb7a-1d00added226
# ╠═1455bae3-7b50-4f0f-b521-b5aa5b9ba926
# ╟─54f33702-08e9-439f-9d28-c783d7c27547
# ╟─03116ef9-39b9-459e-95cc-c367dedd7896
# ╠═6e66626d-7660-45d6-88c5-497ffce7c81e
# ╟─166c0bb7-e75b-4e32-b3f3-0568e9e3d2b3
# ╠═e5bc63bc-751e-4faa-81ce-db37343baf19
# ╟─9d56672c-f3a0-4705-8e04-6bd2776d46b5
# ╠═b0ba2f26-291f-4204-942f-2b87cd5ba8a8
# ╟─5c1b3bac-98d2-4d5b-b8ef-85ca8e2a4f80
# ╠═6d322108-fa1b-41ad-81d6-5f36b6ef2fb1
# ╟─6ee5e9b2-2d38-4a92-9e71-660f06bbc7a5
# ╠═39b108b3-b41e-44c4-9565-d199c5831746
# ╠═a6ea88df-32ae-406a-9ce2-eedbfff3b77f
# ╟─2eff73ca-34ba-4a86-bc98-8543003fa46f
# ╠═577326bc-58c8-4e72-ab94-c2ac8aa2e0c1
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
