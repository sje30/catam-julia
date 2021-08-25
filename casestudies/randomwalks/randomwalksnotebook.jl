### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 4fb3b524-419f-47b0-b8c4-42e768e23f2b
using Plots

# ╔═╡ 64a062ea-c7d9-4908-a8ab-98552da66e0a
begin
	using PlutoUI
	PlutoUI.TableOfContents(title = "Contents")
end

# ╔═╡ 75c95ffe-c921-4b1a-b5d9-8cf7426e4b92
md"""
# Random walks
"""

# ╔═╡ 8afab5ff-a1d9-4db1-87d2-b5246de75779
md"""
## Objectives
- Plot random walks in one, two, and three dimensions
- Examine statistical properties of random walks
- Use random walks to numerically approximate solutions to Laplace's equation
"""

# ╔═╡ 231214c8-77cb-44c8-85b6-c344774b1f1a
md"""
## What is a random walk?
A random walk is a statistical model consisting of a sequence of discrete steps on some space, such as ``\mathbb{Z}``, ``\mathbb{R}^n``, or a graph. They are used to model many phenomena, the most notable of which is probably Brownian motion, that is, the motion of particles suspended in a liquid or gas.

The simplest example, which I will look at initially, is the simple unbiased random walk on ``\mathbb{Z}``, given as follows:
- The walk starts at ``Y_0 = 0``
- Steps are given by independent and identically distributed random variables ``X_i``, where
```math
X_i = \begin{cases}
1 & \text{with probability } \frac{1}{2} \\
-1 & \text{with probability } \frac{1}{2}
\end{cases}
```
- The position of the walk after ``n`` steps is ``Y_n = \sum_{i=1}^n X_i``

To extend this to ``d`` dimensions, the canonical method is to have ``X_n`` be a positive or negative move in any dimension, so steps would take the form ``X_n = (0, 0, \dots, \pm 1, \dots, 0)``, each with probability ``\frac{1}{2d}``.

"""

# ╔═╡ fe14c2a8-9fb7-406e-8698-bd4b666ab436
md"""
## Plotting random walks

Before I look to examine random walks in closer detail, I would like to plot some examples to get a better idea of their structure.
"""

# ╔═╡ 369fd574-1291-4adc-8c1f-14e61f09aaa6
md"""
The `randomwalks1d` function plots `m` random walks of length `n`, by plotting the position against time. It also has a third argument `stepfunction`, which allows me to customise the distribution from which the steps ``X_i`` are sampled.
"""

# ╔═╡ 48c79e2d-0fd1-4ab5-84fd-0d1e3b42ae58
function randomwalks1d(m,n,stepfunction)
	walks = zeros(m,n+1)
	for step ∈ 1:n
		walks[:,step+1] = walks[:,step] + stepfunction(m)
	end
	
	return plot(
		0:n,
		[walks[walk,:] for walk ∈ 1:m],
		legend = false
	)
end

# ╔═╡ 84e34c30-dcb0-469d-824a-74bccf23f077
md"""
I will compare four different step types, all of which will have ``\mathbb{E}(X_i) = 0`` and ``\mathrm{Var}(X_i) = 1`` to allow a fairer comparison. First of all, I will use the simple symmetric random walk, where ``X_i`` is either ``1`` or ``-1``, each with probability ``\frac{1}{2}`` (note that ``(X_i - \mathbb{E}(X_i))^2`` is always ``1`` here, so the variance is ``1``).

The second step type will be similar to the first, but a step of ``0`` will be a third equally likely option. To ensure that variance ``1`` is maintained, the possible steps left and right will have to be larger, indeed:
```math
X_i \text{ chosen uniformly from } \{0, \pm a \}
```
```math
\mathbb{E}(X_i) = 0, \quad \mathrm{Var}(X_i) = \frac{1}{3}(0-0)^2 + \frac{1}{3}(a-0)^2 + \frac{1}{3}(-a-0)^2 = \frac{2a^2}{3} = 1
```
```math
\Rightarrow \quad a = \sqrt{\frac{3}{2}}
```

The third step type will be a continuous uniform distribution, which will be symmetric about ``0`` such that its mean is ``0``:
```math
X_i \sim U[-b,b]
```
```math
\mathbb{E}(X_i) = 0, \quad \mathrm{Var}(X_i) = \frac{(b-(-b))^2}{12} = \frac{1}{3} b^2 = 1
```
```math
\Rightarrow \quad b = \sqrt{3}
```

As `rand()` gives a ``U[0,1]`` distribution, `rand() - 0.5` will give a ``U[-0.5,0.5]`` distribution, and hence I can get the required uniform distribution by `2*√3 * (rand() - 0.5)`.

Finally, I will use a normal distribution, for which the standard normal distribution given by the function `randn` already has the required mean and variance. This random walk is called a Gaussian random walk.
"""

# ╔═╡ e05b6d48-0f68-4b12-95f5-651a561c5821
plot(
	randomwalks1d(5, 100, m -> rand([-1,1],m)),
	randomwalks1d(5, 100, m -> rand([-√1.5,0,√1.5],m)),
	randomwalks1d(5, 100, m -> 2*√3 .* (rand(m) .- 0.5)),
	randomwalks1d(5, 100, m -> randn(m)),
	size = (800, 600),
	ylims = (-20,20),
	title = ["Xᵢ ∈ {±1}" "Xᵢ ∈ {0, ±√1.5}" "Xᵢ ~ U[-√3, √3]" "Xᵢ ~ N(0, 1)"]
)

# ╔═╡ 7b48324b-5b5d-4b12-a21b-370877539cd7
md"""
Over the scale of 100 steps, the four different methods for generating ``X_i`` give broadly similar walks, the difference between them being no more than the random variation between different walks with the same distribution for ``X_i``. This suggests that the mean and variance are the only parameters that will particularly affect ``Y_n``, perhaps unsurprisingly considering the Central Limit Theorem). Therefore, from this point forth, I will use the simple symmetric random walk as standard, with the Gaussian random walk used later where continuity is important.

I can also look at the effect of varying `n`. To do this, I simulate five random walks for each of 100, 1000, 10000, and 100000 steps:
"""

# ╔═╡ 092bc8c9-f746-404c-8047-ab0e247d608a
plot(
	randomwalks1d(5, 100   , m -> rand([-1,1],m)),
	randomwalks1d(5, 1000  , m -> rand([-1,1],m)),
	randomwalks1d(5, 10000 , m -> rand([-1,1],m)),
	randomwalks1d(5, 100000, m -> rand([-1,1],m)),
	size = (800,600),
	title = hcat(["n = $n" for n ∈ 10 .^ (2:5)]...)
)

# ╔═╡ aeb9e7aa-8325-4fa3-9af0-a8a0297cac57
md"""
This demonstrates quite well the fractal nature of random walks, since there is much similarity between the shapes of the graphs when `n` is scaled.

I will also look to plot two and three dimensional random walks, which I can do with the functions `randomwalk2d` and `randomwalk3d` respectively. They are mostly the same as `randomwalks1d`, except that they only plot a single walk at a time, and instead of plotting the position against time, they plot the path that the random walk takes.
"""

# ╔═╡ 64cdecff-16e7-4999-bce6-d8acd36fc297
function randomwalk2d(n)
	walk = fill((0,0),(n+1))
	for step ∈ 1:n
		walk[step+1] = walk[step] .+ rand([(-1,0),(1,0),(0,-1),(0,1)])
	end
	
	return plot(walk, legend = false, aspect_ratio = :equal)
end

# ╔═╡ 47754a40-a4d2-43c3-9b95-2ec10ba00f57
function randomwalk3d(n)
	walk = fill((0,0,0),(n+1))
	for step ∈ 1:n
		walk[step+1] = walk[step] .+
			rand([(-1,0,0),(1,0,0),(0,-1,0),(0,1,0),(0,0,-1),(0,0,1)])
	end
	
	return plot(walk, legend = false, aspect_ratio = :equal)
end

# ╔═╡ d78168c3-e173-40c3-8b74-b40f87cffc18
md"""
To observe the fractal qualities of these random walks, I sample a random walk for each of the values of `n` as before, first in two dimensions:
"""

# ╔═╡ 0e9309f4-03b2-47bb-bb07-5ef2cab164ed
plot(
	randomwalk2d(100),
	randomwalk2d(1000),
	randomwalk2d(10000),
	randomwalk2d(100000),
	size = (800,800),
	title = hcat(["n = $n" for n ∈ 10 .^ (2:5)]...)
)

# ╔═╡ fa1fa07e-6041-4d9a-8d8a-5906552fd921
md"""
and then in three dimensions:
"""

# ╔═╡ e2666dc7-831e-436c-8b55-49fcb664e5c2
begin
	randomwalks3d = plot(
		randomwalk3d(100),
		randomwalk3d(1000),
		randomwalk3d(10000),
		randomwalk3d(100000),
		size = (800,800),
		title = hcat(["n = $n" for n ∈ 10 .^ (2:5)]...)
	)
	
	animrandomwalks3d = @animate for x ∈ 0:0.04π:2π
		plot(randomwalks3d, camera = (45cos(x)+45,20sin(x)+40))
	end
	gif(animrandomwalks3d, fps = 10)
end

# ╔═╡ 9d3464c5-0686-41b3-8c45-7fd238ab5254
md"""
I think that the two and three dimensional plots show the fractal quality even better than in one dimension, especially in two dimensions where the denser blobs are easier to see. In three dimensions, the overall shape is still visible, but the two dimesional perspective makes the path less clear, even with the moving camera angle.
"""

# ╔═╡ 86fd5808-36e4-4114-98cc-fe188518e78d
md"""
## Statistical properties of random walks

### The distribution of a simple symmetric random walk
The first property of the simple symmetric random walk that I will look at is the distribution of ``Y_n``, in the one dimensional case. This is a good starting point since it is easy to work out what it should be.

A ``\mathrm{Bernoulli}(p)`` distribution takes the value ``1`` with probability ``p``, and the value ``0`` with probability ``1-p``. Hence:
```math
X_i \sim 2 \times \mathrm{Bernoulli} \left( \frac{1}{2} \right) - 1
```

The sum of ``n`` independent ``\mathrm{Bernoulli}(p)`` random variables is a random variable with distribution ``\mathrm{B(n,p)}``, the binomial distribution. As ``Y_n`` is the sum of iid random variables ``X_i``:
```math
Y_n \sim \sum_{i = 1}^n \left[ 2 \times \mathrm{Bernoulli} \left( \frac{1}{2} \right) - 1 \right] = 2 \times \mathrm{B} \left( n, \frac{1}{2} \right) - n
```

As ``\mathrm{Bernoulli}(p)`` has mean ``p`` and variance ``p(1-p)``, the Central Limit Theorem gives that:
```math
\sqrt{n} \left( \frac{1}{n}\mathrm{B}(n,p) - p \right) \xrightarrow{(d)} \mathrm{N}(0, p(1-p))
```
```math
\Rightarrow \frac{1}{\sqrt{n}} Y_n \sim 2 \sqrt{n} \left( \frac{1}{n} \mathrm{B} \left( n, \frac{1}{2} \right) - \frac{1}{2} \right) \xrightarrow{(d)} 2 \times \mathrm{N} \left( 0, \frac{1}{4} \right) = \mathrm{N}(0,1)
```
Indeed, the normal approximation ``\mathrm{N}(np, np(1-p))`` for the binomial distribution ``\mathrm{B}(n,p)`` is very good, especially for the more symmetric distributions as ``p \to \frac{1}{2}``. Hence, I will compare ``\frac{1}{\sqrt{n}} Y_n`` with the standard normal distribution ``\mathrm{N}(0,1)`` to verify this calculation.

To do this, I first choose `n` random directions out of `[-1,1]`, and sum them to get a value for `Yₙ`. I repeat this `samplesize` times to get a vector of values of `Yₙ`, which I call `Yₙs`. I then plot the values of `Yₙ/√n` as a histogram, normalised such that the total area under the histogram is 1, and overlay the pdf of a standard normal distribution.
"""

# ╔═╡ 75b2629b-711e-44f8-83f1-1770dfe967cb
function Yₙdistribution(samplesize, n)
	Yₙs = [sum(rand([-1,1],n)) for _ ∈ 1:samplesize]
	distribution = stephist(
        Yₙs ./ √n,
        bins = -3:0.2:3,
        norm = :pdf,
        xticks = -3:1:3,
        showaxis = :x,
		legend = false,
        yticks = false
    )
	return plot!(
        distribution,
        x -> exp(-(x^2)/2)/√(2π),
        c = :black
    )
end

# ╔═╡ d800326f-4d88-4ff9-bb4c-e938a5c637df
plot(
	Yₙdistribution(10000, 100),
	Yₙdistribution(10000, 1000),
	Yₙdistribution(10000, 10000),
	Yₙdistribution(10000, 100000),
	title = hcat(["n = $n" for n ∈ 10 .^ (2:5)]...)
)

# ╔═╡ 7b40cd66-a80b-4b1a-853d-f8be4643d5fa
md"""
The results fit the distributions well for each of the four values of `n`. Unusually, the worst fitting distribution is not the smallest `n` (which might be expected from convergence as `n` tends to infinity), but `n = 1000`, where there is a distinct peak in the range `[0.0, 0.2]`, as well as peaks in the ranges `[-1.4, 1.2]` and `[1.2, 1.4]`. I have observed similar peaks and troughs consistently for many values of `n` between `100` and `10000`, such as some of the examples below: 
"""

# ╔═╡ 4fedd855-a323-479e-b196-57362d99f0fa
plot(
	Yₙdistribution(10000, 500),
	Yₙdistribution(10000, 800),
	Yₙdistribution(10000, 1000),
	Yₙdistribution(10000, 1001),
	Yₙdistribution(10000, 1200),
	Yₙdistribution(10000, 3500),
	layout = (3,2),
	title = hcat(["n = $n" for n ∈ [500, 800, 1000, 1001, 1200, 3500]]...)
)

# ╔═╡ 50a4e8b9-a3e0-4eff-a060-82c584596b4d
md"""
I think the likely cause of this is that because for each random walk, the entire sequence of values `Xᵢ` from `[-1,1]` is generated at once, and for whatever reason they are not truly independent. My theory is that there is some sort of resonance in the random number generator, causing certain sequences to be more likely than others. Nevertheless, I still believe that this simulation verifies the theory for the distribution of ``Y_n``, as the shape of the distribution fits reasonably well regardless, and improves for larger `n`.
"""

# ╔═╡ 3f2f5c0f-63ee-430a-b86a-11882f072029
md"""
### The probability of returning to the origin
In the general ``d`` dimensional random walk, the process starts at ``Y_0 = \mathbf{0}``, but as it must make a step in some direction, ``Y_1 \neq \mathbf{0}``. However, it can return the very next step if it retraces that step, so ``Y_2 = \mathbf{0}`` with probability ``\frac{1}{2d}``. It is a natural question to ask what the probability is that the walk ever returns to the origin, i.e. ``p = \mathbb{P}(Y_n = 0 \text{ for some } n > 0)``.

To simulate this, I will first create a function to pick a random direction in `d` dimensions, which I do simply by creating a vector with all entries zero apart from one random entry, which is randomly `-1` or `1`. 
"""

# ╔═╡ fed215e1-126d-4d69-9abb-ab4a5f024ed6
function randomdirection(d)
	x = zeros(d)
	x[rand(1:d)] = rand([1,-1])
	return x
end

# ╔═╡ 23e9c1bf-4379-4994-b975-2fa1e99fa923
md"""
Then, I estimate the return probability as follows:
- Starting at the origin, I take two random steps (since it is impossible to end up at the origin after an odd number of steps)
- If I end up at the origin, I stop looking
- I continue the walk for up to `nₘₐₓ` total steps

I repeat this `samplesize` times, keeping a cumulative count of the number of walks which have returned to the origin by each time. This I then divide by `samplesize` to get an estimate of the probability of returning by time `2n` for each `n ∈ [2, 4, ..., nₘₐₓ]`. Lastly, I append `0` to the start of this vector, since the return probability by time `0` is `0`.
"""

# ╔═╡ 97852ab1-799c-4eb2-8ca7-604936b13293
function returnprobability(samplesize, nₘₐₓ, d)
    returnfrequencies = zeros(nₘₐₓ ÷ 2)
    for _ ∈ 1:samplesize
        y = zeros(d)
        for halfn ∈ 1:(nₘₐₓ ÷ 2)
            y += randomdirection(d) + randomdirection(d)
            all(y .== 0) && (returnfrequencies[halfn:end] .+= 1; break)
        end
    end
    return vcat(0, returnfrequencies ./ samplesize)
end

# ╔═╡ f1ad4dc1-f5ef-4df1-aa54-22441b391e6b
md"""
I can now plot this, along with estimating ``p``, which I will take to be the estimate of the return probability after `nₘₐₓ` steps:
"""

# ╔═╡ 5d322770-d6d9-440b-b488-5e1c57477847
function plotreturnprobabilities(samplesize, nₘₐₓ, ds)
	returnprobs = [returnprobability(samplesize, nₘₐₓ, d) for d ∈ ds]
    plot(
        0:2:nₘₐₓ,
        returnprobs,
		label = hcat(
			["d = $d, p ≈ $(returnprobs[i][end])" for (d,i) ∈ enumerate(ds)]...),
        ylims = (0,1)
    )
end

# ╔═╡ 9e9511f7-1bfa-46df-98d8-4b3bafbd9150
plotreturnprobabilities(1000, 10000, 1:4)

# ╔═╡ c125a698-8feb-43fc-9f25-fb199e0e1367
md"""
The true values of ``p`` for each ``d`` are described by Eric W. Weisstein at Wolfram MathWorld, where they are called [Pólya's Random Walk Constants](https://mathworld.wolfram.com/PolyasRandomWalkConstants.html). For the values of ``d`` which I have considered above, the true values are:

| d | p |
|:-:|:-:|
| ``1`` | ``1`` |
| ``2`` | ``1`` |
| ``3`` | ``0.340537 \dots`` |
| ``4`` | ``0.193206 \dots`` |

This matches quite well with my estimates for ``d = 1, 3,`` and ``4``. For ``d = 2``, my estimate suggests that it is possible that a random walk doesn't return to the origin, although the graph shows that the probability is still obviously increasing, not having converged to a value like the other three.

Increasing `nₘₐₓ` can help to improve the estimate, but even `nₘₐₓ = 1000000` only gives an estimate of ``p \approx 0.8``, with the graph still having a noticeable upward slope. The problem here is that although the walk will theoretically always return to the origin, the rate at which it does so can be very slow indeed.
"""

# ╔═╡ 830cb57b-e67b-4105-b9ad-17cad4f22504
md"""
## Solving Laplace's equation with random walks

### Laplace's equation, the Dirichlet problem, and Kakutani's solution
Laplace's equation is given as follows:
```math
\nabla^2 \phi = 0 \qquad \text{for } \phi : \mathbb{R}^d \to \mathbb{R}
```

Solutions of Laplace's equation are called harmonic function, and arise commonly in physical systems, such as in thermodynamics where they are the solutions to the heat equation which are constant over time, and gravitation where gravitational potential is always a harmonic function.

The Dirichlet problem involves finding the solution to Laplace's equation on a region ``U \subset \mathbb{R}^d``, with the boundary condition that ``\phi`` is known on ``\partial U`` (the boundary of ``U``). A general method of solving this problem using Brownian motion (a continuous limit of random walks where the step size tends to 0) was discovered by Shizuo Kakutani in 1944:

_**(Kakutani 1944)**_ - For ``\mathbf{x} \in U``, let a particle undergo Brownian motion starting from ``\mathbf{x}``, and let ``\mathbf{X}`` be the (random) position where the trajectory of the particle first meets ``\partial U``. Then, ``\phi(\mathbf{x}) = \mathbb{E}(\phi(\mathbf{X}))``.

The proof of this is by no means simple, but an intuitive understanding can be garnered from considering ``U = B = B_r(\mathbf{x}) = \{ \mathbf{y} \in \mathbb{R}^d : |\mathbf{x} - \mathbf{y}| < r \}`` for any ``r > 0``. The symmetry of Brownian motion means that ``\mathbf{X}`` should be uniformly distributed on ``\partial U``, and so using ``\phi(\mathbf{x}) = \mathbb{E}(\phi(\mathbf{X}))``:
```math
\phi(\mathbf{x}) = \mathbb{E}(\phi(\mathbf{X})) = \frac{\int_{\partial B} \phi(\mathbf{y}) d\mathbf{y}}{\int_{\partial B} d\mathbf{y}} 
```
which is exactly the mean-value property, a defining property for harmonic functions. Indeed, for a more general ``U``, points further away from ``\mathbf{x}`` are both less likely for the Brownian motion to hit (the density decreases as the radius ``|\mathbf{x} - \mathbf{y}|`` increases), and also have less of an effect on the value of ``\phi(\mathbf{x})`` (as can be seen from the mean-value property).

To put this theorem into practice, I will look specifically at the case ``d = 2``, using ``\mathbb{C}`` instead of ``\mathbb{R}^2``, with ``U \subset \mathbb{C}`` either a disc centred at ``0``, or a rectangle aligned with the real and imaginary axes. Instead of the continuous process of Brownian motion, I will approximate it with random walks, although to maintain an essence of continuity which will greatly aid the approximation, I will use steps with each of the real and imaginary components given independently by ``\mathrm{N}(0, \sigma^2)``, giving a two dimensional Gaussian random walk:
```math
X_j, Y_j \sim \mathrm{N}(0, \sigma^2), \qquad Z_0 = x, \quad Z_n = x + \sum_{j=1}^n (X_j + i Y_j )
```

The choice of ``\sigma`` will be a matter of balancing speed and accuracy. If ``\sigma`` is lower, the random walk will more closely resemble ideal Brownian motion, but will also make steps much smaller on average, meaning that it will take longer for the walk to cross ``\partial U``.
"""

# ╔═╡ 711b7d6e-8f36-4bd9-985e-75a174ed4fc3
md"""
### Solving on a disc
First, I take ``U`` to be the disc ``\{ z \in \mathbb{C} : |z| < r \}``. Starting at `z = x`, I can generate ``X_j + i Y_j`` by `σ*complex(randn(2)...)`, and add this on to `z` to get the next position in the walk. This I continue doing until `z` ends up outside of ``U`` (i.e. `while abs(z) < r`).

However, it is almost certain that I have overshot ``\partial U``, and so the value for ``\phi(X)`` could be inaccurate. Due to rounding errors, I cannot expect it to be possible for ``X`` to land on ``\partial U`` at all, so the boundary condition must be defined near ``\partial U`` as well, not just exactly on it, but I do want to minimise error by making sure that ``X`` is as close as possible to ``\partial U``. To enact this, I will choose ``X`` to be the point ``w`` on the line between ``x`` and ``z`` where it intersects with the circle ``\partial U``, or at least a good approximation of it up to rounding error.
"""

# ╔═╡ a4e68952-e2d8-40ae-81ac-f614ef091404
begin
	diagram₁ = plot(
		cos.(0:0.01π:2.01π),
		sin.(0:0.01π:2.01π),
		c = :black,
		legend = false,
		size = (800,300),
		showaxis = false,
		ticks = false,
		xlims = (-4,4),
		ylims = (-1.5,1.5)
	)
	
	scatter!(
		diagram₁,
		[(-0.4,0.2),(0.8,0.6),(1.1,0.7)],
		c = :black,
		ann = [(-0.5,0.4,"x"),(0.7,0.4,"w"),(1.2,0.9,"z")]
	)
	
	plot!(
		diagram₁,
		[(-0.4,0.2),(0,-0.3),(0.7,0),(1.1,0.7)],
		c = :red,
		arrow = true
	)
	
	plot!(
		diagram₁,
		x -> (1/3)x + 1/3,
		c = :black,
		linestyle = :dot
	)
end

# ╔═╡ 3bd012e4-b0cd-46c3-9aca-527b303476b3
md"""
Before I can do any programming, I need to work out how to calculate this point. The equations of the line and the circle give that:
```math
w = x + t(z-x), \qquad w\bar{w} = r^2
```
where we know that ``0 < t \leq 1``. A more convenient form for the equation of the line can be found by:
```math
\begin{aligned}
w(\bar{x} - \bar{z}) + \bar{w}(z-x)
&= (x + t(z-x))(\bar{x} - \bar{z}) + (\bar{x} + t(\bar{z} - \bar{x}))(z-x) \\
&= x\bar{x} - x\bar{z} + \bar{x}z - x\bar{x} + t(z-x)(\bar{x} - \bar{z}) + t(\bar{z} - \bar{x})(z-x) \\
&= \bar{x}z - x\bar{z}
\end{aligned}
```

Multiplying by ``w`` and rearranging gives:
```math
(\bar{x} - \bar{z})w^2 + (x\bar{z} - \bar{x}z)w + r^2 (z-x) = 0
```

which I can solve as a quadratic equation, using a custom function to avoid having to write out the quadratic formula with these coefficients.
"""

# ╔═╡ 40f4876c-a2fb-4f3d-88a4-d460b4d8b53b
solvequadratic(a,b,c) = Tuple([(-b + ε * √complex(b^2 - 4a*c))/2a for ε ∈ [1,-1] ])

# ╔═╡ 0b404fc3-2483-4c75-919a-09f652e75935
solvequadratic(1,1,1)

# ╔═╡ 32185868-cb3c-4f26-8933-c12497b02f8d
md"""
The `solvequadratic` function returns both solutions to the quadratic, but I only need one. As it happens, this is always the ``-`` solution, which is always the second of the two solutions, allowing me to find ``w``:
```julia
w = solvequadratic(conj(x) - conj(z), x*conj(z) - conj(x)*z, r^2 * (z - x))[2]
```

I then need to repeat the random walk `samplesize` times, keeping a total of the values of ``\phi(X)``. To finish the function, I divide the total by `samplesize`, and return this average.
"""

# ╔═╡ 720f07ba-0518-449c-a02e-43a503c66796
function laplace◯(x, samplesize, r, ϕ, σ)
    ϕtotal = 0
    for _ ∈ 1:samplesize
        z = x
        while abs(z) < r
            z += σ*complex(randn(2)...)
        end
		
        w = solvequadratic(conj(x) - conj(z), x*conj(z) - conj(x)*z, r^2 * (z - x))[2]
        ϕtotal += ϕ(w)
    end
    return ϕtotal / samplesize
end

# ╔═╡ bafeba49-956b-42aa-80ee-6c7d514da5d5
md"""
To create a plot, I need a parameter to control the number of points `x` from which I sample. This I do with `gridsize`, which will be the number of equally spaced values between `-r` and `r` from which the real and imaginary parts of `x` will be chosen, calculated by
```julia
graduations = range(-r, r, length = gridsize)
```

The plotting will be done with `wireframe`, which takes in the lists of graduations to define a rectangular grid, with the input function calculated at each point and plotted in three dimensions. As this grid will include points outside of the circle ``U``, I make sure to return `NaN` for these points so that they won't be plotted.

I also plot the boundary ``\partial U`` with the boundary conditions as input, which helps to visualise the surface representing the solution.
"""

# ╔═╡ c126d81b-2d9d-45b3-b19f-2ef2fd31745b
function plotlaplace◯(gridsize, samplesize, r, ϕ, σ)
    graduations = range(-r, r, length = gridsize)
    solutionplot = wireframe(
        graduations,
        graduations,
        (x,y) -> hypot(x,y) ≤ r ? laplace◯(x+y*im, samplesize, r, ϕ, σ) : NaN,
        c = :black,
        legend = false
    )

    θs = 0:0.01π:2.01π
    z(θ) = r*exp(im*θ)
    return plot!(solutionplot, r.*cos.(θs), r.*sin.(θs), ϕ.(z.(θs)), c = :black)
end

# ╔═╡ 3d81ba40-868b-4980-b16f-948750a21063
md"""
As an example, I use the boundary condition:
```math
\phi(re^{i \theta}) = \mathrm{sinc}(2\theta) = \frac{\sin(2\pi\theta)}{2\pi\theta}
```
with the function `angle` choosing ``\theta \in (-\pi, \pi]``.
"""

# ╔═╡ 98c98083-ab31-4532-857c-16d303cf5b8b
ϕ◯ = z -> sinc(2angle(z));

# ╔═╡ 30c1d94c-49e5-4824-b13c-5ad3bb3bafb7
solutionplot◯ = plotlaplace◯(20, 1000, 1, ϕ◯, 0.1);

# ╔═╡ 6560fe5e-c717-4f15-8eca-33d4e5db133d
md"""
Three dimensional plots can be hard to visualise as they are, especially as `gridsize` gets larger and the plot gets busier with lines. To help with this, I use the `camera` attribute of such plots to be able to change the view of the plot without having to recalculate anything.

*The sliders below will only work in if this file is opened as a Pluto notebook*
"""

# ╔═╡ 1504864d-f838-475a-99ac-bf28da99365d
md"""
Azimuth: $(@bind azimuthangle◯ Slider(0:90, default = 60))
Elevation: $(@bind elevationangle◯ Slider(0:90, default = 60))
"""

# ╔═╡ 20da0c07-59d1-4294-a457-cc71181a00ff
plot(solutionplot◯, camera = (azimuthangle◯,elevationangle◯))

# ╔═╡ 4283aa0f-c7de-4834-93eb-208834097338
md"""
With my chosen sample size of 1000, and a grid size of 20, the approximate solution looks mostly smooth and matches well with the boundary conditions, showing that the random walk method is working to approximate a harmonic function.
"""

# ╔═╡ 5c43e2b3-6070-477e-ab0d-9696f85f4dc5
md"""
### Solving on a rectangle

I will now mirror this method, but instead of a circle, ``U`` will be a rectangle given by ``U = \{ z \in \mathbb{C} : x_{min} < \mathrm{Re}(z) < x_{max} , y_{min} < \mathrm{Im}(z) < y_{max} \}``. To begin with, I will write a function making boundary conditions easier to define. This takes eight arguments, four defining the limits of the rectangle, and four functions, one to define the boundary condition on each boundary.

The resultant function `ϕ` will then work as follows:
- `ϕ(xₘᵢₙ + im*y) = ϕxₘᵢₙ(y)`
- `ϕ(xₘₐₓ + im*y) = ϕxₘₐₓ(y)`
- `ϕ(x + im*yₘᵢₙ) = ϕyₘᵢₙ(x)`
- `ϕ(x + im*yₘₐₓ) = ϕyₘₐₓ(y)`
- The `x` coordinate takes priority over the `y` coordinate, so `ϕ(xₘᵢₙ + im*yₘᵢₙ) = ϕxₘᵢₙ(yₘᵢₙ)` etc. This isn't a problem if the boundary conditions chosen are continuous at the corners, which I will usually choose them to be
"""

# ╔═╡ ae801ddc-0866-4a1f-be4c-7199ade3423c
function rectanglefunction(xₘᵢₙ, xₘₐₓ, yₘᵢₙ, yₘₐₓ, ϕxₘᵢₙ, ϕxₘₐₓ, ϕyₘᵢₙ, ϕyₘₐₓ)
    return z -> real(z) == xₘᵢₙ ? ϕxₘᵢₙ(imag(z)) :
                real(z) == xₘₐₓ ? ϕxₘₐₓ(imag(z)) :
                imag(z) == yₘᵢₙ ? ϕyₘᵢₙ(real(z)) :
                imag(z) == yₘₐₓ ? ϕyₘₐₓ(real(z)) :
                NaN
end

# ╔═╡ 78e87873-247b-4ded-a563-10b008de1980
md"""
To find the solution this time, the algorithm is much the same, but a few tweaks need to be made to accomadate the new shape of ``U``:
- Instead of the radius `r`, the functions take an argument `boundary`, which is a 4-tuple containing the values `xₘᵢₙ`, `xₘₐₓ`, `yₘᵢₙ`, `yₘₐₓ` in that order
- Many points `x` will be on the boundary, which is simple to check, and allow me to skip the rest of the function by just returning the value of `ϕ(x)` that the boundary conditions determine
- Calculation of the point `w` will be different. Due to the random element, I can guarantee that the line between `x` and `z` will not be exactly horizontal or vertical, so it will intersect each of the lines of the four sides of the rectangle. For each side, I calculate the value of `t` such that `x + t*(z-x)` is the intersection point. Then, `w` will be given by the smallest positive value of `t` out of these four.
"""

# ╔═╡ 7ef086b7-2016-4c36-820a-2884cd3281bc
begin
	diagram₂ = plot(
		[(-1,-1),(1,-1),(1,1),(-1,1),(-1,-1)],
		c = :black,
		legend = false,
		size = (800,300),
		showaxis = false,
		ticks = false,
		xlims = (-4,4),
		ylims = (-1.5,1.5)
	)
	
	scatter!(
		diagram₂,
		[(-0.25,0.1),(-1.25,-0.3),(-1,-0.2),(1,0.6),(-3,-1),(2,1)],
		c = :black,
		markersize = [4,4,3,3,3,3],
		markerstrokewidth = 0,
		ann = [(-0.45,0.2,"x"),(-1.45,-0.2,"z")]
	)
	
	plot!(
		diagram₂,
		[(-0.25,0.1),(-0.2,-0.3),(-0.7,-0.6),(-1.25,-0.3)],
		c = :red,
		arrow = true
	)
	
	plot!(
		diagram₂,
		[x -> x < -1 ? -1 : NaN, x -> x > 1 ? 1 : NaN, x -> 0.4x + 0.2],
		c = :black,
		linestyle = :dot
	)
end

# ╔═╡ 1a9c53ec-d4fb-4e07-a075-368ca422238e
md"""
- In the circular case, I made sure that my boundary condition was defined near ``\partial U`` to account for rounding error. However, in the rectangular case, I have not required this (indeed, if `ϕ` is constructed from `rectanglefunction`, it won't be), so I will need to round off `w` in order to snap it to ``\partial U``
"""

# ╔═╡ ed827bfc-dbdb-4b54-a4a4-35727925f5f1
function laplace□(x, samplesize, boundary, ϕ, σ)
    xₘᵢₙ, xₘₐₓ, yₘᵢₙ, yₘₐₓ = boundary
    (real(x) ∈ (xₘᵢₙ,xₘₐₓ) || imag(x) ∈ (yₘᵢₙ,yₘₐₓ)) && return ϕ(x)
    ϕtotal = 0
    for _ ∈ 1:samplesize
        z = x
        while (xₘᵢₙ < real(z) < xₘₐₓ) && (yₘᵢₙ < imag(z) < yₘₐₓ)
            z += σ * complex(randn(2)...)
        end

        tvals = [
            (xₘᵢₙ - real(x))/(real(z) - real(x)),
			(xₘₐₓ - real(x))/(real(z) - real(x)),
            (yₘᵢₙ - imag(x))/(imag(z) - imag(x)),
			(yₘₐₓ - imag(x))/(imag(z) - imag(x))
        ]
        t = minimum(tvals[tvals .≥ 0])
		w = round(x + t*(z-x), digits = 3)
        ϕtotal += ϕ(w)
    end
    return ϕtotal / samplesize
end

# ╔═╡ 5c96bd07-1fcf-4f42-b325-59eef0295541
md"""
For the plot, there are two minor changes:
- All of the grid points as defined by the graduations will be in ``U \cup \partial U``, so there is no need to use `NaN` to stop points outside of this being plotted
- The boundary conditions also don't need to be plotted, since they are already accounted for in the plot
"""

# ╔═╡ c7b6fcba-9bc8-4da7-8545-011016b92bb4
function plotlaplace□(gridsize, samplesize, boundary, ϕ, σ)
    return wireframe(
        range(boundary[1], boundary[2], length = gridsize),
        range(boundary[3], boundary[4], length = gridsize),
        (x,y) -> laplace□(x+y*im, samplesize, boundary, ϕ, σ),
        c = :black,
        legend = false
    )
end

# ╔═╡ 87b23074-2e4b-467d-b2eb-d9ea8afc65e1
ϕ□ = rectanglefunction(
	-1,1,-1,1,
	t -> 1 - t^4,
	t -> t^4 - 1,
	t -> sin(π*t),
	t -> sin(π*t),
);

# ╔═╡ e040b96f-ae6e-49bb-a867-fb158efd0066
solutionplot□ = plotlaplace□(20, 1000, (-1,1,-1,1), ϕ□, 0.1);

# ╔═╡ 883dd2db-83a3-4663-a27d-cb959e2bea43
md"""
*The sliders below will only work in if this file is opened as a Pluto notebook*
"""

# ╔═╡ a42f3b5e-7d3d-45d6-8a6c-f77f49087072
md"""
Azimuth: $(@bind azimuthangle□ Slider(0:90, default = 60))
Elevation: $(@bind elevationangle□ Slider(0:90, default = 60))
"""

# ╔═╡ a2a14f4d-20b3-4c08-b99e-d7ae2392855e
plot(solutionplot□, camera = (azimuthangle□,elevationangle□))

# ╔═╡ d777e34b-0cef-4556-bd64-c5470b5e559a
md"""
Again, a grid size of 20 and a sample size of 1000 gives me a satisfactory visualisation of the approximation that this algorithm makes to the harmonic function solving Laplace's equation with the given boundary conditions.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Plots = "~1.20.1"
PlutoUI = "~0.7.9"
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
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "9995eb3977fbf67b86d0a0a0508e83017ded03f2"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.14.0"

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
git-tree-sha1 = "727e463cfebd0c7b999bbf3e9e7e16f254b94193"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.34.0"

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
git-tree-sha1 = "7d9d316f04214f7efdbb6398d545446e246eff02"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.10"

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
git-tree-sha1 = "d59e8320c2747553788e4fc42231489cc602fa50"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.58.1+0"

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
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

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
git-tree-sha1 = "2ca267b08821e86c5ef4376cffed98a46c2cb205"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.1"

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
git-tree-sha1 = "438d35d2d95ae2c5e8780b330592b6de8494e779"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.0.3"

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
git-tree-sha1 = "8365fa7758e2e8e4443ce866d6106d8ecbb4474e"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.20.1"

[[PlutoUI]]
deps = ["Base64", "Dates", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "Suppressor"]
git-tree-sha1 = "44e225d5837e2a2345e69a1d1e01ac2443ff9fcb"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.9"

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
git-tree-sha1 = "44a75aa7a527910ee3d1751d1f0e4148698add9e"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.1.2"

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
git-tree-sha1 = "3240808c6d463ac46f1c1cd7638375cd22abbccb"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.12"

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

[[Suppressor]]
git-tree-sha1 = "a819d77f31f83e5792a76081eee1ea6342ab8787"
uuid = "fd094767-a336-5f1f-9728-57cf17d0bbfb"
version = "0.2.0"

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
# ╟─75c95ffe-c921-4b1a-b5d9-8cf7426e4b92
# ╟─8afab5ff-a1d9-4db1-87d2-b5246de75779
# ╟─231214c8-77cb-44c8-85b6-c344774b1f1a
# ╟─fe14c2a8-9fb7-406e-8698-bd4b666ab436
# ╠═4fb3b524-419f-47b0-b8c4-42e768e23f2b
# ╟─369fd574-1291-4adc-8c1f-14e61f09aaa6
# ╠═48c79e2d-0fd1-4ab5-84fd-0d1e3b42ae58
# ╟─84e34c30-dcb0-469d-824a-74bccf23f077
# ╠═e05b6d48-0f68-4b12-95f5-651a561c5821
# ╟─7b48324b-5b5d-4b12-a21b-370877539cd7
# ╠═092bc8c9-f746-404c-8047-ab0e247d608a
# ╟─aeb9e7aa-8325-4fa3-9af0-a8a0297cac57
# ╠═64cdecff-16e7-4999-bce6-d8acd36fc297
# ╠═47754a40-a4d2-43c3-9b95-2ec10ba00f57
# ╟─d78168c3-e173-40c3-8b74-b40f87cffc18
# ╠═0e9309f4-03b2-47bb-bb07-5ef2cab164ed
# ╟─fa1fa07e-6041-4d9a-8d8a-5906552fd921
# ╠═e2666dc7-831e-436c-8b55-49fcb664e5c2
# ╟─9d3464c5-0686-41b3-8c45-7fd238ab5254
# ╟─86fd5808-36e4-4114-98cc-fe188518e78d
# ╠═75b2629b-711e-44f8-83f1-1770dfe967cb
# ╠═d800326f-4d88-4ff9-bb4c-e938a5c637df
# ╟─7b40cd66-a80b-4b1a-853d-f8be4643d5fa
# ╠═4fedd855-a323-479e-b196-57362d99f0fa
# ╟─50a4e8b9-a3e0-4eff-a060-82c584596b4d
# ╟─3f2f5c0f-63ee-430a-b86a-11882f072029
# ╠═fed215e1-126d-4d69-9abb-ab4a5f024ed6
# ╟─23e9c1bf-4379-4994-b975-2fa1e99fa923
# ╠═97852ab1-799c-4eb2-8ca7-604936b13293
# ╟─f1ad4dc1-f5ef-4df1-aa54-22441b391e6b
# ╠═5d322770-d6d9-440b-b488-5e1c57477847
# ╠═9e9511f7-1bfa-46df-98d8-4b3bafbd9150
# ╟─c125a698-8feb-43fc-9f25-fb199e0e1367
# ╟─830cb57b-e67b-4105-b9ad-17cad4f22504
# ╟─711b7d6e-8f36-4bd9-985e-75a174ed4fc3
# ╟─a4e68952-e2d8-40ae-81ac-f614ef091404
# ╟─3bd012e4-b0cd-46c3-9aca-527b303476b3
# ╠═40f4876c-a2fb-4f3d-88a4-d460b4d8b53b
# ╠═0b404fc3-2483-4c75-919a-09f652e75935
# ╟─32185868-cb3c-4f26-8933-c12497b02f8d
# ╠═720f07ba-0518-449c-a02e-43a503c66796
# ╟─bafeba49-956b-42aa-80ee-6c7d514da5d5
# ╠═c126d81b-2d9d-45b3-b19f-2ef2fd31745b
# ╟─3d81ba40-868b-4980-b16f-948750a21063
# ╠═98c98083-ab31-4532-857c-16d303cf5b8b
# ╠═30c1d94c-49e5-4824-b13c-5ad3bb3bafb7
# ╟─6560fe5e-c717-4f15-8eca-33d4e5db133d
# ╟─1504864d-f838-475a-99ac-bf28da99365d
# ╠═20da0c07-59d1-4294-a457-cc71181a00ff
# ╟─4283aa0f-c7de-4834-93eb-208834097338
# ╟─5c43e2b3-6070-477e-ab0d-9696f85f4dc5
# ╠═ae801ddc-0866-4a1f-be4c-7199ade3423c
# ╟─78e87873-247b-4ded-a563-10b008de1980
# ╟─7ef086b7-2016-4c36-820a-2884cd3281bc
# ╟─1a9c53ec-d4fb-4e07-a075-368ca422238e
# ╠═ed827bfc-dbdb-4b54-a4a4-35727925f5f1
# ╟─5c96bd07-1fcf-4f42-b325-59eef0295541
# ╠═c7b6fcba-9bc8-4da7-8545-011016b92bb4
# ╠═87b23074-2e4b-467d-b2eb-d9ea8afc65e1
# ╠═e040b96f-ae6e-49bb-a867-fb158efd0066
# ╟─883dd2db-83a3-4663-a27d-cb959e2bea43
# ╟─a42f3b5e-7d3d-45d6-8a6c-f77f49087072
# ╠═a2a14f4d-20b3-4c08-b99e-d7ae2392855e
# ╟─d777e34b-0cef-4556-bd64-c5470b5e559a
# ╟─64a062ea-c7d9-4908-a8ab-98552da66e0a
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
