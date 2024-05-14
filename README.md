# HPGL.jl

[![docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://hannahilea.github.io/HPGL.jl/dev)
[![CI](https://github.com/hannahilea/HPGL.jl/actions/workflows/HPGL_CI.yml/badge.svg)](https://github.com/hannahilea/HPGL.jl/actions/workflows/HPGL_CI.yml)
[![codecov](https://codecov.io/gh/hannahilea/HPGL.jl/branch/main/graph/badge.svg?token=7pWFU40sqY)](https://app.codecov.io/gh/hannahilea/HPGL.jl)

Interface for generating and handling both realtime and offline [Hewlett-Packard Graphics Language (HP-GL)](https://en.wikipedia.org/wiki/HP-GL) commands, which can sent directly to a pen plotter or previewed as an image via the included visualizer.

The [scripts/](./scripts/) directory contains some common entrypoints for generating/working with generating HPGL and a pen plotter.

- [`validate-pen-plotter.jl`](./scripts/validate-pen-plotter.jl): Test script to ensure plotter serial port connection is valid, then provides a **REPL-type interaction with the external pen plotter**. Run each command sequentially in the Julia REPL.
- [`explore-hpgl-commands.jl`](./scripts/explore-hpgl-commands.jl): Test script to explore additional pen plotter commands. Run each command sequentially in the REPL.
- [`audio-meter-plot.jl`](./scripts/audio-meter-plot.jl): Demonstrates entrypoint to **plotting realtime audio, horizontally across the page**. Run each command sequentially in the REPL.
- [`polar-audio.jl`](./scripts/polar-audio.jl): Demonstrates entrypoint to **plotting realtime audio, as spiraling out from the center of the page**. Run each command sequentially in the REPL.

To plot a full pre-generated HPGL file with an external pen plotter, use this [external `chunker` utility](https://github.com/WesleyAC/plotter-tools/tree/4a285e167421d2a917561413cda4e8724e860f5c/chunker).

## Installation
With [Julia installed](https://julialang.org/downloads/), start the Julia REPL and add this package to your environment:
```
using Pkg
Pkg.add("url="https://github.com/hannahilea/HPGL.jl")
using HPGL
```

## Non-pen plotter utilities

### File validation

To validate a file, do
```
using HPGL
validate_hpgl_file(VisualizationConfig(), joinpath(pkgdir(HPGL), "examples/demo.hpgl")) # No output if file is valid
validate_hpgl_file(VisualizationConfig(), joinpath(pkgdir(HPGL), "examples/invalid_file.hpgl")) # Shows warnings for unexpected/invalid file contents
```

### File preview/visualization

To preview an HPGL file with the visualizer, do
```
using HPGL
viz=set_up_visualization_plotter()
plot_hpgl_file!(viz, "examples/demo.hpgl")
display(viz) # to view
```

Use debug mode to additionally draw the borders of the plottable area as well as draw the paths of all pen-up movements:
```
using HPGL
viz = set_up_visualization_plotter(VisualizationConfig(; debug=true))
plot_hpgl_file!(viz, "examples/demo.hpgl")
display(viz) # to view
save_visualization(viz, "demo.png") # save image
save_visualization(viz, "demo.svg") #...or as svg
```
For additional configuration, see help docs by doing `?plot_hpgl_file!` in the REPL.

### Realtime (cumulative) preview/visualization

To preview HPGL commands one at a time, do
```
using HPGL

# set up basic plotter output figure
viz = set_up_visualization_plotter()

# plot initial input commands
plot_commands!(viz, ["IN", "SP1", "PA 300,300", "PD"])

# plot commands one at a time
plot_command!(viz, "PA 3000,3000")

# plot commands in bulk
cmds = map(x -> "PA $x,$(x^1.1)", 1:10:1_000)
plot_commands!(viz, cmds)
```

## External resources
- https://github.com/WesleyAC/plotter-tools
