
n = 256
w = exp(-2im*pi/n)
DFT = zeros(Complex, n, n)

for i = 1:n
    for j = 1:n
        DFT[i,j] = w^((i-1)*(j-1))
    end
end

