# These are the functions that need to be imported so that new methods do not overwrite old ones
import Base.show
import Base.one
import Base.∘
import Base.inv
import Base.^

"""
    Permutation(image::Vector{Int64})
    Permutation(xs...::Int64)

A function ℕ → ℕ which fixes all but finitely many points.

Construct a `Permutation` from a vector of integers as the image of the integers `1:length(image)`.

Alternatively, construct from an arbitrary list of integers.

# Examples
```julia-repl
julia> Permutation([1,5,3,2,4])
( 2 4 5 )

julia> Permutation(4,5,2,3,1)
( 1 5 2 3 4 )
```
"""
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

Permutation(imagevals::Int64...) = Permutation([x for x ∈ imagevals])

"""
    maxarg(σ::Permutation)

Find the largest integer which the `Permutation` `σ` does not fix.

For the identity `Permutation`, return `1`.

# Examples
```julia-repl
julia> maxarg(Permutation(1,3,2,4))
3

julia> maxarg(ι)
1
```
"""
maxarg(σ::Permutation) = length(σ.image)

"""
    (σ::Permutation)(x::Int64)

Evaluate the action of the `Permutation` `σ` on `x`.

# Examples
julia> σ = Permutation(4,5,2,1,3)
( 1 4 )( 2 5 3 )

julia> σ(5)
3
"""
(σ::Permutation)(x::Int64) = x ∈ 1:maxarg(σ) ? σ.image[x] : x

"""
    orbit(σ::Permutation,x::Int64)

Compute the orbit of `x` under the repeated action of the `Permutation` `σ`.

# Examples
```julia-repl
julia> orbit(Permutation(2,3,4,5,1),3)
5-element Vector{Int64}:
 3
 4
 5
 1
 2
```
"""
function orbit(σ::Permutation, x::Int64)
    orb = [x]
    y = σ(x)
    while y != x
        push!(orb,y)
        y = σ(y)
    end
    return orb
end

"""
    dcd(σ::Permutation)

Compute the disjoint cycle decomposition of the `Permutation` `σ`.

If an integer is fixed by `σ`, then it is not included in the decomposition.

# Examples
```julia-repl
julia> dcd(Permutation(4,3,5,1,2))
2-element Vector{Vector{Int64}}:
 [1, 4]
 [2, 3, 5]

julia> dcd(Permutation(1,3,2))
1-element Vector{Vector{Int64}}:
 [2, 3]
```
"""
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

function show(io::IO,σ::Permutation)
    toprint = *([ *( "( ", ["$y " for y ∈ x]... , ")" ) for x ∈ dcd(σ)]..., "")
    toprint == "" && (toprint = "ι")
    print(io, toprint)
end

"""
    ι

The identity `Permutation`.

# Examples
```julia-repl
julia> ι.(1:10) == 1:10
true
```
"""
const ι = Permutation(1)
one(::Permutation) = ι
one(::Type{Permutation}) = ι

"""
    ∘(σ::Permutation)
    ∘(σ::Permutation, τ::Permutation)
    ∘(σs...::Permutation)

Compose `Permutation`s.

Compose a single `Permutation` and recieve it back.

# Examples
```julia-repl
julia> ∘(Permutation(1,2,4,3))
( 3 4 )

julia> Permutation(5,2,3,1,4) ∘ Permutation(2,1,4,5,3)
( 1 2 5 3 )
```
"""
∘(σ::Permutation) = σ
∘(σ::Permutation, τ::Permutation) = Permutation([σ(τ(x)) for x ∈ 1:max(maxarg(σ),maxarg(τ))])
∘(σ::Permutation, τ::Permutation, υ::Permutation...) = ∘(σ ∘ τ, υ...)

inv(σ::Permutation) = Permutation([findfirst(σ.image .== x) for x ∈ 1:maxarg(σ)])

"""
    ^(σ::Permutation,n::Int)

Exponentiate a `Permutation` `σ` by an integer `n`.

If `n` is negative, compute the inverse and exponentiate by `-n`.
```julia-repl
julia> Permutation(5,4,2,3,1)^5
( 1 5 )( 2 3 4 )

julia> Permutation(5,4,2,3,1)^-5
( 1 5 )( 2 4 3 )
```
"""
function ^(σ::Permutation,n::Int64)
    n == 0 && return one(Permutation)
    n < 0 && ((n,σ) = (-n,inv(σ)))
    return ∘(fill(σ,n)...)
end

"""
    transposition(m::Int64,n::Int64)

Create the `Permutation` which is a transposition of `m` and `n`.

If `m == n`, the `Permutation` created is the identity.

# Examples
```julia-repl
julia> transposition(4,5)
( 4 5 )

julia> transposition(6,6)
ι
```
"""
function transposition(m::Int64, n::Int64)
    image = collect(1:max(m,n))
    image[m], image[n] = n, m
    return Permutation(image)
end

"""
    symmetricgroup(n::Int64)

Compute the `Permutation`s which make up the symmetric group of order `factorial(n)`.

# Examples
```julia-repl
julia> symmetricgroup(5)
120-element Vector{Permutation}:
[...]
```
"""
function symmetricgroup(n::Int64)
    n ≥ 1 || error("symmetric group must have a positive parameter")
    n == 1 && return [ι]

    permutations = vcat(fill(symmetricgroup(n-1),n)...)
    transpositions = vcat([fill(transposition(i,n),factorial(n-1)) for i ∈ 1:n]...)
    return permutations .∘ transpositions
end

"""
    parity(σ::Permutation)

Compute the parity of the `Permutation` `σ`.

# Examples
```julia-repl
julia> parity(Permutation(1,2,3,5,4))
-1

julia> parity(ι)
1
```
"""
parity(σ::Permutation) = (-1)^sum([iseven(length(x)) for x ∈ dcd(σ)])

"""
    alternatinggroup(n::Int64)

Compute the `Permutation`s which make up the `n`th alternating group.

# Examples
```julia-repl
julia> alternatinggroup(5)
60-element Vector{Permutation}:
[...]
```
"""
function alternatinggroup(n::Int64)
    Sₙ = symmetricgroup(n)
    return Sₙ[parity.(Sₙ) .== 1]
end