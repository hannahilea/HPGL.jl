using Pkg
Pkg.activate(".") # Should be path to HPGL/audio directory
using HPGL
using Dates

plotter_port = set_up_plotter()
safety_up = false

outfile = "explore_plotter_repl_debug.hpgl"
send_plotter_cmds(plotter_port, ["IN", "SP2", "PA0,0"]; safety_up, outfile)

# send_plotter_cmds(plotter_port, ["LBis this a label?;"]; safety_up, outfile)

y = 1000
for speed in [2, 10, 40]
    cmds = ["VS $speed", "PA 8000,$y", "PD", "PA 9000,$y", "PU"]
    @info cmds
    send_plotter_cmds(plotter_port, cmds; safety_up, outfile)
    y += 500
    sleep(0.2)
end

close(plotter_port)
