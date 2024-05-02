using Pkg
Pkg.activate("/Users/skye/Documents/CODE/RC/HPGL.jl/audio")
using HPGL
using PortAudio
using SampledSignals: s
using CairoMakie
CairoMakie.activate!(; type="svg") #Can be svg
using LibSerialPort

# Set up audio input
stream = PortAudioStream(1, 0)

# Record in 3 s of audio
buf = read(stream, 3s)

# Generate y-values
num_resolutions=100 #TODO better name, more like
function basic_abs_max(samples; num_samples_per_window=100)
    # Non-overlapping windows
    windows = Iterators.partition(samples, num_samples_per_window)
    return map(windows) do w
        peak = maximum(abs.(w))
         # clamp to -60dB, 0dB
        peak = clamp.(20log10.(peak), -60.0, -30.0)
        return trunc.(Int, (peak + 60)/60 * (num_resolutions-1)) + 1

    end
end
output_basic_abs_max = basic_abs_max(buf.data)

# Set up plotting output (for now, visualization)
function initialize_plotter()
    ps = PlotState(PlotterConfig(; debug=true, linewidth=10))
    plot_commands!(ps, ["IN", "SP1", "PA 0,0", "PD"])
    display(ps)
    return ps
end

# Convert to HPGL 
let
    ps = initialize_plotter()
    x = 0
    for (i, m) in enumerate(output_basic_abs_max)
        x += 5
        y = m #TODO: scale!! relative to one line height, and for max/min
        plot_command!(ps, "PA $x,$y")
        (i % 100 == 0) && display(ps)
    end
    save("outfile.png", ps.f)
end

# Play it to test 
PortAudioStream(0, 2; samplerate=buf.samplerate) do stream
    write(stream, buf.data)
end

# Okay, set up plotter...
# # rc_plotter_port = SerialPort.new("/dev/tty.usbserial-10", 9600,  8, true, nil);  TODO: uncomment to actually run!
# using LibSerialPort
# list_ports()
# portname = "/dev/cu.usbserial-10"
# baudrate = 9600

# # Snippet from examples/mwe.jl
# @assert portname in get_port_list()
# port = LibSerialPort.open(portname, baudrate)

# write(port, "IN\n")
# write(port, "SP0\n")
# write(port, "SP1\n")
