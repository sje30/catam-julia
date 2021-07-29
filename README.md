# CATAM material in Julia

This is the home page for creating the Julia materials for Mathematics
students at the University of Cambridge.  As part of the degree,
students are encouraged to work on projects in
[CATAM](https://www.maths.cam.ac.uk/undergrad/catam/computer-aided-teaching-all-mathematics-catam):
Computer-Aided Teaching of All Mathematics.  Currently, MATLAB is used
by most students, although students are free to use whichever language
they wish.  The aim of this project is to provide material suitable
for mathematicians to learn the key concepts of the
[Julia](https://julialang.org) programming language.



# Draft material ready for commenting

1. [Introduction to Julia for CATAM](https://sje30.github.io/catam-julia/intro/julia-manual.html)
2. [Case study: permutations](https://sje30.github.io/catam-julia/casestudies/Permutations/Permutations.html)
3. [Case study: modelling infectious diseases](https://sje30.github.io/catam-julia/casestudies/Modelling%20infectious%20diseases/Modelling%20infectious%20diseases.html)

# Work in progress below


We hope to provide several documents, available as .jl (Pluto format)
with PDF/HTML.  Movies could be made too (but take a lot of time).

1. [Introduction to Julia for CATAM](intro/README.md) UNDERWAY
2. Conversion of [1A code](1a/README.md) UNDERWAY
3. Conversion of 1B Numerical analysis DODO
4. 1B model code for
   [root-finding](https://www.maths.cam.ac.uk/undergrad/catam/files/0pt1.pdf) UNDERWAY @jmb280cam
5. Case studies (see next section) to demonstrate different aspects of Julia

## Possible case studies

1. Logistic equation (for the introduction)
2. SIR model for disease spread
3. Four colour map theorem
4. Finding prime numbers
5. Matters of efficiency (Gokul mentions maths macros `@simd`, `@fastmath`, `@inbounds` and column-major arrays in particular)
6. Advantages of macros
7. Voronoi diagrams
8. Examples from John Hinch's new book on [fluid dynamics](https://www.cambridge.org/gb/academic/subjects/mathematics/fluid-dynamics-and-solid-mechanics/think-you-compute-prelude-computational-fluid-dynamics?format=PB)?  [code](https://www.damtp.cam.ac.uk/user/hinch/teaching/CMIFM_Handouts/)
9. Game of life
10. Automatic differentiation --> neural networks (gradient descent) [starting point](https://www.youtube.com/watch?v=vAp6nUMrKYg)
11. Something to read in large CSV data files/process/summarise / data analysis
12. Numerical optimisation?
13. Turing patterns -- following tutorial by [Miura and Maini](https://paperpile.com/app/p/56e34cfe-cb76-07bd-ae2d-49dd9faad3b9)
14. Mandlebrot/Julia fractals
15. Statistics of card shuffles
16. RSA/Diffie-Hellman Encryption
17. Different approaches to approximate pi or e (monte carlo, series, continued fractions, etc.)
18. Perlin noise generation
19. Enumeration of Polyominoes
20. Finite projective geometry
21. Julia's type system and multiple dispatch (see [Gokul's thoughts](https://github.com/sje30/catam-julia/issues/4))

# Acknowledgements

This project has been funded by Cambridge University Press.
