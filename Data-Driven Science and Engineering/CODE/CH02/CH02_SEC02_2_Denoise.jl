
using Distributions
using FFTW
using Plots

# Create a simple signal with two frequencies
dt = 0.001
t = 0:dt:1
n = length(t)

f = sin.(50*2pi*t) + sin.(120*2pi*t) # Sum of 2 frequencies
f += 2.5*rand(Normal(), n) # Add some noise

# Compute the Fast Fourier Transform FFT
fhat = fft(f) # Compute the fast Fourier transform
PSD = abs2.(fhat)/n # Power spectrum (power per freq)
freq = 1/(dt*n)*(0:n) # Create x-axis of frequencies in Hz

# Use the PSD to filter out noise
indices = PSD .> 100 # Find all freqs with large power
PSDclean = PSD.*indices # Zero out all others
fhat = indices.*fhat # Zero out small Fourier coeffs. in Y
ffilt = real.(ifft(fhat)) # Inverse FFT for filtered time signal

# PLOTS
p1 = plot(t, f)
plot!(t, ffilt)

L = 1:Int(floor(n/2)) # Only plot the first half of freqs
p2 = plot(freq[L], PSD[L])
plot!(freq[L], PSDclean[L])