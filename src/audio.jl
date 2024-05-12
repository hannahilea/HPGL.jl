
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

# 10300, 7650
function polar_micmeter(plotter_port; start_point=(5150, 3825), logfile, num_steps=100,
                        t_step=20 * pi / num_steps, r_step=(7650 * 0.5) / num_steps, constant_arc=20)
    mic = PortAudioStream(1, 0; latency=0.1)
    safety_up = false
    println("Press Ctrl-C to quit")
    theta = 0
    radius = 500

    _round = a -> Int(floor(a))

    @info "PRE"
    for i in 1:num_steps  # while true
        
        # @info i
        block = read(mic, 12000) #TODO-may need to adjust! #TODO: LUDWIG IS EXCITED
        blockmax_raw = maximum(abs.(block)) # find the maximum value in the block #TODO-try keeping sign!!
        blockmax = Int(floor(log(blockmax_raw) * 100))
        # @debug blockmax_raw blockmax

        r_scaled = radius - blockmax #TODO: add amplitude!

        x = _round(first(start_point) + r_scaled * cos(theta))
        y = _round(last(start_point) + r_scaled * sin(theta))
        # sleep(.02)

        # y = y_offset + blockmax #TODO-maybe scale for niceness
        # @debug x y
        send_plotter_cmds(plotter_port, ["PA $x,$y"]; safety_up, logfile)
        if i == 1
            send_plotter_cmds(plotter_port, ["PD"]; safety_up, logfile)
        end
        
        radius += r_step
        theta += t_step
        # theta = constant_arc / ((1 + radius)/3825)
        # @info radius theta
        if radius > 3825
            @info "We're over the limit!"
            send_plotter_cmds(plotter_port, ["PU", "SP0"]; safety_up, logfile)
            break
        end
    end
    return nothing
end
