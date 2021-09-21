### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ c8590734-c738-4225-9e4e-372f5ef7a63c
using Plots

# ╔═╡ bae4a3e4-2224-4e5d-ab15-bbdf86310ba8
begin
	using PlutoUI
	PlutoUI.TableOfContents(title = "Contents")
end

# ╔═╡ 133172e0-ee0f-11eb-3d88-efecd8115ca7
md"""
# Modelling infectious diseases
"""

# ╔═╡ 0f33ac97-eb86-40cf-aa65-8ffb51cdf37c
md"""
## Objectives
- Create and compare two different ``SIR`` models for infectious disease
  - Mathematically, the classical ``SIR`` model given in terms of differential equations
  - Computationally, an ``SIR`` model considering proximity of individuals
- _**Consider methods of increasing efficiency in Julia code**_
"""

# ╔═╡ 70d33a7a-edac-421c-a6e0-7acfd523871e
md"""
## What is an SIR model?

An ``SIR`` model models an infectious disease by splitting the population into three categories
- **Susceptible** (``S``) - Those who are susceptible to the disease, having not come into contact with it yet
- **Infectious** (``I``) - Those who have the disease and are able to pass it on to the susceptible population
- **Recovered** (``R``) - Those who have had the disease in the past but can no longer pass it on. This category is sometimes called **Removed** to be more inclusive to those who died from the disease

The model then has rules for how the size of the three categories changes with time. In the models in this case study, the total population `` N = S + I + R `` is fixed, but this doesn't have to be the case.

The two models that I will create in the following studies are:
- A simple yet effective model based on an intuitive system of differential equations, which I will refer to as the [mathematical model](#ed6cab5f-4fdb-4680-9978-6024aa57595c)
- A more complicated model attempting to simulate the disease passing between individuals, which I will refer to as the [computational model](#99d6153f-38ae-4ba4-a96e-509e9094bdb1)
"""

# ╔═╡ ed6cab5f-4fdb-4680-9978-6024aa57595c
md"""
## Mathematical model

The most simple and elegant ``SIR`` model is given by three differential equations:

```math
\frac{dS}{dt} = - \beta I S
```
```math
\frac{dI}{dt} = \beta I S - \nu I
```
```math
\frac{dR}{dt} = \nu I
```

although since we know that `` S + I + R `` is fixed, and the equations do not depend directly on ``R``, the first two will suffice. Here, ``\beta`` is the rate of infection, and ``\nu`` is the rate of recovery, which are parameters that I will be able to change later. 

To implement this in Julia, I will use the Forward Euler algorithm where

```math
\frac{dF}{dt} = f(t), \qquad F(0) = F_0
```

can be approximated for `` t > 0 `` by iteration of the form

```math
F(0) = F_0, \qquad F((n+1)\delta{}t) \approx F(n\delta{}t) + f(n\delta{}t) \delta{}t
```

where ``\delta{}t`` is some chosen step size (smaller is more accurate but requires more computation).

I start by choosing `δt` and a final time `T` up to which I will run the simulation.
"""

# ╔═╡ 728e28a5-d807-4751-858c-4a94873463be
δt = 0.001

# ╔═╡ 2598752b-f99f-457b-8192-b9e256c72e1e
T = 1

# ╔═╡ 828ec2df-aa76-44ff-b951-880e159cb82f
times = 0:δt:T

# ╔═╡ 262d57fa-8ab8-4a9e-a826-3c8550692811
ntimes = length(times)

# ╔═╡ fb7bb03b-bcf3-4d2c-a066-294256e2d92e
md"""
I also choose a population size `N`. The subscript `₁` denotes that this is the first model of the two.
"""

# ╔═╡ dc26b16a-25ba-4b16-9b52-16b912c4b8bb
N₁ = 10000

# ╔═╡ b75775ab-a852-4571-8e59-63b5083db3c2
md"""
I initialise vectors the same size as the list of times to track ``S`` and ``I`` (as mentioned earlier there is no need to track ``R``), with the initial values being one infectious individual and the rest susceptible.
"""

# ╔═╡ 5363d193-fb8a-469d-9e87-09ece19a01fe
S₁ = zeros(size(times));

# ╔═╡ 1751daa5-78e7-471c-8576-1c9acc2dd68c
S₁[1] = N₁ - 1;

# ╔═╡ 0533a017-889b-4f72-ad21-58f762f4fae2
I₁ = zeros(size(times));

# ╔═╡ 547bc8b9-22fb-4143-9eb6-8f2b4090ed65
I₁[1] = 1;

# ╔═╡ 64f43f00-eacb-4039-81b0-d09b94af8923
md"""
Finally, I choose values for the two parameters `β` and `ν`.
"""

# ╔═╡ 3fa04a1c-25eb-4fd4-aa77-f0296c83dd31
β = 0.005

# ╔═╡ 688bebd2-2d88-441c-90f6-9597de92a176
ν = 4

# ╔═╡ 310433cf-f3a6-4e4a-8f2c-c5d5967b5ad4
md"""
Forward Euler iteration can now begin. I am careful to make sure that `S`, `I`, and `S + I` remain between `0` and `N` at all times, although the model has clearly failed if this ever becomes a problem.
"""

# ╔═╡ 907983f7-0950-49ae-ba41-85da7ac577ed
for i ∈ 2:ntimes
    δS₁ = - β * I₁[i-1] * S₁[i-1] * δt
    δI₁ = - δS₁ - ν * I₁[i-1] * δt
    S₁[i] = min(max(S₁[i-1] + δS₁, 0),N₁)
    I₁[i] = min(max(I₁[i-1] + δI₁, 0),N₁ - S₁[i])
end

# ╔═╡ 16ff8546-92f0-4578-9310-28d8db1cb6e2
md"""
I can now calculate `R` from the values obtained for `S` and `I`.
"""

# ╔═╡ e20a2623-e0bc-4421-8726-8f81554d63b1
R₁ = N₁ .- (S₁ + I₁);

# ╔═╡ 1753a908-a344-40f6-b25d-6dbc124f5272
md"""
The `Plots` package allows me to visualise the results, which I will do in two forms, a line graph, and a stacked area graph.
"""

# ╔═╡ 5bb45fc2-1361-4555-952d-d50f9e6aea77
lineplot₁ = plot(
	times,
	[S₁ I₁ N₁ .- (S₁ + I₁)],
	label = ["Susceptible" "Infectious" "Recovered"],
	color = [:gold :red :blue]
)

# ╔═╡ 7fe01089-0b35-417e-b857-1b0ba3653ccd
areaplot₁ = areaplot(
	times,
	[S₁ I₁ N₁ .- (S₁ + I₁)],
	label = ["Susceptible" "Infectious" "Recovered"],
	color = [:gold :red :blue]
)

# ╔═╡ e794f4a0-fcad-427e-af49-7fd20ed11a10
md"""
An interesting alteration to make to this model is to introduce some randomness, for which I will need to introduce a vector to track ``R``. The randomness I will create by multiplying `δS`, `δI`, and `δR` by log-normally distributed random variables of parameters `μ = 0`, and `σ` a parameter I can set (note that `σ = 0` is equivalent to no randomness), and then normalising to keep `S + I + R` fixed.

It is now particularly essential that `S`, `I`, and `R` are kept between `0` and `N` since the randomness increases the chance for them to end up outside of that range.
"""

# ╔═╡ b3e54a43-a997-43bf-994c-19100d49f765
S₁′ = zeros(size(times));

# ╔═╡ f33ac3be-782d-4183-9c84-ee9c161d33ee
S₁′[1] = N₁ - 1;

# ╔═╡ 3b63e289-dddf-4460-bde9-ce6acd7607ab
I₁′ = zeros(size(times));

# ╔═╡ 6b7a449f-3fcc-457d-b268-39fddda134a2
I₁′[1] = 1;

# ╔═╡ 8c207e61-241c-4af1-a1dd-0f5580157de8
R₁′ = zeros(size(times));

# ╔═╡ 61c09dcb-b03a-485d-a954-9ebbc9501d35
σ = 1

# ╔═╡ 1641868a-a25b-499d-bc72-e6fff52036bc
for i ∈ 2:ntimes
    δS₁′ = - β * I₁′[i-1] * S₁′[i-1] * δt
	δR₁′ = ν * I₁′[i-1] * δt
	δI₁′ = - δS₁′ - δR₁′
    S₁′[i] = max(S₁′[i-1] + δS₁′ * exp(σ * randn()), 0)
    I₁′[i] = max(I₁′[i-1] + δI₁′ * exp(σ * randn()), 0)
	R₁′[i] = max(R₁′[i-1] + δR₁′ * exp(σ * randn()), 0)
	scale = (S₁′[i] + I₁′[i] + R₁′[i])/N₁
	S₁′[i] /= scale; I₁′[i] /= scale; R₁′[i] /= scale
end

# ╔═╡ 4670197e-4c4e-49ec-ad7d-ffdd0701631e
md"""
Plotting `S`, `I` and `R` now gives:
"""

# ╔═╡ d2821018-da14-45c2-a98e-47edf882a867
plot(
	times,
	[S₁′ I₁′ R₁′],
	label = ["Susceptible" "Infectious" "Recovered"],
	color = [:gold :red :blue]
)

# ╔═╡ a52bbb3c-3f25-46a0-819c-dce56bd7c75c
areaplot(
	times,
	[S₁′ I₁′ R₁′],
	label = ["Susceptible" "Infectious" "Recovered"],
	color = [:gold :red :blue]
)

# ╔═╡ 7a039123-2afd-4f2d-b47b-d05f3cb4f13c
md"""
There is only a small effect of randomness on making the curves less smooth. What it does do, however, is dramatically quicken both processes of infection and recovery. This can be explained as the exponential nature of the processes causing a feedback loop which amplifies the effects of random increases in rate while dulling the effects of random decreases in rate.
"""

# ╔═╡ 99d6153f-38ae-4ba4-a96e-509e9094bdb1
md"""
## Computational model
The second model which I will use simulates a population of ``N`` people with the disease propagating only between neighbours:
- ``N`` people are arranged in a grid, with one starting out as infectious and the rest susceptible
- At each step:
  - Any infectious individual passes on the disease to any of their four neighbours independently with probability ``p``
  - Any infectious individual recovers with probability ``q`` (can happen on the same step as passing on the disease, but not in the same step as getting passed the disease)
- This is run for a predetermined number of steps, with the numbers ``S``, ``I``, and ``R`` kept track of at all times

This model has some features that the first does not which may make it more realistic, such as:
- The population is discrete, allowing the disease to die out more easily
- The disease is localised so cannot infect those who are not in contact with it

However, due to the simulation of individuals rather than the simulation of the population as a whole, this is inevitably more computationally intensive. Hence, efficiency will be essential to make this model usable.

### Setting up the model
To begin with, I will set up the parameters for the model.
"""

# ╔═╡ df4d71fd-a752-46fd-bb18-908a23ee0cd0
sqrtN₂ = 100

# ╔═╡ 1086d559-ef39-405a-a113-a060b391ad9e
N₂ = sqrtN₂^2

# ╔═╡ 25922ea7-4054-4054-ba4a-f93dbee85503
p = 0.4

# ╔═╡ b39fb04a-1074-4441-9d6d-3612674475d9
q = 0.01

# ╔═╡ a87ed703-f514-41cf-8262-b5ace0a28e45
maxsteps = 500

# ╔═╡ b24a796c-4908-4ff9-b392-0781574829e4
md"""
The population of size `N₂` will be stored as a matrix of numbers (`sqrtN₂` by `sqrtN₂`), where `1` represents susceptible, `2` represents infectious, and `3` represents recovered.
"""

# ╔═╡ 7709c287-c7b8-4ffe-a257-4ada27454db3
population = fill(1, (sqrtN₂, sqrtN₂));

# ╔═╡ fdc5dd62-50e7-4423-880b-1dbde1aebea3
population[rand(1:N₂)] = 2;

# ╔═╡ a565879c-2938-4f5b-8de8-9807cdff3948
md"""
As before, vectors `S₂` and `I₂` will keep track of the number of susceptible and infectious individuals respectively after each step.
"""

# ╔═╡ d74fe014-47a1-4636-9360-83fc311307d2
S₂ = zeros(maxsteps+1);

# ╔═╡ b8903866-81e9-42b0-8bd7-263d5cbaf2b4
S₂[1] = N₂ - 1;

# ╔═╡ 94272156-621b-4ed5-8582-c079625fa977
I₂ = zeros(maxsteps+1);

# ╔═╡ ef4051e0-38f2-4dc6-a765-b0c76a4b0705
I₂[1] = 1;

# ╔═╡ 8fbf94ce-50f5-48a6-91ce-d2f67fa505e4
md"""
As an additional form of output, I will create an animation of the population at each stage, using the `Plots` package. I use the function `populationplot` to convert the matrix `population` into a heatmap where `1` is yellow, `2` is red, and `3` is blue (which is why I use numbers in the matrix). In order to maintain these colours, three additional pixels of each of these values are added, as otherwise `Plots` will change the scale if the range of values of the plot is not 1 to 3.
"""

# ╔═╡ dfc867ac-d8d7-4f90-9410-03746e134443
function populationplot(population::Matrix{Int64})
    return heatmap(
        hcat(population, fill(missing, sqrtN₂),
			[1,2,3, fill(missing, sqrtN₂ - 3)...]),
        legend = false,
        color = [:gold, :red, :blue],
        size = (4*sqrtN₂,4*sqrtN₂),
        showaxis = false,
        ticks = false
    )
end

# ╔═╡ f4e7d095-13c3-40dc-b248-61d8a065d61c
begin
	anim₂ = Animation()
	frame(anim₂, populationplot(population))
end;

# ╔═╡ 559aeb30-0d2e-4077-9af1-b4ed4702f9e5
md"""
I am now ready to carry out the iteration. For each step, I would like to do the following:

- Initialise empty lists of indices for points which will become red and points that will become blue
```julia
reds = CartesianIndex{2}[]
blues = CartesianIndex{2}[]
```

- Iterating over each member of the population, check whether they are infectious
```julia
for j ∈ 1:sqrtN₂, i ∈ 1:sqrtN₂
    if population[i,j] == 2
		# loop
	end
end
```

- For those which are infectious, infect each susceptible neighbour with independent probability `p`, and recover with probability `q`, adding the appropriate indices to the lists `reds` and `blues`
```julia
i > 1 && population[i-1,j] == 1 && rand() < p && push!(reds,CartesianIndex(i-1,j))
j > 1 && population[i,j-1] == 1 && rand() < p && push!(reds,CartesianIndex(i,j-1))
i < sqrtN₂ && population[i+1,j] == 1 && rand() < p &&
	push!(reds,CartesianIndex(i+1,j))
j < sqrtN₂ && population[i,j+1] == 1 && rand() < p &&
	push!(reds,CartesianIndex(i,j+1))
rand() < q && push!(blues,CartesianIndex(i,j))
```

- Once this is complete, update the status of the population with the new `reds` and `blues`
```julia
population[reds]  .= 2
population[blues] .= 3
```

- Create the next frame of the animation
```julia
frame(anim₂, populationplot(population))
```

- Calculate the new number of susceptible and infectious
```julia
nnewreds, nnewblues = (length ∘ unique! ∘ sort!)(reds), length(blues)
S₂[n] = S₂[n-1] - nnewreds
I₂[n] = I₂[n-1] + nnewreds - nnewblues
```

- If the disease has died out (i.e. no more infectious), stop the loop, since there is no point in continuing
```julia
I₂[n] == 0 && (S₂ = S₂[1:n]; I₂ = I₂[1:n]; break)
```

This I combine into one large loop.
"""

# ╔═╡ dc815f4e-a731-4e6d-987d-9a9db7ee5270
for n ∈ 2:(maxsteps+1)
    reds = CartesianIndex{2}[]
    blues = CartesianIndex{2}[]
    for j ∈ 1:sqrtN₂, i ∈ 1:sqrtN₂
        if population[i,j] == 2
            i > 1      && population[i-1,j] == 1 && rand() < p &&
				push!(reds,CartesianIndex(i-1,j))
            j > 1      && population[i,j-1] == 1 && rand() < p &&
				push!(reds,CartesianIndex(i,j-1))
            i < sqrtN₂ && population[i+1,j] == 1 && rand() < p &&
				push!(reds,CartesianIndex(i+1,j))
            j < sqrtN₂ && population[i,j+1] == 1 && rand() < p &&
				push!(reds,CartesianIndex(i,j+1))
            rand() < q && push!(blues,CartesianIndex(i,j))
        end
    end

    population[reds]  .= 2
    population[blues] .= 3
    frame(anim₂, populationplot(population))

    nnewreds, nnewblues = (length ∘ unique! ∘ sort!)(reds), length(blues)
    S₂[n] = S₂[n-1] - nnewreds
    I₂[n] = I₂[n-1] + nnewreds - nnewblues
    I₂[n] == 0 && (S₂ = S₂[1:n]; I₂ = I₂[1:n]; break)
end

# ╔═╡ 3e2119c2-9482-482b-8caf-f9d386ae0522
md"""
From `S` and `I`, I calculate `R` as before.
"""

# ╔═╡ 466ab0b6-fb5e-4354-ae91-20c7bc20a583
R₂ = N₂ .- (S₂ + I₂);

# ╔═╡ 8ef0ac34-d033-4515-af2d-9f44c6749977
md"""
Finally, the visualisations can be created. First, I plot the animation of the spread of the infection, and then the same two graphs as were plotted for the first model.
"""

# ╔═╡ ba404ab9-794d-499f-b41a-7601a994e42e
gif₂ = gif(anim₂)

# ╔═╡ fa9bcbb8-927f-45cd-96c1-14ff760b2af8
lineplot₂ = plot(
	0:length(S₂)-1,
	[S₂ I₂ R₂],
	label = ["Susceptible" "Infectious" "Recovered"],
	color = [:gold :red :blue]
)

# ╔═╡ fff03d6e-741b-48a6-b90f-89a52f4d707e
areaplot₂ = areaplot(
	0:length(S₂)-1,
	[S₂ I₂ R₂],
	label = ["Susceptible" "Infectious" "Recovered"],
	color = [:gold :red :blue]
)

# ╔═╡ df111c85-33bf-4ca1-846e-a20e3491dcbd
md"""
### Efficiency considerations

The second model took noticeably more effort for me to program than the first. This is mainly because it is more complicated, and in this instance, with complexity comes slowness. For this reason, I had to make many changes to my initial attempt in order to optimise it.

Here is a snippet of an early draft of the program for the second model:
```julia
population = fill(:gold, (sqrtN₂, sqrtN₂))
population[rand(1:N₂)] = :red

anim₂ = Animation()
function populationplot(population::Matrix{Symbol})
	return scatter(
		[(i,j) for j ∈ 1:sqrtN₂, i ∈ 1:sqrtN₂][:],
		markersize = 3,
		markercolor = population[:],
		markerstrokewidth = 0,
		size = (4*sqrtN₂, 4*sqrtN₂),
		legend = false,
		showaxis = false,
		ticks = false
	)
end
frame(anim₂,populationplot(population))

for n ∈ 2:(maxsteps+1)
	newpopulation = copy(population)
	for j ∈ 1:sqrtN₂, i ∈ 1:sqrtN₂
        if population[i,j] == :red
            i > 1 && population[i-1,j] == :gold && rand() < p &&
				newpopulation[i-1,j] = :red
            j > 1 && population[i,j-1] == :gold && rand() < p &&
				newpopulation[i,j-1] = :red
            i < sqrtN₂ && population[i+1,j] == :gold && rand() < p &&
				newpopulation[i+1,j] = :red
            j < sqrtN₂ && population[i,j+1] == :gold && rand() < p &&
				newpopulation[i,j+1] = :red
            rand() < q && newpopulation[i,j] = :blue
        end
    end
	
	population = newpopulation
	frame(anim₂,populationplot(population))
	
	S₂[n] = count(==(:gold), population)
	I₂[n] = count(==(:red), population)
	I₂[n] == 0 && (S₂ = S₂[1:n]; I₂ = I₂[1:n]; break)
end
```
"""

# ╔═╡ 9756b3f3-e826-4b6d-ac4f-54ea7a5d43d1
md"""
With experience coding in Julia (and in general), you can pick up tips and tricks for efficiency that become almost automatic for you to include. Some examples of this in this instance are already included in my early draft, and some could be added in:

- Julia orders the elements of matrices by columns then rows, i.e the next element of a matrix `A` after `A[i,j]` is `A[i+1,j]` (the element below it). Note that this is opposite to some other languages, such as Python. A consqeuence of this is that when looping over matrices, the outer loops should loop over the columns, and the inner loop over the rows, since then the entries are being accessed in exactly the order that they lie in memory. In the example above, this is the reason why I have written:
```julia
for j ∈ 1:sqrtN₂, i ∈ 1:sqrtN₂
```
- Another way of fixing this is to use `eachindex`, which gives an efficient way of iterating over an array (with syntax `for i ∈ eachindex(A)`). This is better when the row and column indices are irrelevant to the operation inside the loop, but I needed the indices, it isn't the right choice here.

- If multiple conditions need to be checked, it makes sense to check the fastest and/or most likely to fail first, since then the loop can move on quicker. This is seen in the draft, where the probability `p` checks are only made after checking that the target individual is susceptible, since that is a quick operation and is quite likely to not be true

- There is no need to work with large amounts of data when a small amount will do, in particular the matrix `newpopulation`, which is inefficiently copied from `population` only for most of the entries to remain the same since no infection or recovery happened there. This I fixed by introducing the lists `reds` and `blues` of points which have become red/blue, and then changing the values in the matrix `population` once finished, as can be seen in the final program. The `CartesianIndex` type is used to store these indices since it allows the assignment of values to a list of indices with `.=` as shown below, while storing indices as a vector of tuples or as a matrix would not give as neat a solution.
```julia
reds = CartesianIndex{2}[]
blues = CartesianIndex{2}[]
⋮
population[reds]  .= :red
population[blues] .= :blue
```

- Since I now have the list of `reds` and `blues` that are changing at this step, there is no need to count `S[n]` and `I[n]` so inefficiently. Instead, I need only count how many are changing and add to / subtract from the previous value. For `blues`, this is simple, but for `reds` there could be duplicates (if two infectious people infect the same susceptible person that they both neighbour). `unique!` would do this, but the documentation notes that if the order of the original points isn't needed (which it isn't), then `unique! ∘ sort!` is better.
```julia
nnewreds, nnewblues = (length ∘ unique! ∘ sort!)(reds), length(blues)
S₂[n] = S₂[n-1] - nnewreds
I₂[n] = I₂[n-1] + nnewreds - nnewblues
```

- More examples of this sort of optimisation can be found at <https://docs.julialang.org/en/v1/manual/performance-tips/>
"""

# ╔═╡ 6733d7f2-c434-4719-9ae8-e15fa58779ce
md"""
The next place to look for improvements in efficiency is in profiling, which helps to find which places in the code are taking the longest, and where improvements to be made. This is implemented by the inbuilt package `Profile`, although for better visualisation, the package `ProfileView` is needed.
```julia
using ProfileView
```
Profiling works best for testing individual functions, although it is important to make sure that the functions are compiled first before running the test (this can be achieved by running the function, or by profiling twice and taking the second result as true). However, in this instance, I don't have a single function to test, but an entire program, so I run the program once to compile it, and then run
```julia
ProfileView.@profview include("<file-path>")
```
This produces a flame graph, which is a graph made up of stacked horizontal bars. Each bar represents a function called within the process of running the program, with the length denoting the length of time spent in that function, and each bar lying below all the bars representing the functions that it calls within that time. Usually, the best place to look for potential improvements are the longest bars, constituting the functions that are the slowest / called the most times within the program. Once you have identified these places, you can consider how you can rewrite these sections of code to speed them up. Flame graphs can also be saved to compare different iterations of the program, which can also help this process.

An advantage of using editors is that they can also have their own inbuilt tools for profiling. One example of this is in VSCode, where the Julia extension comes with an inbuilt package `VSCodeServer` with its own version of `@profview`. Again, run the function or program once, before running
```julia
VSCodeServer.@profview include("<file-path>")
```
Instead of a flame graph, this produces a list of all of the functions called in the process of running ordered by "Self Time", that is the time for the functions themselves to run, ignoring those functions that they call. It also annotates the code with times, showing the lines of code which take the most. The flame graph from `ProfileView` can be obtained from the same run with
```julia
ProfileView.view()
```
Both methods of visualisation of the profile are valuable to understand where to look for gains in efficiency.

In the case of my program, I found that the majority of the time came from calls to `Plots` functions (and related packages, such as `GR` which is the backend that I am using for generating the graphs). My initial thought was that this may be because drawing the entire graph after each step may be inefficient, but amending this to instead add red and blue points to the graph at each step made little difference. This seems to be because with so many points on the graph, drawing it in order to capture a frame gets slower and slower with each step.

The solution that I settled on was to shift from manually drawing a scatter graph from a matrix of colours to drawing a heatmap from a matrix of numbers with custom colours. The heatmap is plotted similarly to the scatter graph, however it is already optimised to be efficient, unlike my own code, so it is a better choice.
"""

# ╔═╡ 53984f21-33d9-46b8-b08c-d15e044f2752
md"""
If the program still isn't fast enough, it is possible that more radical changes need to be made. The algorithm itself may be at fault, in which case there is nothing more that you can do then attempt to alter it or look elsewhere for a better one (if the constraints of the project allow you to do so). An important (but by no means only) consideration to make is the complexity of the algorithm, that is the rate at which the speed of the algorithm scales with increasing the size of the inputs or relevant parameters. Lower complexity algorithms tend to be faster, although if a large amount of overhead is required to lower the complexity it may not be worthwhile for realistically sized inputs.

For the mathematical model, the most relevant parameter is `ntimes` (or `δt` assuming that `T` is fixed). Each loop contains the exact same calculations, so the total complexity of the algorithm is ``O(n)`` (where ``n = `` `ntimes`).

For the computational model, (ignoring early termination, since complexity calculations always assume the worst case) the length of the loop is `maxsteps`, but the time that each iteration takes depends on the size of `I`. The worst case is that all neighbours are infected and none ever recover, with the assumption that `N` is large enough that this doesn't hit the border within `maxsteps` iterations, giving a sequence
```math
I_n = 1, 5, 13, 25,...
```
which are the [centered square numbers](http://oeis.org/A001844), increasing at a rate of ``I_n = O(n^2)``. Hence, the complexity of the second algorithm is (in terms of ``m = `` `maxsteps`) is
```math
\sum_{n = 2}^{m+1} O(n^2) = O(m^3)
```

This, however, demonstrates the limitations of considering complexity, since I already know that this part of the algorithm isn't the slow bit (even if theoretically it may be for larger `maxsteps`). In this instance, the higher complexity is pretty irrelevant for explaining the discrepancy in speed between the two algorithms, instead it is the formation of the animated visualisation which takes up most of the time.
"""

# ╔═╡ 23608a2c-77cb-4401-b598-9a7eb3d8d469
md"""
## Comparison of the two models

Since we have line graphs and stacked area graphs for both models, we can examine them side-by-side to compare the two models. On the left are the results of the first model (not including randomness), and on the right are the results of the second:

*Note for Pluto users: the analysis below is performed using the default parameters. If you have experimented with different values, it may be best to reload the notebook to see the intended graphs*
"""

# ╔═╡ 3df2b0f4-a7ae-4ad6-aad5-255330edf54b
plot(lineplot₁, areaplot₁, lineplot₂, areaplot₂, layout = (2,2), size = (800,600))

# ╔═╡ 87cac64d-90a8-431c-8179-7f7462e5c11a
md"""
Obviously, the two models are parameterised completely differently, so there is no reason to expect them to match perfectly. However, there is one clear difference between the two, which is the rate of propagation of the infection through the population, which is markedly quicker in the mathematical model.

To explain the difference, we need only look at the two algorithms. From the differential equations defining the first, when ``I`` is small and ``S`` is large,
`` \frac{dI}{dt} \approx \beta I S ``, giving (near) exponential growth. Meanwhile, as already seen when considering the complexity of the second algorithm, the growth in ``I`` is at most quadratic, and indeed with this parametrisation, is almost linear. Hence, even though the computational model is intended to be more realistic, it cannot model the phenomenon of exponential growth of infections which is seen in the real world. In my view, this is probably because although some level of contact is simulated, it does not come close to the sort of contact between individuals which actually occurs, since individuals only come into contact with four people all of whom are already in close contact anyway (perhaps it is more accurate as a model of maths students than the population as a whole).

In contrast, the recovery curves for the two models are almost identical. Again, this can be predicted by studying the algorithms. In the first, with `` S \approx 0 ``, `` \frac{dI}{dt} \approx - \nu I ``, which results in exponential decay. For the second model, each infectious person recovers with probability `q`, so ``I_n \approx q I_{n-1} ``, again giving exponential decay. The parameters that I have chosen make this even more obvious since they cause the blue Recovered curves to resemble each other very well, indeed:
"""

# ╔═╡ ba1205e6-dcde-4c44-a246-5bc180085ec7
begin
	recoverycomparison = plot(
		times,
		R₁,
		color = :deepskyblue,
		label = "Mathematical model",
		legend = :topleft,
		showaxis = false,
		ticks = false
	)
	plot!(
		recoverycomparison,
		(0:maxsteps) / maxsteps,
		R₂,
		color = :navy,
		label = "Computational model"
	)
end

# ╔═╡ 89c2bc30-220c-4add-8bc8-21b5b610d45b
md"""
Overall, I think that the mathematical model is a better model for infectious disease, although with some alterations to increase contact, the computational model may be able to equal it, with the added bonus of a visualisation of the disease spreading among the population rather than just the macroscopic graphs that the its competitor provides.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Plots = "~1.19.3"
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
git-tree-sha1 = "dc7dedc2c2aa9faf59a55c622760a25cbefbe941"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.31.0"

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
git-tree-sha1 = "9f473cdf6e2eb360c576f9822e7c765dd9d26dbc"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.58.0"

[[GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "eaf96e05a880f3db5ded5a5a8a7817ecba3c7392"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.58.0+0"

[[GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "15ff9a14b9e1218958d3530cc288cf31465d9ae2"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.3.13"

[[Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "47ce50b742921377301e15005c96e979574e130b"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.1+0"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "c6a1fff2fd4b1da29d3dccaffb1e1001244d844e"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.12"

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
git-tree-sha1 = "6a8a2a625ab0dea913aba95c11370589e0239ff0"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.6"

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
git-tree-sha1 = "c8abc88faa3f7a3950832ac5d6e690881590d6dc"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "1.1.0"

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
git-tree-sha1 = "1bbbb5670223d48e124b388dee62477480e23234"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.19.3"

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
git-tree-sha1 = "1b9a0f17ee0adde9e538227de093467348992397"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.7"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StatsAPI]]
git-tree-sha1 = "1958272568dc176a1d881acb797beb909c785510"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.0.0"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "2f6792d523d7448bbe2fec99eca9218f06cc746d"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.8"

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
git-tree-sha1 = "8ed4a3ea724dac32670b062be3ef1c1de6773ae8"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.4.4"

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
# ╟─133172e0-ee0f-11eb-3d88-efecd8115ca7
# ╟─0f33ac97-eb86-40cf-aa65-8ffb51cdf37c
# ╟─70d33a7a-edac-421c-a6e0-7acfd523871e
# ╟─ed6cab5f-4fdb-4680-9978-6024aa57595c
# ╠═728e28a5-d807-4751-858c-4a94873463be
# ╠═2598752b-f99f-457b-8192-b9e256c72e1e
# ╠═828ec2df-aa76-44ff-b951-880e159cb82f
# ╠═262d57fa-8ab8-4a9e-a826-3c8550692811
# ╟─fb7bb03b-bcf3-4d2c-a066-294256e2d92e
# ╠═dc26b16a-25ba-4b16-9b52-16b912c4b8bb
# ╟─b75775ab-a852-4571-8e59-63b5083db3c2
# ╠═5363d193-fb8a-469d-9e87-09ece19a01fe
# ╠═1751daa5-78e7-471c-8576-1c9acc2dd68c
# ╠═0533a017-889b-4f72-ad21-58f762f4fae2
# ╠═547bc8b9-22fb-4143-9eb6-8f2b4090ed65
# ╟─64f43f00-eacb-4039-81b0-d09b94af8923
# ╠═3fa04a1c-25eb-4fd4-aa77-f0296c83dd31
# ╠═688bebd2-2d88-441c-90f6-9597de92a176
# ╟─310433cf-f3a6-4e4a-8f2c-c5d5967b5ad4
# ╠═907983f7-0950-49ae-ba41-85da7ac577ed
# ╟─16ff8546-92f0-4578-9310-28d8db1cb6e2
# ╠═e20a2623-e0bc-4421-8726-8f81554d63b1
# ╟─1753a908-a344-40f6-b25d-6dbc124f5272
# ╠═c8590734-c738-4225-9e4e-372f5ef7a63c
# ╠═5bb45fc2-1361-4555-952d-d50f9e6aea77
# ╠═7fe01089-0b35-417e-b857-1b0ba3653ccd
# ╟─e794f4a0-fcad-427e-af49-7fd20ed11a10
# ╠═b3e54a43-a997-43bf-994c-19100d49f765
# ╠═f33ac3be-782d-4183-9c84-ee9c161d33ee
# ╠═3b63e289-dddf-4460-bde9-ce6acd7607ab
# ╠═6b7a449f-3fcc-457d-b268-39fddda134a2
# ╠═8c207e61-241c-4af1-a1dd-0f5580157de8
# ╠═61c09dcb-b03a-485d-a954-9ebbc9501d35
# ╠═1641868a-a25b-499d-bc72-e6fff52036bc
# ╟─4670197e-4c4e-49ec-ad7d-ffdd0701631e
# ╠═d2821018-da14-45c2-a98e-47edf882a867
# ╠═a52bbb3c-3f25-46a0-819c-dce56bd7c75c
# ╟─7a039123-2afd-4f2d-b47b-d05f3cb4f13c
# ╟─99d6153f-38ae-4ba4-a96e-509e9094bdb1
# ╠═df4d71fd-a752-46fd-bb18-908a23ee0cd0
# ╠═1086d559-ef39-405a-a113-a060b391ad9e
# ╠═25922ea7-4054-4054-ba4a-f93dbee85503
# ╠═b39fb04a-1074-4441-9d6d-3612674475d9
# ╠═a87ed703-f514-41cf-8262-b5ace0a28e45
# ╟─b24a796c-4908-4ff9-b392-0781574829e4
# ╠═7709c287-c7b8-4ffe-a257-4ada27454db3
# ╠═fdc5dd62-50e7-4423-880b-1dbde1aebea3
# ╟─a565879c-2938-4f5b-8de8-9807cdff3948
# ╠═d74fe014-47a1-4636-9360-83fc311307d2
# ╠═b8903866-81e9-42b0-8bd7-263d5cbaf2b4
# ╠═94272156-621b-4ed5-8582-c079625fa977
# ╠═ef4051e0-38f2-4dc6-a765-b0c76a4b0705
# ╟─8fbf94ce-50f5-48a6-91ce-d2f67fa505e4
# ╠═dfc867ac-d8d7-4f90-9410-03746e134443
# ╠═f4e7d095-13c3-40dc-b248-61d8a065d61c
# ╟─559aeb30-0d2e-4077-9af1-b4ed4702f9e5
# ╠═dc815f4e-a731-4e6d-987d-9a9db7ee5270
# ╟─3e2119c2-9482-482b-8caf-f9d386ae0522
# ╠═466ab0b6-fb5e-4354-ae91-20c7bc20a583
# ╟─8ef0ac34-d033-4515-af2d-9f44c6749977
# ╠═ba404ab9-794d-499f-b41a-7601a994e42e
# ╠═fa9bcbb8-927f-45cd-96c1-14ff760b2af8
# ╠═fff03d6e-741b-48a6-b90f-89a52f4d707e
# ╟─df111c85-33bf-4ca1-846e-a20e3491dcbd
# ╟─9756b3f3-e826-4b6d-ac4f-54ea7a5d43d1
# ╟─6733d7f2-c434-4719-9ae8-e15fa58779ce
# ╟─53984f21-33d9-46b8-b08c-d15e044f2752
# ╟─23608a2c-77cb-4401-b598-9a7eb3d8d469
# ╠═3df2b0f4-a7ae-4ad6-aad5-255330edf54b
# ╟─87cac64d-90a8-431c-8179-7f7462e5c11a
# ╠═ba1205e6-dcde-4c44-a246-5bc180085ec7
# ╟─89c2bc30-220c-4add-8bc8-21b5b610d45b
# ╟─bae4a3e4-2224-4e5d-ab15-bbdf86310ba8
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
