# HPGL.jl

Generates [(HPGL)](https://en.wikipedia.org/wiki/HP-GL) files, which can be written to a file or sent directly to a pen plotter.

To plot HPGL file with an external pen plotter, use this [external `chunker` utility](https://github.com/WesleyAC/plotter-tools/tree/4a285e167421d2a917561413cda4e8724e860f5c/chunker). 

## Installation 
With [Julia installed](https://julialang.org/downloads/), start the Julia REPL and add this package to your environment:
```
using Pkg
Pkg.add("url="https://github.com/hannahilea/HPGL.jl")
using HPGL
```

## Usage

### File validation

To validate a file, do
```
using HPGL
validate_file(joinpath(pkgdir(HPGL), "examples/demo.hpgl")) # No output if file is valid
validate_file(joinpath(pkgdir(HPGL), "examples/invalid_file.hpgl")) # Shows warnings for unexpected/invalid file contents
```

### File preview/visualization

To plot an HPGL file, and save it's resultant output to `outfile`, do
```
using HPGL
p = plot_file("examples/demo.hpgl"; outfile="myfile.png")
display(p) # to view
```

Use debug mode to additionally draw the borders of the plottable area as well as draw the paths of all pen-up movements: 
```
using HPGL
p = plot_file("examples/demo.hpgl"; config=PlotterConfig(; debug=true), outfile="myfile.png")
display(p) # to view
```
For additional configuration, see help docs by doing `?plot_file` in the REPL.

### Cumulative preview

To plot HPGL commands one at a time, do
```
using HPGL

# set up basic plotter output figure
ps = PlotState(PlotterConfig())

# plot initial input commands
plot_commands!(ps, ["IN", "SP1", "PA 300,300", "PD"])

# plot commands one at a time 
plot_command!(ps, "PA 3000,3000")

# plot commands in bulk
cmds = map(x -> "PA $x,$(x^1.2)", 1:10:10_000)
plot_commands!(ps, cmds)
```

## Resources
- https://github.com/WesleyAC/plotter-tools

## Dev notes
Up next:
- [ ] Docstrings
- [ ] Set up https://github.com/JuliaIO/LibSerialPort.jl to support sending HGPL to the plotter directly (instead of relying on external tools)
- [ ] Support other basic HGPL commands that the plotter supports (relative position, text, etc)
- [ ] Set up GHA for built docs/CI/tests (+ add tests...)
