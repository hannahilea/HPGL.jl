using HPGL
using Dates

# Set up plotter
plotter_port = set_up_serial_port_plotter()
logfile = "audio_plotter_repl_debug_$(now()).hpgl"

# Not strictly necessary BUT will reset any non-default plotter settings,
# which is probably what you want unless you KNOW you don't want it
plot_commands!(plotter_port, ["IN", "SP1", "PA0,0"]; logfile)

# Start monitoring sound!
micmeter(; x_offset=0, y_offset=500)

# ...clean up after yourself:
plot_commands!(plotter_port, ["PU", "PA 0,0", "SP0"]; logfile)
