using Pkg
Pkg.activate(".") # Should be path to HPGL/audio directory
using HPGL
using PortAudio
using SampledSignals: s
using Dates
using CairoMakie
CairoMakie.activate!(; type="svg") #Can be svg

# Set up audio input
stream = PortAudioStream(1, 0)

# Record audio
buf = read(stream, 10s)
# Play it to test 
PortAudioStream(0, 2; samplerate=buf.samplerate) do stream
    return write(stream, buf.data)
end

# Generate y-values
num_resolutions = 100 #TODO better name, more like
function basic_abs_max(samples; num_samples_per_window=Int(round(buf.samplerate / 4)))
    # Non-overlapping windows
    windows = Iterators.partition(samples, num_samples_per_window)
    return map(windows) do w
        peak = maximum(abs.(w))
        # clamp to -60dB, 0dB
        peak = clamp.(20log10.(peak), -60.0, -20.0)
        #TODO-figure out if this next line is doing what i want!!!
        return trunc.(Int, (peak + 60) / 60 * (num_resolutions - 1)) + 1
    end
end
output_basic_abs_max = basic_abs_max(buf.data)

# Set up plotter
safety_up = false
plotter_port = set_up_plotter()
outfile = "audio_plotter_repl_debug_$(now()).hpgl"
send_plotter_cmds(plotter_port, ["IN", "SP2", "PA0,0", "PU"]; safety_up, outfile)

# Convert to HPGL 
let
    x = 2000
    y_offset = 1000
    send_plotter_cmds(plotter_port, ["PU", "PA$x,$(y_offset)"]; safety_up, outfile)
    for (i, m) in enumerate(output_basic_abs_max)
        x += 100
        if x == 6000
            x = 0
            y_offset += 1000
            send_plotter_cmds(plotter_port, ["PU", "PA$x,$(y_offset)"]; safety_up, outfile)
            sleep(0.1)
        end
        y = m * 10 + y_offset #TODO: scale!! relative to one line height, and for max/min
        send_plotter_cmds(plotter_port, ["PD$x,$y"]; safety_up, outfile)
    end
end
