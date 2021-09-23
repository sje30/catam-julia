
using LinearAlgebra
using DataFrames
using CSV
using Plots

obs = CSV.File("../../DATA/ovariancancer_obs.csv", header = false) |> Tables.matrix
grp = CSV.File("../../DATA/ovariancancer_grp.csv", header = false) |> Tables.matrix

U, S, V = svd(obs)

p1 = plot(S, yaxis = :log, legend = false)
p2 = plot(cumsum(S)./sum(S), legend = false)

cancer = [[],[],[]]
normal = [[],[],[]]

for i = 1:size(obs)[1]
    x = V[:,1]'*obs[i,:]
    y = V[:,2]'*obs[i,:]
    z = V[:,3]'*obs[i,:]
    if (grp[i] == "Cancer")
        append!.(cancer, [x, y, z])
    else
        append!.(normal, [x, y, z])
    end
end

p3 = scatter(cancer..., mc = :red, label = "Cancer")
scatter!(normal..., mc = :blue, label = "Normal")