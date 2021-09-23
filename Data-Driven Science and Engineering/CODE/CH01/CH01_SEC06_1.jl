
using Images
using ImageView
using MAT

vars = matread("../../DATA/allFaces.mat")

n = Int(vars["n"])
m = Int(vars["m"])
faces = vars["faces"]
nfaces = Int.(vars["nfaces"])

allPersons = zeros(n*6, m*6)

count = 1
for i = 1:6
    for j = 1:6
        allPersons[1+(i-1)*n:i*n, 1+(j-1)*m:j*m] = reshape(faces[:,1+sum(nfaces[1:count-1])], n, m)
        global count += 1
    end
end
imshow(allPersons)

for person = 1:length(nfaces)
    subset = faces[:, 1+sum(nfaces[1:person-1]):sum(nfaces[1:person])]
    allFaces = zeros(n*8, m*8);
    
    global count = 1
    for i = 1:8
        for j = 1:8
            if (count <= nfaces[person])
                allFaces[1+(i-1)*n:i*n, 1+(j-1)*m:j*m] = reshape(subset[:,count], n, m)
                global count += 1
            end
        end
    end
    imshow(allFaces)
end