### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 58a85b40-e086-11eb-1471-a3d9d5596625
md"""
# Julia for CATAM

"""

# ╔═╡ 45aa5e5d-b518-4f28-ab45-365a9c3d4ee1
md"""
## Installing Julia

To use Julia, two elements are required: Julia itself, and an editor to allow you to write and run your programs.

Julia is a standalone program downloaded from <https://julialang.org/downloads/>
- For most Windows users, the version to download will be the 64-bit (installer). Once downloaded, run the installer, making sure to check the "Add Julia to PATH" box (which will allow the editor to find it)
- For Mac users there is no such paralysis of choice, the single Mac download link is the one you want
- For Linux users, you know what you're doing anyway
Additional platform specific information can be found at <https://julialang.org/downloads/platform/>

An editor is technically not essential, although it makes programming immeasuarably faster and easier. This manual will use the editor VSCode, which is developed by Microsoft but available on Mac and Linux as well as Windows. This is downloadable from <https://code.visualstudio.com/Download>

The third and final step is to open VSCode and install the Julia extension which allows it to recognise and run Julia code. This is found in the Extensions tab (accessible via **View** > **Extensions**, or `Ctrl` + `Shift` + `X`, or as the fifth symbol on the left sidebar). Search for Julia, and click Install. Once the extension has installed, restart VSCode, and it will be ready to use. Documentation for the extension is found at <https://www.julia-vscode.org/docs/dev/>, which provides (at the time of writing) limited information on using the extension.
"""

# ╔═╡ 6dab02d3-4b45-4227-a790-00350002a909
md"""
## Using Julia with VSCode

VSCode gives two ways to interact with Julia: the REPL and the editor

### The Julia REPL

The read-eval-print-loop (REPL) is the command line interface of Julia, akin to the MATLAB Command Window or the Python Shell. It allows single lines of code to be written and evaluated, and is also the place where any programs you write will run. It can be opened by the key sequence `Alt` + `J` followed by `Alt` + `O`, or by opening VSCode's command palette via the **View** menu or with `Ctrl` + `Shift` + `P`, and searching for the command **Julia: Start REPL**. It is identical to the command line which appears when running Julia as an application, so there is no need to interact with Julia outside of VSCode.

To test it, try copying the code in the boxes below, and see if the outputs match:
"""

# ╔═╡ 07d24863-82aa-4b13-aa92-1b06a0b5276b
a = 3;

# ╔═╡ c8366549-83b0-4a1c-b526-a4c38c1b1151
b = 2

# ╔═╡ 1c46f6c4-fba1-460d-91ff-a7f5e4506041
a + b

# ╔═╡ d3da52ff-1f54-4b15-bdb7-1c213154cc89
md"""
Note that without the semicolon, an output is displayed, which may or may not be desirable. Multiple lines can be written at once by seperation by semicolons, e.g
"""

# ╔═╡ 21f97b7f-7dd1-4f12-9812-081f08ed3f1f
c = a + 4; b * c

# ╔═╡ 6d3d80e1-c4e9-43eb-8750-48ce16a55e63
md"""
One particularly useful feature of the REPL is help mode. By typing `?` into the REPL. the prompt changes from **`julia>`** to **`help?>`**, after which typing the name of any variable or function tells you about it. Help mode can be exited by `Backspace` on an empty line, or `Ctrl` + `C` at any time. 

### The editor

The editor pane is the large central pane, which will allow the writing of programs in the form of scripts. To create a new file, select **File** and choose **New File** from the menu, or use `Ctrl` + `N`. Then, we need to tell VSCode that we are writing Julia, which can be done through the **Select a language** prompt, or by saving the file with the file type *.jl*.

Once a script has been written and saved, it can be run through the REPL by clicking the triangle in the top right and selecting **Julia: Execute File in REPL**. This does not have a keyboard shortcut automatically, but this (and any other keyboard shortcuts) can be changed through the command palette (`Ctrl` + `Shift` + `P`) by searching for the relevant command and clicking the cog that appears when you mouse over it.
"""

# ╔═╡ ffcdf202-a14d-417a-9a82-bf3e5ba38972
md"""
## Learning Julia

This manual doesn't focus on teaching Julia, purely because there are already plenty of freely available resources online to get you started
- A good place to start is the Julia Manual on Julia's official website, starting with <https://docs.julialang.org/en/v1/manual/getting-started/> and navigable through the left-hand menu
- For programmers already familiar with other languages, a useful page from the manual is <https://docs.julialang.org/en/v1/manual/noteworthy-differences/>, detailing how Julia differs from other languages, and <https://cheatsheets.quantecon.org/>, which gives explicit differences in syntax between Julia, Python, and MATLAB
- A short introductory guide is at <https://computationalthinking.mit.edu/Spring21/basic_syntax/>. This is an interactive Pluto notebook, with the ability to edit the snippets of code accessible by:
  - Run `using Pkg; Pkg.add("Pluto");` in the Julia REPL and wait for the package to be downloaded and installed
  - Now run `using Pluto; Pluto.run()`, which should open in your browser, or give an address of the form `localhost:1234/?secret=XXXXXXXX` for you to open
  - In the **Open from file:** textbox enter the URL of the notebook as linked above
- A quick cheatsheet for Julia syntax and its abilities is at <https://juliadocs.github.io/Julia-Cheat-Sheet/>
- A similar cheatsheet for the Plots package is at <https://github.com/sswatson/cheatsheets/blob/master/plotsjl-cheatsheet.pdf>
- YouTube (as usual) provides a plethora of videos of a wide range of qualities; simply searching for "Learn Julia" is a good start

However, there are some particular features worth highlighting:
"""

# ╔═╡ af2dd15c-cb27-483f-b047-69c70d9e7532
md"""
### Unicode support

Julia is unusual in supporting the use of characters usual Latin alphabet, Arabic numerals, and common English punctuation. For example:
- Instead of `pi` and `exp(1)`, we can use `π` and `ℯ`
- Where Greek letters are used by mathematical convention, they can be used in programs, such as `ρ` for density, or `λ` for the parameter of a Poisson distribution, improving comprehension
- Some symbols have syntactic meaning, such as using `≤` instead of `<=`, or `∈` instead of the keyword `in`
- Non-Latin writing systems are supported, allowing variable/function names as well as text within the program to be written in your (human) language of choice
- Emoji can be used similarly. Unfortunately, the author of this manual is too boring to appreciate this. `😒 = true`
These can be copied and pasted into your code, or directly typed if you have the capibilities, but the easiest way tends to be to use LaTeX-like shortcuts with tab-completion, such as `\alpha<tab>` for `α` or `\leq<tab>` for `≤`. The help mode of the REPL allows pasting of characters to see the relevant shortcuts available for typing them.
"""

# ╔═╡ 6cf95416-a4d0-442b-8dfa-5e59d07d4a15
md"""
### Mathematical notation uncommon in other languages

The usual syntax for defining functions is similar to many other programming languages
"""

# ╔═╡ 92715aab-25fe-4387-9fd9-45c7e632b50d
function f(x,y)
	return √(x^2 + y^2)
end

# ╔═╡ 4f540782-83d9-4401-8865-78bb39af2aae
md"""
However, an alternative syntax is particularly useful for readability of short functions, by writing them in the compact form:
"""

# ╔═╡ dd43c006-3455-49db-97bc-e928408a0539
g(x,y) = √(x^2 + y^2)

# ╔═╡ 26b5cc22-db0b-46f4-9d45-d3830223d336
md"""
This is convenient notation since it mirrors the mathematical equivalent. The expression after the equals must be a single line, but can also be extended to longer expressions by using a `begin`-`end` block, which allows multiple lines to be treated together as a single line:
"""

# ╔═╡ 59b2dc85-0ce7-4e99-aeae-170cc13cfe87
h(x) = begin
	if 0 < x < 3
		return x
	else
		return 0
	end
end

# ╔═╡ 74e50b24-39d8-49b4-b651-e4cbe07d382f
md"""
The function `h` above also demonstrates another ability of Julia, which is to allow multiple comparisons in the same statement. In many languages, `0 < x < 3` would be invalid syntax, and would have to be written as `0 < x && x < 3`.

A third feature of Julia that appeals to standard mathematical notation is function composition:
"""

# ╔═╡ 0c4f78f4-055b-47fd-8c64-8a77259a13c1
hg = h ∘ g

# ╔═╡ 7b097f93-d92e-4bac-8d41-3e309629ae3a
md"""
Here, `hg` isn't technically a function, but a `ComposedFunction`, although it acts in much the same way.

A fourth and final feature is the ability to use numeric coefficients to denote multiplication. Consider the following:
"""

# ╔═╡ a671de2a-de76-4728-bf7b-f751c284aace
d = 2; e = 2d

# ╔═╡ 1b859eb6-525f-4405-b4fc-181ff335532b
md"""
In most other programming languages, this would cause an error, as the implicit multiplication wouldn't be recognised. Julia, however, knows that prefixing a variable name with a number means multiplication, so treats it as such.

This only works with numeric literals, i.e. actual numbers, not variables which take a number as a value. For example, trying to multiply `d` and `e` like this results in:
"""

# ╔═╡ c33eeb03-07d8-4f16-8691-568bc830e468
de

# ╔═╡ 7e80b6cc-d4b6-45c7-a14f-76e0f67a6053
md"""
because Julia interprets this as the variable with name `de`, not `d` multiplied by `e`.
"""

# ╔═╡ 2fe58313-a17a-4af0-b68f-8bdefd0a035d
md"""
### Short-circuiting and the ternary operator

The `if`-statement is perhaps one of the most used in programming, since it allows the program to respond differently depending on different conditions. Therefore, since it is so ubiquitous, it can be useful to have some abbreviations for it.

Usually, the **AND** (`&&`) and **OR** (`||`) operators are used for combining logical statements. An optimisation which allows more efficient code is *short-circuiting*:
- Consider the statement `<statement-1> && <statement-2>`. If `<statement-1>` is `false`, then there is no need to evaluate `<statement-2>`, since the overall result will always be `false`, so Julia *short-circuits* by ignoring it and simply returning `false`
- Simiarly, in the case `<statement-1> || <statement-2>` with `<statement-1>` true, the overall expression will be `true` without checking `<statement-2>`
A useful way of using this is to have `<statement-2>` not be a logical statement at all, and instead be a piece of code. This will then only run if no short-circuit is made, abbreviating:
```
if <statement-1>
	<statement-2>			=>			<statement-1> && <statement-2>
end
```
and
```
if !<statement-1>
	<statement-2>			=>			<statement-1> || <statement-2>
end
```
For example:
"""

# ╔═╡ 0d6f6cf0-4706-4469-bd4b-ca65af27ffe6
3 > 4 && "Secret message"

# ╔═╡ 3ac36546-1ddd-479d-86c5-d02e07993069
3 < 4 && "Secret message"

# ╔═╡ 89b0c356-3962-4201-abb6-caeb334fce6a
md"""
Another common use for an `if`-statement is to assign a variable one of two values, depending on whether a condition is met or not. This can be done by the ternary operator, which provides the following abbreviation
```
if <condition>
	x = <value-if>
else 						=>		x = (<condition> ? <value-if> : <value-else>)
	x = <value-else>
end
```
which can be seen in the following example:
"""

# ╔═╡ c5193537-9e52-4391-b352-3aaf640192c4
3 > 4 ? "This is true" : "This is false"

# ╔═╡ db2c9293-1c23-4708-b1a9-5ed013d1f8f4
3 < 4 ? "This is true" : "This is false"

# ╔═╡ Cell order:
# ╟─58a85b40-e086-11eb-1471-a3d9d5596625
# ╟─45aa5e5d-b518-4f28-ab45-365a9c3d4ee1
# ╟─6dab02d3-4b45-4227-a790-00350002a909
# ╠═07d24863-82aa-4b13-aa92-1b06a0b5276b
# ╠═c8366549-83b0-4a1c-b526-a4c38c1b1151
# ╠═1c46f6c4-fba1-460d-91ff-a7f5e4506041
# ╟─d3da52ff-1f54-4b15-bdb7-1c213154cc89
# ╠═21f97b7f-7dd1-4f12-9812-081f08ed3f1f
# ╟─6d3d80e1-c4e9-43eb-8750-48ce16a55e63
# ╟─ffcdf202-a14d-417a-9a82-bf3e5ba38972
# ╟─af2dd15c-cb27-483f-b047-69c70d9e7532
# ╟─6cf95416-a4d0-442b-8dfa-5e59d07d4a15
# ╠═92715aab-25fe-4387-9fd9-45c7e632b50d
# ╟─4f540782-83d9-4401-8865-78bb39af2aae
# ╠═dd43c006-3455-49db-97bc-e928408a0539
# ╟─26b5cc22-db0b-46f4-9d45-d3830223d336
# ╠═59b2dc85-0ce7-4e99-aeae-170cc13cfe87
# ╟─74e50b24-39d8-49b4-b651-e4cbe07d382f
# ╠═0c4f78f4-055b-47fd-8c64-8a77259a13c1
# ╟─7b097f93-d92e-4bac-8d41-3e309629ae3a
# ╠═a671de2a-de76-4728-bf7b-f751c284aace
# ╟─1b859eb6-525f-4405-b4fc-181ff335532b
# ╠═c33eeb03-07d8-4f16-8691-568bc830e468
# ╟─7e80b6cc-d4b6-45c7-a14f-76e0f67a6053
# ╟─2fe58313-a17a-4af0-b68f-8bdefd0a035d
# ╠═0d6f6cf0-4706-4469-bd4b-ca65af27ffe6
# ╠═3ac36546-1ddd-479d-86c5-d02e07993069
# ╟─89b0c356-3962-4201-abb6-caeb334fce6a
# ╠═c5193537-9e52-4391-b352-3aaf640192c4
# ╠═db2c9293-1c23-4708-b1a9-5ed013d1f8f4
