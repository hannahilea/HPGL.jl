# HPGL.jl

Interface for generating both realtime and offline [(HPGL)](https://en.wikipedia.org/wiki/HP-GL) code, which can sent directly to a pen plotter or previewed with the included visualizer. 

To plot a full pre-generated HPGL file with an external pen plotter, use this [external `chunker` utility](https://github.com/WesleyAC/plotter-tools/tree/4a285e167421d2a917561413cda4e8724e860f5c/chunker).

## Installation 
With [Julia installed](https://julialang.org/downloads/), start the Julia REPL and add this package to your environment:
```
using Pkg
Pkg.add("url="https://github.com/hannahilea/HPGL.jl")
using HPGL
```

## Pen plotter usage: realtime audio plotting!
The [scripts/](./scripts/) directory contains some common entrypoints for generating/working with generating HPGL and a pen plotter.

- [`validate-serialport.jl`](./scripts/validate-serialport.jl): Test script to ensure plotter serialport connection is valid. Run each command sequentially in the Julia REPL.
- [`explore-hpgl-commands.jl`](./scripts/explore-hpgl-commands.jl): Test script to explore additional pen plotter commands. Run each command sequentially in the REPL.
- [`audio-meter-plot.jl`](./scripts/audio-meter-plot.jl): Demonstrates entrypoint to plotting realtime audio, as plotted horizontally across the page. Run each command sequentially in the REPL.
- [`polar-audio.jl`](./scripts/polar-audio.jl): Demonstrates entrypoint to plotting realtime audio, as plotted spiraling out from the center of the page. Run each command sequentially in the REPL.


## Non-pen plotter utilities

### File validation

To validate a file, do
```
using HPGL
validate_file(joinpath(pkgdir(HPGL), "examples/demo.hpgl")) # No output if file is valid
validate_file(joinpath(pkgdir(HPGL), "examples/invalid_file.hpgl")) # Shows warnings for unexpected/invalid file contents
```

### File preview/visualization

To preview an HPGL file, and save it's resultant output to `outfile`, do
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

### Realtime (cumulative) preview/visualization

To preview HPGL commands one at a time, do
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

## External resources
- https://github.com/WesleyAC/plotter-tools

