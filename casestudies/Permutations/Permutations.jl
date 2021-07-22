# These are the functions that need to be imported so that new methods do not overwrite old ones
import Base.show
import Base.one
import Base.∘
import Base.inv
import Base.^

# I create a new type "Permutation", with a single field "image", a vector representing the values that σ sends each of
#   1, 2, ... to
struct Permutation
    image::Vector{Int64}
    # An inner constructor checks that the permutation is valid
    function Permutation(image::Vector{Int64})
        sortedimage = sort(image)
        m = maximum([image[image .!= 1:length(image)]..., 1])
        sortedimage == 1:last(sortedimage) && return new(image[1:m])
        error("not a valid permutation")
    end
end

# An outer constructor allows for easier construction of Permutation objects
Permutation(imagevals::Int64...) = Permutation([x for x ∈ imagevals])

# maxarg is a useful utitlity function which shortens the call for the length of the image
maxarg(σ::Permutation) = length(σ.image)

# I define what it means for a Permutation to be called as a function
(σ::Permutation)(x::Int64) = x ∈ 1:maxarg(σ) ? σ.image[x] : x

# The orbit of an integer under the action of a Permutation is needed for creating the disjoint cycle decomposition
function orbit(σ::Permutation, x::Int64)
    orb = [x]
    y = σ(x)
    while y != x
        push!(orb,y)
        y = σ(y)
    end
    return orb
end

# I can then calculate the disjoint cycle decomposition
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

# I create a new method for show to customise the displayed form of a Permutation for ease of interpretation
function show(io::IO,σ::Permutation)
    toprint = *([ *( "( ", ["$y " for y ∈ x]... , ")" ) for x ∈ dcd(σ)]..., "")
    toprint == "" && (toprint = "ι")
    print(io, toprint)
end

# I create the identity Permutation and overload the one function to output it
const ι = Permutation(1)
one(::Permutation) = ι
one(::Type{Permutation}) = ι

# Permutations can be combined by composition
∘(σ::Permutation) = σ
∘(σ::Permutation, τ::Permutation) = Permutation([σ(τ(x)) for x ∈ 1:max(maxarg(σ),maxarg(τ))])
∘(σ::Permutation, τ::Permutation, υ::Permutation...) = ∘(σ ∘ τ, υ...)

# Permutations can be inverted
inv(σ::Permutation) = Permutation([findfirst(σ.image .== x) for x ∈ 1:maxarg(σ)])

# Permutations can be exponentiated by any integer
function ^(σ::Permutation,n::Int64)
    n == 0 && return one(Permutation)
    n < 0 && ((n,σ) = (-n,inv(σ)))
    return ∘(fill(σ,n)...)
end

# Transpositions are particularly useful, so I create a shortcut to make them (note that transposition(n,n) == ι)
function transposition(m::Int64, n::Int64)
    image = collect(1:max(m,n))
    image[m], image[n] = n, m
    return Permutation(image)
end

# The symmetric group of order n! is built up recursively by multiplication with transpositions
function symmetricgroup(n::Int64)
    n ≥ 1 || error("symmetric group must have a positive parameter")
    n == 1 && return [ι]

    permutations = vcat(fill(symmetricgroup(n-1),n)...)
    transpositions = vcat([fill(transposition(i,n),factorial(n-1)) for i ∈ 1:n]...)
    return permutations .∘ transpositions
end

# The parity of a Permutation is found using the disjoint cycle decomposition
parity(σ::Permutation) = (-1)^sum([iseven(length(x)) for x ∈ dcd(σ)])

# I can find the alternating group from the symmetric group by checking the parity of the elements
function alternatinggroup(n::Int64)
    Sₙ = symmetricgroup(n)
    return Sₙ[parity.(Sₙ) .== 1]
end