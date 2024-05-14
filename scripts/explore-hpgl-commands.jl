using Pkg
Pkg.activate(".") # Should be path to HPGL directory
using HPGL
using Dates

plotter_port = set_up_serial_port_plotter()
pen_up_immediately_after_command = false

logfile = "explore_plotter_repl_debug.hpgl"
plot_commands!(plotter_port, ["IN", "SP2", "PA0,0"]; pen_up_immediately_after_command, logfile)

y = 1000
for speed in [2, 10, 40]
    cmds = ["VS $speed", "PA 8000,$y", "PD", "PA 9000,$y", "PU"]
    @info cmds
    plot_commands!(plotter_port, cmds; pen_up_immediately_after_command, logfile)
    y += 500
    sleep(0.2)
end

# plot_commands!(plotter_port, ["LBis this a label?;"]; pen_up_immediately_after_command, logfile)

close(plotter_port)
