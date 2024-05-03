
"""
    micmeter(plotter_port; x_offset=0, y_offset=0, xtick=100, ytick=1000, xmax=10_000)
    
Continuously read from the default audio input and send commands to plot the per-buffer level to 
`plotter_port` (via [`send_plotter_cmds`](@ref)).
TODO-document kwargs, pull out more kwargs
"""
function micmeter(plotter_port; x_offset=0, y_offset=0, xtick=100, ytick=1000, xmax=10_000,
                  logfile)
    mic = PortAudioStream(1, 0; latency=0.1)
    safety_up = false
    println("Press Ctrl-C to quit")
    x = x_offset
    try
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
    finally
        send_plotter_cmds(plotter_port, ["PU"]; safety_up, logfile)
    end
    return nothing
end
