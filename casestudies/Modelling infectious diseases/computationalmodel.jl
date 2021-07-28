using Plots

sqrtN = 100
N = sqrtN^2
population = fill(1, (sqrtN, sqrtN)) 
# 1 == susceptible, 2 == infectious, 3 == recovered

# I₀ = 1
population[rand(1:N)] = 2

# Probability of infected individual infecting susceptible neighbour
p = 0.4
# Probability of infected individual recovering
q = 0.01

anim = Animation()
function populationplot(population::Matrix{Int64})
    return heatmap(
        hcat(population, fill(missing, sqrtN), [1,2,3, fill(missing, sqrtN - 3)...]),
        legend = false,
        color = [:green, :red, :blue],
        size = (4*sqrtN,4*sqrtN),
        showaxis = false,
        ticks = false
    )
end
frame(anim, populationplot(population))

maxsteps = 500
S = zeros(maxsteps+1)
S[1] = N - 1
I = zeros(maxsteps+1)
I[1] = 1

for n ∈ 2:(maxsteps+1)
    reds = CartesianIndex{2}[]
    blues = CartesianIndex{2}[]
    for j ∈ 1:sqrtN, i ∈ 1:sqrtN
        if population[i,j] == 2
            i > 1     && population[i-1,j] == 1 && rand() < p && push!(reds,CartesianIndex(i-1,j))
            j > 1     && population[i,j-1] == 1 && rand() < p && push!(reds,CartesianIndex(i,j-1))
            i < sqrtN && population[i+1,j] == 1 && rand() < p && push!(reds,CartesianIndex(i+1,j))
            j < sqrtN && population[i,j+1] == 1 && rand() < p && push!(reds,CartesianIndex(i,j+1))
            rand() < q && push!(blues,CartesianIndex(i,j))
        end
    end

    population[reds]  .= 2
    population[blues] .= 3
    frame(anim, populationplot(population))

    nnewreds, nnewblues = (length ∘ unique! ∘ sort!)(reds), length(blues)
    S[n] = S[n-1] - nnewreds
    I[n] = I[n-1] + nnewreds - nnewblues
    # Disease dies out
    I[n] == 0 && break #(S = S[1:n]; I = I[1:n]; break)
end

R = N .- (S + I)

gif_ = gif(anim);
lineplot = plot(0:length(S)-1, [S I R], label = ["Susceptible" "Infectious" "Recovered"], color = [:green :red :blue]);
areaplot_ = areaplot(0:length(S)-1, [S I R], label = ["Susceptible" "Infectious" "Recovered"], color = [:green :red :blue]);

display(gif_)
display(lineplot)
display(areaplot_)