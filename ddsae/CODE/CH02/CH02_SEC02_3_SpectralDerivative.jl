
using FFTW
using Plots

n = 128
L = 30
dx = L/n
t = -L/2:dx:L/2-dx
f(x) = cos(x)*exp(-x^2/25) #Function
df(x) = -sin(x)*exp(-x^2/25) - 2*x*f(x)/25 #Derivative

# Approximate derivative using finite Differences...
dfFD = zeros(n)
for k = 1:n-1
    dfFD[k] = (f(t[k+1])-f(t[k]))/dx
end
dfFD[n] = dfFD[n-1];

# Derivative using FFT (spectral derivative)
fhat = fft(f.(t))
kappa = (2pi/L)*(-n/2:n/2-1)
kappa = fftshift(kappa) # Re-order fft frequencies
dfhat = im*kappa.*fhat
dfFFT = real(ifft(dfhat))

# Plotting commands
plot(t, f)
plot!(t, df)
plot!(t, dfFD)
plot!(t, dfFFT)