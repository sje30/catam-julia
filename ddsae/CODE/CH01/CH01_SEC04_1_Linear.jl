
using Plots
using LinearAlgebra

x = 3 # True slope
a = -2:.25:2
b = a*x + randn(length(a)) # Add noise

p1 = plot(a, x*a, label = "True line") # True relationship
scatter!(a, b, label = "Noisy data") # Noisy measurements

U, S, V = svd(reshape(collect(a), length(a), 1))
xtilde = (V*inv(diagm(S))*U'*b)[1] # Least-square fit

plot!(a, xtilde*a, label = "Regression line") # Plot fit