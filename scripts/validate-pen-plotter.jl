using Pkg
Pkg.activate(".") # Should be path to HPGL/audio directory
using HPGL

plotter_port = set_up_serial_port_plotter()
start_plot_repl(plotter_port; pen_up_immediately_after_command=true)

#= At the prompt, try
IN
SP2
PA 0,0
PD 0,7000
PD 5000,7400
PD 10000,7400
VS 2
PD 0,7400
PA 0,6000
VS 10
PD 5000,6000
VS 20
PD 10000,6000
=#
close(plotter_port)
