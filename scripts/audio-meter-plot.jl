using PortAudio
using HPGL

# Set up plotter
plotter_port = set_up_plotter()
logfile = "audio_plotter_repl_debug_$(now()).hpgl"
send_plotter_cmds(plotter_port, ["IN", "SP3", "PA0,0", "PU"]; logfile)
micmeter(; x_offset=0, y_offset=500)

send_plotter_cmds(plotter_port, ["PU", "PA 0,0", "SP0"]; safety_up, logfile)
