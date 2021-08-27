### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ f1d0ed8f-bfd3-4210-84fd-f189bba6ebf9
begin
	using PlutoUI
	PlutoUI.TableOfContents(title = "Contents")
end

# ╔═╡ 08eadc12-f8e9-11eb-1094-b7adc6936aa1
md"""
# Permutations
"""

# ╔═╡ c4d2ff29-2579-4079-a6cb-29015ef5ecd2
md"""
## Objectives
- _**Create a custom type**_ to represent a permutation
- _**Utilise multiple dispatch to create new methods for inbuilt functions**_ with `Permutation` objects as arguments
- Generate the elements of groups from generators in `Permutation` form
"""

# ╔═╡ db919e43-6dc8-4e53-8081-d9312446117a
md"""
## What is multiple dispatch?
Multiple dispatch is a feature central to the design of Julia with incredibly powerful consequences. In a most basic sense, it allows for the same function name to be used for multiple different operations, such as `-` being used for unary minus (``x \to -x``) as well as for subtraction. More generally, if the types of the inputs are specified differently for different declarations of the function, the function can act differently depending on the inputs that it gets. An example of this inbuilt into Julia is `a * b`, which multiplies `a` and `b` if they are numbers, and concatenates `a` and `b` if they are strings:
"""

# ╔═╡ 524dee4b-6687-44de-af79-b99d3724f9ac
3 * 4

# ╔═╡ a16202d3-406a-4b43-807e-b60c673d4132
"3" * "4"

# ╔═╡ 41fc4769-5b67-4503-b1d1-2854a0d9c3a2
md"""
These, or similar examples, are duplicated notation common to most programming languages, but what Julia allows that others don't is for your own custom functions to utilise multiple dispatch as well. For example, say that I want to check if an input is four or not, but I don't mind if the input is a number or a string. To do this, I follow the argument with double colons and the type to determine when this method will run (here `Number` is an abstract type, which cannot itself be the type of an object, but encompasses all numeric types into one keyword). Note that such notation of arguments can still be used for functions with only a single methods, where it can be helpful for debugging purposes.
"""

# ╔═╡ acf690f4-b65b-4576-9145-1e894d5342f2
isfour(x::String) = (lowercase(x) ∈ ["4", "four"])

# ╔═╡ 9f193c51-b6ea-477f-ab0e-1bc5a4be4b86
md"""
`isfour` is now defined for a `Number` and a `String` input, but not currently for anything else. If I decide that nothing else can be considered as four, then I can create a third method using the keyword `Any` (the abstract type representing all possible types) which will deal with everything else:
"""

# ╔═╡ 29b729bb-cd1a-4ee1-ae2e-26b55ce744a4
isfour(x::Any) = false

# ╔═╡ 740f8275-ee0c-4aa2-b0c1-76d46fad3ecd
md"""
Of course, an input like `4` is also of type `Any`, but Julia's type system recognises that `Number` is more restrictive and so is of higher precedence, hence any `Number` input to `isfour` triggers the specialised method for that type.

More of the power of multiple dispatch is illustrated later in this case study.
"""

# ╔═╡ 73d93917-b72e-468b-970c-f34ec6d51de4
md"""
## Creating the `Permutation` type

### Declaring `Permutation` as a new type
I begin by declaring a new type with the keyword `struct`. The most basic syntax to do this is:
```julia
struct Permutation
    image::Vector{Int64}
end
```

although I will want more functionality than this. The new type has a single field `image` which is a vector of integers, representing the images of ``1, 2, \dots n`` under the permutation (where ``n`` is the maximum integer permuted). For example, the permutation ``(123)(45)`` has image ``(2, 3, 1, 5, 4)^T``, and can be created as an object by the syntax:
```julia
σ = Permutation([2,3,1,5,4])
```

Its field will also be accessible through dot notation by:
```julia
σ.image
```
"""

# ╔═╡ c18ae801-b186-44cf-9e42-83188c4781aa
md"""
There are currently some issues with the new type, primarily that at the moment any vector of integers could be the image of a `Permutation`, so I need to be able to check that an image is valid, i.e.
- The image contains all of the integers ``1, 2, ..., n`` for some ``n`` exactly once
- The image contains nothing else

I will also impose an additional condition, which is that the largest integer `n` must not be fixed, since there is no point in storing it. However, this can be amended within the code, rather than rejecting such an image vector.

The way to impose these conditions is to use an inner constructor, which is a method within the `struct` block.
```julia
struct Permutation
    image::Vector{Int64}

	function Permutation(image::Vector{Int64})
		# Inner constructor code
	end
end
```

To check that the vector `image` contains the right elements, I sort it and compare it to the vector `1:n`, where `n` is the length of `image`.
```julia
sort(image) == 1:length(image)
```

Then, I find the integers which aren't fixed by using Boolean indexing, which is indexing an array with an array of `true`s and `false`s of the same size, and taking the elements which correspond to `true`. The maximum of them is then found, with `1` added to the list since `maximum` cannot find the maximum element of an empty vector.
```julia
m = maximum([image[image .!= 1:length(image)]..., 1])
```

Now, I can make use of the inner constructor specific keyword `new` to construct the permutation, by ordering the arguments as they would be if I were calling the `Permutation` function. With an error message if the conditions are not met by `image`, this completes my inner constructor
```julia
function Permutation(image::Vector{Int64})
    sortedimage = sort(image)
 	m = maximum([image[image .!= 1:length(image)]..., 1])
    sortedimage == 1:last(sortedimage) && return new(image[1:m])
    error("not a valid permutation")
end
```
"""

# ╔═╡ 99fe42de-2afa-409f-9416-5c7671e4d0f4
md"""
One last thing I want to adjust before I am done with the `Permutation` type is to be able to construct a permutation by just giving it a list of integers and not having to wrap them up in vector form myself. This I do by utilising multiple dispatch, with an outer constructor, which is simply a new method with different inputs to construct a `Permutation` object.
```julia
Permutation(imagevals::Int64...) = Permutation([x for x ∈ imagevals])
```

Putting this all together, I get (including some code from later sections, due to the reactivity of the Pluto notebook in which this is written):
"""

# ╔═╡ b9c535e5-3317-4291-9925-696bc6cb0252
begin
	struct Permutation
    	image::Vector{Int64}
		
	    function Permutation(image::Vector{Int64})
    	    sortedimage = sort(image)
        	m = maximum([image[image .!= 1:length(image)]..., 1])
	        sortedimage == 1:last(sortedimage) && return new(image[1:m])
    	    error("not a valid permutation")
	    end
	end

	Permutation(imagevals::Int64...) = Permutation([x for x ∈ imagevals])
	
	# See section Evaluating a Permutation as a function below
	maxarg(σ::Permutation) = length(σ.image)
	(σ::Permutation)(x::Int64) = x ∈ 1:maxarg(σ) ? σ.image[x] : x
	
	# See section Generating groups with Permutations
	import Base.:(==)
	==(σ::Permutation, τ::Permutation) = (σ.image == τ.image)
	
	nothing
end

# ╔═╡ 1d56249e-d86a-4d1e-b7d2-6d63a621bfa8
isfour(x::Number) = (x == 4)

# ╔═╡ 9ab255ff-b40a-4f16-bed8-fe14e4495502
isfour(4.0)

# ╔═╡ 98750bd0-84bd-4cb1-900b-9ee26142e4ec
isfour("Twelve")

# ╔═╡ 4e4508db-47c0-462f-9cec-93e52bbffd7c
isfour([4])

# ╔═╡ de16f61d-853a-43ed-adf0-fb77ea3c8f4a
σ = Permutation(4,5,1,3,2); σ.image

# ╔═╡ 322f2dbc-f8f4-4f62-a9bb-ea6b00a333ae
md"""
### Evaluating a `Permutation` as a function
I now have a `Permutation` object, but it doesn't do anything yet. The next step is to be able to use a Permutation object as the function that it represents, i.e. evaluate it at an integer. I can do this by defining a function with its name as a `Permutation` parameter:
```julia
(σ::Permutation)(x::Int64) = σ.image[x]
```

However this will give an error for any integer not between `1` and the maximum unfixed integer (`m` in the inner constructor), since no such index exists. Instead, I want it to fix all other integers, which will make composing permutations later much easier, so I amend the code, defining a new function `maxarg` to go with it:
```julia
maxarg(σ::Permutation) = length(σ.image)
(σ::Permutation)(x::Int64) = x ∈ 1:maxarg(σ) ? σ.image[x] : x
```

This is included in the block above with the constructors. I can test the result of this on the sample permutation `σ` defined above
"""

# ╔═╡ ff8ab6b4-34de-44eb-b98a-2f5e0f1c48fc
σ(4)

# ╔═╡ 5ce89616-326b-4404-9f2f-707c91835fa3
maxarg(σ)

# ╔═╡ 9617f0f2-1b45-418f-8818-26df1abde6cb
md"""
### Creating a custom display format for a `Permutation` object
At the moment, whenever a `Permutation` object is returned, it displays in the default form for a new `struct`, which is the name of the type followed by a list of its fields (in this case `σ` would look like `Permutation([4, 5, 1, 3, 2])`). This isn’t very useful, so be more understandable (and more in keeping with standard mathematical notation), I want to customise this displayed form, which I can do with multiple dispatch by adding a method to the function `show` specifically for the `Permutation` type.

The format that I want to display the permutation in is as its disjoint cycle decomposition. This will first require a function to calculate the orbit generated by acting repeatedly on a given element:
"""

# ╔═╡ ee9d45f3-0a25-47f6-8445-8ba733c3a8f6
function orbit(σ::Permutation, x::Int64)
    orb = [x]
    y = σ(x)
    while y != x
        push!(orb,y)
        y = σ(y)
    end
    return orb
end

# ╔═╡ b119e9f0-b8ba-42a3-a76c-82ed2dc170a4
md"""
To calculate the disjoint cycle decomposition, I build up the output as follows:
- I start out with an empty `Vector{Vector{Int64}}` (that is, a vector whose elements are vectors of integers)
```julia
decomp = Vector{Int64}[]
```

- A vector `unaccounted` tracks which values in the range `1:maxarg(σ)` are yet to be added to the decomposition. I will iterate until this vector is entirely false
```julia
unaccounted = trues(maxarg(σ))

while any(unaccounted)
    # code to iterate
end
```

- Inside the loop, I will look for the first value which is unaccounted for in the decomposition so far, calculate its orbit, and then update `unaccounted` accordingly
```julia
x = findfirst(unaccounted)
xorbit = orbit(σ,x)
unaccounted[xorbit] .= false
```

- Then, if the orbit is non-trivial, I add it to the decomposition
```julia
length(xorbit) > 1 && push!(decomp,xorbit)
```

This results in `decomp` being a list of cycles exactly determining the disjoint cycle decomposition.
"""

# ╔═╡ e4ce9583-5c18-4df7-a5fb-a46670fe40af
function dcd(σ::Permutation)
    decomp = Vector{Int64}[]
    unaccounted = trues(maxarg(σ))
    while any(unaccounted)
        x = findfirst(unaccounted)
        xorbit = orbit(σ,x)
        unaccounted[xorbit] .= false
        length(xorbit) > 1 && push!(decomp,xorbit)
    end
    return decomp
end

# ╔═╡ b2ac585a-d84a-4d19-afe5-ad6d288e847f
md"""
I then need to consider how to build up the string from this decomposition
- Each cycle from the decomposition will be expressed as an open parenthesis, followed by the list of integers in order, separated by spaces, and then closed with another parenthesis. To do this, I list out strings that I can then concatenate with `*`.
```julia
*( "( ", ["$y " for y ∈ x]... , ")" )
```

- This needs to be repeated for all of the cycles in the decomposition, with an additional empty string added in case the disjoint cycle decomposition is empty.
```julia
toprint = *([ *( "( ", ["$y " for y ∈ x]... , ")" ) for x ∈ dcd(σ)]..., "")
```

- Finally, if (and only if) the permutation is the identity permutation, then the string will be empty at this point. Instead, I want to use the symbol `ι`.
```julia
toprint == "" && (toprint = "ι")
```

In order to write my new method for `show`, I first need to `import` it, ensuring that I do not overwrite the inbuilt methods that it has. Then, I construct my function, mirroring the syntax used for `show` in the source code as it is good practice.
"""

# ╔═╡ 7a96d2c8-aa9c-405f-b34f-1f3c7c53b6c6
begin
	import Base.show
	
	function show(io::IO,σ::Permutation)
	    toprint = *([ *( "( ", ["$y " for y ∈ x]... , ")" ) for x ∈ dcd(σ)]..., "")
    	toprint == "" && (toprint = "ι")
	    print(io, toprint)
	end
end

# ╔═╡ 12346644-107b-4c43-aaca-3e404fecc8b3
md"""
Permutations now have a much more aesthetic and useful display style:
"""

# ╔═╡ 0afa030a-58ad-44f6-a10f-0ae3baabe6f8
σ

# ╔═╡ 1e8659dc-27d5-429d-8431-d5cfa9006411
md"""
### Adding `Permutation` arithmetic
I now want to add some arithmetic for combining `Permutation` objects, starting with a shortcut for the identity. This will be represented by the constant `ι` (mirroring the way it is displayed by `show`), and is given by:
"""

# ╔═╡ 068a9d15-ce46-4aa5-9c13-3f79e70b0eda
const ι = Permutation(1)

# ╔═╡ b3151f52-6dd7-4f63-a158-becb5d1aec2e
md"""
Then, I add two methods to the inbuilt function one allowing it to be obtained either by passing a permutation, or the `Permutation` type. For these functions, the input variables are not given names, only their types specified, since the type is the only relevant property about the input, as needed for multiple dispatch.
"""

# ╔═╡ d614739d-b22f-4991-9722-e8371732bf4b
begin
	import Base.one
	one(::Permutation) = ι
	one(::Type{Permutation}) = ι
end

# ╔═╡ 363481da-d185-4846-82ab-c227e9f668f8
md"""
Next, I want to be able to compose permutations, for which I will write new `Permutation`-specific methods for the inbuilt operator `∘`. In order for an arbitrary number of permutations to be composable, I use an inductive definition which mirrors the definition of composition of functions [from the Julia source code](https://github.com/JuliaLang/julia/blob/master/base/operators.jl#L1096), that is:
```julia
∘(f) = f
∘(f, g) = ComposedFunction(f, g)
∘(f, g, h...) = ∘(f ∘ g, h...)
```

Hence, my methods for `∘` are:
"""

# ╔═╡ 8f925ec6-7cd8-49fe-a467-807711b3425b
begin
	import Base.∘
	∘(σ::Permutation) = σ
	∘(σ::Permutation, τ::Permutation) =
        Permutation([σ(τ(x)) for x ∈ 1:max(maxarg(σ),maxarg(τ))])
	∘(σ::Permutation, τ::Permutation, υ::Permutation...) = ∘(σ ∘ τ, υ...)
end

# ╔═╡ 4552e49c-af66-4fd3-a827-28284215f4f9
md"""
Thirdly, I want an inverse function to be able to find the inverse of a permutation. To do this, I need to find the index of each of `1:maxarg(σ)` in the image vector and let that be the image of the new permutation, which is done by:
"""

# ╔═╡ 0e710b07-b5db-4ea7-986b-8eb7fc0946b1
begin
	import Base.inv
	inv(σ::Permutation) = Permutation([findfirst(σ.image .== x) for x ∈ 1:maxarg(σ)])
end

# ╔═╡ 7c082457-980c-4961-bb10-d91b7248d0f6
md"""
Finally, I want to be able to exponentiate by any integer (including zero and negative integers), which can be done using some logic combined with the three operations above:
"""

# ╔═╡ 59075aa4-dd35-47af-b4d1-40e89b2e599f
begin
	import Base.^

	function ^(σ::Permutation,n::Int64)
	    n == 0 && return one(Permutation)
	    n < 0 && ((n,σ) = (-n,inv(σ)))
	    return ∘(fill(σ,n)...)
	end
end

# ╔═╡ 764fb693-f4ac-4327-93a3-2171621ad039
md"""
I can now test these out:
"""

# ╔═╡ 75e5491a-6536-44b0-a5b9-10cf7f9e5c66
ι

# ╔═╡ 9d43f21c-c60a-4bf8-b1a0-bf3b56b3a97b
σ

# ╔═╡ b421f174-d554-47a8-a72d-4d5f3ec6ba2e
τ = Permutation(4,5,2,3,1)

# ╔═╡ ff82e088-aa60-49fe-bb12-fe39b0430d51
σ ∘ τ

# ╔═╡ 7c0c4e99-ebff-409b-87f3-919a6870cccc
σ^-1

# ╔═╡ 029a0c9f-5d32-409d-b6ad-9e0d4e19e854
τ^5

# ╔═╡ c75f7100-778e-44c6-9d43-675d11175673
md"""
## Generating groups with `Permutation` objects

### Constructing symmetric and alternating groups
The first groups that I would like to be able to list the elements of are symmetric or alternating groups. Before this however, I will define two more functions which will be useful to me in their construction.

First, I would like a way to quickly construct a transposition:
"""

# ╔═╡ 0598e94b-a043-4106-bb7b-d032eb67be0b
function transposition(m::Int64, n::Int64)
    image = collect(1:max(m,n))
    image[m], image[n] = n, m
    return Permutation(image)
end

# ╔═╡ 00a61c28-230d-41b0-81ac-e2f0869d6640
transposition(3,4)

# ╔═╡ 32b52a58-6086-4c2f-a833-e1a7efb69d29
transposition(3,3)

# ╔═╡ 84bd5d92-00eb-4e66-a1c5-c86626b8f7d2
md"""
Note that `transposition(m,m)` returns the identity, which turns out to be exactly what I want.

To find the alternating group, I will need to consider the parity of elements. The easiest way to find the parity of a permutation is to consider it as a product of cycles and consider their parities. I already have such a decomposition, given by `dcd`, so using the `iseven` function, and `sum` to count the number of `true` elements of an array, I can write such a function:
"""

# ╔═╡ 1b10a694-a310-4a4e-9831-654e3e9691d1
parity(σ::Permutation) = (-1)^sum([iseven(length(x)) for x ∈ dcd(σ)])

# ╔═╡ 9812e6fb-9308-4c27-9d57-9fbf71474343
parity(ι)

# ╔═╡ d69ce761-f489-4728-a19d-783b84b436a5
parity(σ)

# ╔═╡ a6be1358-652d-4084-9c8e-f3089fb99169
parity(τ)

# ╔═╡ 41cf3bc2-c70c-4053-bed0-74a11f8a5ad5
md"""
Now, I have all the tools to create the `n`th symmetric group as a vector of `Permutation` objects, which I will do recursively using the inductive formula:
```math
S_1 = \{ \iota \}, \qquad S_n = \{ \sigma \circ (m n) : \sigma \in S_{n-1}, m \in \{ 1, 2, \dots, n \} \}
```
where as in the `transposition` function above, ``(n n) = \iota``.

- First, I will check that `n` is positive to avoid non-terminating loops (and also because the group doesn’t make sense otherwise)
```julia
n ≥ 1 || error("symmetric group must have a positive parameter")
```

- Then, I implement the base case of the trivial group when `n == 1`:
```julia
n == 1 && return [ι]
```

- For the recursive step, I copy `symmetricgroup(n-1)` into a vector `n` times, and then set up the corresponding vector of transpositions that I will multiply each by, using array filling and concatenation. Then, I compose the two elementwise:
```julia
permutations = vcat(fill(symmetricgroup(n-1),n)...)
transpositions = vcat([fill(transposition(i,n),factorial(n-1)) for i ∈ 1:n]...)
return permutations .∘ transpositions
```

The entire function is:
"""

# ╔═╡ c70a297d-adb7-4f70-b6bb-949a3d49d3c0
function symmetricgroup(n::Int64)
    n ≥ 1 || error("symmetric group must have a positive parameter")
    n == 1 && return [ι]

    permutations = vcat(fill(symmetricgroup(n-1),n)...)
    transpositions = vcat([fill(transposition(i,n),factorial(n-1)) for i ∈ 1:n]...)
    return permutations .∘ transpositions
end

# ╔═╡ eb5640fa-0814-497c-b157-da718df1c129
md"""
Now, finding the `n`th alternating group is as simple as finding the `n`th symmetric group and taking the even permutations:
"""

# ╔═╡ d546b70a-eeaa-45db-8b65-d36cb13b67f6
function alternatinggroup(n::Int64)
    Sₙ = symmetricgroup(n)
    return Sₙ[parity.(Sₙ) .== 1]
end

# ╔═╡ 5dea6f25-65fe-4304-a7e7-2d4b830f4724
symmetricgroup(5)

# ╔═╡ 13cacc56-7fcc-4a71-9cc5-be298295939b
alternatinggroup(5)

# ╔═╡ 46eeeed1-a8e4-49cc-8d97-6ddfb1fa2b1e
md"""
### Generating arbitrary finite groups
Instead of just symmetric and alternating groups, I would like to be able to generate a group given a list of `Permutation` objects as generators. By Cayley's theorem, this suffices to construct any finite group, assuming that you can find an appropriate list of generators. This will require one final use of multiple dispatch, which will be for me to define equality of permutations:
```julia
import Base.:(==)
==(σ::Permutation, τ::Permutation) = (σ.image == τ.image)
```

This snippet of code is included in the block with the definition of the `Permutation` type at the end of the section [Declaring `Permutation` as a new type](#73d93917-b72e-468b-970c-f34ec6d51de4), since otherwise the import of `==` here conflicts with its use in the definition of `Permutation` in the Pluto notebook format.

I can now write a function to generate a group from a list of generators. This I will do by repeatedly checking closure under multiplication, which is not a particularly clever or efficient algorithm, but it will work which is all I am looking for in this case.
"""

# ╔═╡ 3e8b7d82-1d63-4aec-8ed6-0b1f11c5cb33
function generate(σs::Permutation...)
    G = [σs...]
    while true
        newelements = Permutation[]

        for σ ∈ G, τ ∈ G
            υ = σ ∘ τ
            υ ∉ G && υ ∉ newelements && push!(newelements, υ)
        end

        if isempty(newelements)
            return G
        else
            G = vcat(G,newelements)
        end
    end
end

# ╔═╡ 79584487-dd19-4014-97e7-7fcc0582efa8
md"""
An interesting point of note here is that nowhere in the function do I use the syntax `==`, and yet the function would not work without it. This demonstrates further the power of multiple dispatch, since the operator `∉` uses `==` to determine whether or not `υ` is an element of `G` (or `newelements`), and I have defined what `==` means for a `Permutation`, so `∉` will automatically work for permutations without me explicitly telling it how to.

Some demonstrations of the `generate` function are shown below, with `C₅`, `D₁₀`, and `G` the group generated by `σ` and `τ`, which happens to be `S₅`:
"""

# ╔═╡ 4725c3bb-a1c1-49cc-9bf7-a7e443db085c
C₅ = generate(Permutation(2,3,4,5,1))

# ╔═╡ 9e84f004-fd88-4a25-bfba-0797d2df0942
D₁₀ = generate(Permutation(2,3,4,5,1),Permutation(5,4,3,2,1))

# ╔═╡ bd677d6a-3b42-497d-bcfb-58543dee7ebd
G = generate(σ,τ)

# ╔═╡ 076885f1-61b4-4913-8530-fd65c531f419
S₅ = symmetricgroup(5)

# ╔═╡ 738df784-eeb7-4d3b-b19f-6317f2459c6d
all([g ∈ G for g ∈ S₅]) && all([g ∈ S₅ for g ∈ G])

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PlutoUI = "~0.7.9"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "477bf42b4d1496b454c10cce46645bb5b8a0cf2c"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.0.2"

[[PlutoUI]]
deps = ["Base64", "Dates", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "Suppressor"]
git-tree-sha1 = "44e225d5837e2a2345e69a1d1e01ac2443ff9fcb"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.9"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Reexport]]
git-tree-sha1 = "5f6c21241f0f655da3952fd60aa18477cf96c220"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.1.0"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[Suppressor]]
git-tree-sha1 = "a819d77f31f83e5792a76081eee1ea6342ab8787"
uuid = "fd094767-a336-5f1f-9728-57cf17d0bbfb"
version = "0.2.0"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
"""

# ╔═╡ Cell order:
# ╟─08eadc12-f8e9-11eb-1094-b7adc6936aa1
# ╟─c4d2ff29-2579-4079-a6cb-29015ef5ecd2
# ╟─db919e43-6dc8-4e53-8081-d9312446117a
# ╠═524dee4b-6687-44de-af79-b99d3724f9ac
# ╠═a16202d3-406a-4b43-807e-b60c673d4132
# ╟─41fc4769-5b67-4503-b1d1-2854a0d9c3a2
# ╠═1d56249e-d86a-4d1e-b7d2-6d63a621bfa8
# ╠═acf690f4-b65b-4576-9145-1e894d5342f2
# ╠═9ab255ff-b40a-4f16-bed8-fe14e4495502
# ╠═98750bd0-84bd-4cb1-900b-9ee26142e4ec
# ╟─9f193c51-b6ea-477f-ab0e-1bc5a4be4b86
# ╠═29b729bb-cd1a-4ee1-ae2e-26b55ce744a4
# ╠═4e4508db-47c0-462f-9cec-93e52bbffd7c
# ╟─740f8275-ee0c-4aa2-b0c1-76d46fad3ecd
# ╟─73d93917-b72e-468b-970c-f34ec6d51de4
# ╟─c18ae801-b186-44cf-9e42-83188c4781aa
# ╟─99fe42de-2afa-409f-9416-5c7671e4d0f4
# ╠═b9c535e5-3317-4291-9925-696bc6cb0252
# ╠═de16f61d-853a-43ed-adf0-fb77ea3c8f4a
# ╟─322f2dbc-f8f4-4f62-a9bb-ea6b00a333ae
# ╠═ff8ab6b4-34de-44eb-b98a-2f5e0f1c48fc
# ╠═5ce89616-326b-4404-9f2f-707c91835fa3
# ╟─9617f0f2-1b45-418f-8818-26df1abde6cb
# ╠═ee9d45f3-0a25-47f6-8445-8ba733c3a8f6
# ╟─b119e9f0-b8ba-42a3-a76c-82ed2dc170a4
# ╠═e4ce9583-5c18-4df7-a5fb-a46670fe40af
# ╟─b2ac585a-d84a-4d19-afe5-ad6d288e847f
# ╠═7a96d2c8-aa9c-405f-b34f-1f3c7c53b6c6
# ╟─12346644-107b-4c43-aaca-3e404fecc8b3
# ╠═0afa030a-58ad-44f6-a10f-0ae3baabe6f8
# ╟─1e8659dc-27d5-429d-8431-d5cfa9006411
# ╠═068a9d15-ce46-4aa5-9c13-3f79e70b0eda
# ╟─b3151f52-6dd7-4f63-a158-becb5d1aec2e
# ╠═d614739d-b22f-4991-9722-e8371732bf4b
# ╟─363481da-d185-4846-82ab-c227e9f668f8
# ╠═8f925ec6-7cd8-49fe-a467-807711b3425b
# ╟─4552e49c-af66-4fd3-a827-28284215f4f9
# ╠═0e710b07-b5db-4ea7-986b-8eb7fc0946b1
# ╟─7c082457-980c-4961-bb10-d91b7248d0f6
# ╠═59075aa4-dd35-47af-b4d1-40e89b2e599f
# ╟─764fb693-f4ac-4327-93a3-2171621ad039
# ╠═75e5491a-6536-44b0-a5b9-10cf7f9e5c66
# ╠═9d43f21c-c60a-4bf8-b1a0-bf3b56b3a97b
# ╠═b421f174-d554-47a8-a72d-4d5f3ec6ba2e
# ╠═ff82e088-aa60-49fe-bb12-fe39b0430d51
# ╠═7c0c4e99-ebff-409b-87f3-919a6870cccc
# ╠═029a0c9f-5d32-409d-b6ad-9e0d4e19e854
# ╟─c75f7100-778e-44c6-9d43-675d11175673
# ╠═0598e94b-a043-4106-bb7b-d032eb67be0b
# ╠═00a61c28-230d-41b0-81ac-e2f0869d6640
# ╠═32b52a58-6086-4c2f-a833-e1a7efb69d29
# ╟─84bd5d92-00eb-4e66-a1c5-c86626b8f7d2
# ╠═1b10a694-a310-4a4e-9831-654e3e9691d1
# ╠═9812e6fb-9308-4c27-9d57-9fbf71474343
# ╠═d69ce761-f489-4728-a19d-783b84b436a5
# ╠═a6be1358-652d-4084-9c8e-f3089fb99169
# ╟─41cf3bc2-c70c-4053-bed0-74a11f8a5ad5
# ╠═c70a297d-adb7-4f70-b6bb-949a3d49d3c0
# ╟─eb5640fa-0814-497c-b157-da718df1c129
# ╠═d546b70a-eeaa-45db-8b65-d36cb13b67f6
# ╠═5dea6f25-65fe-4304-a7e7-2d4b830f4724
# ╠═13cacc56-7fcc-4a71-9cc5-be298295939b
# ╟─46eeeed1-a8e4-49cc-8d97-6ddfb1fa2b1e
# ╠═3e8b7d82-1d63-4aec-8ed6-0b1f11c5cb33
# ╟─79584487-dd19-4014-97e7-7fcc0582efa8
# ╠═4725c3bb-a1c1-49cc-9bf7-a7e443db085c
# ╠═9e84f004-fd88-4a25-bfba-0797d2df0942
# ╠═bd677d6a-3b42-497d-bcfb-58543dee7ebd
# ╠═076885f1-61b4-4913-8530-fd65c531f419
# ╠═738df784-eeb7-4d3b-b19f-6317f2459c6d
# ╟─f1d0ed8f-bfd3-4210-84fd-f189bba6ebf9
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
