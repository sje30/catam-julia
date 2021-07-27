
include("LUdecomp.jl")
include("Lsolve.jl")
include("Usolve.jl")

#we write a function that solves Ax = b for x by LU decomposition
function Asolve(A, b)
	L, U = LUdecomp(A)
	y = Lsolve(L, b)
	x = Usolve(U, y)
	return x
end
