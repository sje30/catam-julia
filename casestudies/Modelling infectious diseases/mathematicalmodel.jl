#=  https://www.damtp.cam.ac.uk/research/dd/files/teaching/MB17Gog.pdf#subsubsection.1.3.4  =#
using Plots

δt = 0.001
T = 1
times = 0:δt:T
ntimes = length(times)

N = 10000
I₀ = 1

S = zeros(size(times))
S[1] = N - I₀
I = zeros(size(times))
I[1] = I₀
R = zeros(size(times))

# Rate of infection
β = 0.005
# Rate of recovery
ν = 4

# Randomness for σ > 0
σ = 1

for i ∈ 2:ntimes
    δS = - β * I[i-1] * S[i-1] * δt
	δR = ν * I[i-1] * δt
	δI = - δS - δR
    S[i] = max(S[i-1] + δS * exp(σ * randn()), 0)
    I[i] = max(I[i-1] + δI * exp(σ * randn()), 0)
	R[i] = max(R[i-1] + δR * exp(σ * randn()), 0)
	scale = (S[i] + I[i] + R[i])/N
	S[i] /= scale; I[i] /= scale; R[i] /= scale
end

lineplot = plot(times, [S I R], label = ["Susceptible" "Infectious" "Recovered"], color = [:gold :red :blue]);
areaplot_ = areaplot(times, [S I R], label = ["Susceptible" "Infectious" "Recovered"], color = [:gold :red :blue]);

display(lineplot)
display(areaplot_)