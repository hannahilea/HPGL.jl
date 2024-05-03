using PortAudio
using HPGL

"""
Continuously read from the default audio input and plot an
ASCII level/peak meter
"""
function micmeter(; x_offset=0, y_offset=0, xtick=100, ytick=1000, xmax=10_000)
    mic = PortAudioStream(1, 0; latency=0.1)
    println("Press Ctrl-C to quit")
    x = x_offset
    send_plotter_cmds(plotter_port, ["PA$x,$(y_offset)", "PD"]; safety_up, logfile)
    while true
        block = read(mic, 24000) #TODO-may need to adjust!
        blockmax_raw = maximum(abs.(block)) # find the maximum value in the block
        blockmax = Int(floor(blockmax_raw * 1000))
        @debug blockmax_raw blockmax
        y = y_offset + blockmax #TODO-maybe scale for niceness
        @debug x y
        send_plotter_cmds(plotter_port, ["PA $x,$y"]; safety_up, logfile)

        x += xtick
        if x >= xmax
            x = x_offset
            y_offset += ytick
            send_plotter_cmds(plotter_port, ["PU", "PA$x,$(y_offset)", "PD"]; safety_up,
                              logfile)
        end
    end
end

# Set up plotter
plotter_port = set_up_plotter()
safety_up = false
logfile = "audio_plotter_repl_debug_$(now()).hpgl"
send_plotter_cmds(plotter_port, ["IN", "SP3", "PA0,0", "PU"]; safety_up, logfile)
micmeter(; x_offset=0, y_offset=500)

send_plotter_cmds(plotter_port, ["PU", "PA 0,0", "SP0"]; safety_up, logfile)
