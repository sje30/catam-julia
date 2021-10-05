
using LinearAlgebra
using DataFrames
using CSV
using Plots

A = CSV.File("../../DATA/hald_ingredients.csv", header = false) |> Tables.matrix
b = CSV.File("../../DATA/hald_heat.csv", header = false) |> Tables.matrix

U, S, V = svd(A)
x = (V*inv(diagm(S))*U'*b) # Solve Ax=b using the SVD

p1 = plot(b, label = "Heat data") # Plot data
plot!(A*x, label = "Regression") # Plot regression
