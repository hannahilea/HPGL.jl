using HPGL
using Dates

# Set up plotter
plotter_port = set_up_serial_port_plotter()
logfile = "polar_audio_plotter_repl_debug_$(now()).hpgl"

# Not strictly necessary BUT will reset any settings you previously had going,
# which is probably what you want unless you KNOW you don't want it
plot_commands!(plotter_port, ["IN", "SP1", "PA0,0"]; logfile)

# Start monitoring sound!
polar_micmeter(plotter_port; logfile, num_steps=1_000)

# ...clean up after yourself:
plot_commands!(plotter_port, ["PU", "PA 0,0", "SP0"]; logfile)

outfile = "polar.html"
run(pipeline(`../plotter-tools/viz/target/debug/viz $logfile`; stdout=outfile))
run(`open $outfile`)
