
from LUdecomp import *
from Lsolve import *
from Usolve import *

#we write a function that solves Ax = b for x by LU decomposition
def Asolve(A, b):
	L, U = LUdecomp(A)
	y = Lsolve(L, b)
	x = Usolve(U, y)
	return x
