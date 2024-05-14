module HPGL

using LibSerialPort
using Dates
using PortAudio
using CairoMakie

CairoMakie.activate!(; type="svg") #Can be svg

export plot_command!, plot_commands!, start_plot_repl, set_up_serial_port_plotter,
       micmeter, polar_micmeter,                          # From audio.jl
       VisualizationConfig, set_up_visualization_plotter, # From visualize.jl
       validate_hpgl_file                                      # From file-handling.jl

"""
    handle_command!(destination::T, command)

Send `command` to `destination`, dispatching on the destination's type `T`. All
destination types supported by this package must implement a `handle_command!` for
that type.
"""
handle_command!(::Missing, command) = nothing

function handle_command!(::Any, command)
    throw(ErrorException("Unsupported plotter type `$(typeof(plotter))` for $plotter; if this is a new plotter type, ensure `handle_command!(::NewType,...)` is implemented "))
end

"""
    plot_command!(dest, command; pen_up_immediately_after_command)

Send single `command` to plot destination `dest`, where it will be handled by that destination
type's [`handle_command!`](@ref).

If `pen_up_immediately_after_command` is true, any "pen down" or "pen move while pen down" commands (PD, PA)
will be followed by a "pen up command", to prevent pen bleed in situations where commands
are sent infrequently to a physical pen plotter.
"""
function plot_command!(dest, command; pen_up_immediately_after_command::Bool)
    endswith(command, ";") || (command *= ";")
    command *= "\n"
    @debug "Sending: " command
    handle_command!(dest, command)

    if pen_up_immediately_after_command &&
       (startswith(command, "PA") || startswith(command, "PD"))
        handle_command!(dest, "PU;\n")
    end
    return nothing
end

"""
    start_plot_repl(destination; pen_up_immediately_after_command=true,
                    logfile="plotter_repl_debug_$(now()).hpgl")

Start REPL-like environment that prompts for individual commands and then executes them
for `destination` via [`plot_command!`](@ref). Additionally logs all commands entered
at the REPL to `logfile`, unless `logfile=missing`.

If `pen_up_immediately_after_command` is true, any "pen down" or "pen move while pen down" commands (PD, PA)
will be followed by a "pen up command", to prevent pen bleed in situations where commands
are sent infrequently to a physical pen plotter.
"""
function start_plot_repl(destination; pen_up_immediately_after_command=true,
                         logfile="plotter_repl_debug_$(now()).hpgl")
    if isdefined(Main, :VSCodeServer)
        @warn "Likely cannot run `destination_repl` from an interactive VSCode session; user input broken"
    end
    while true
        print("Enter next command: ")
        command = readline()
        command == "exit()" && break
        plot_command!(destination, command; pen_up_immediately_after_command)
        plot_command!(logfile, command; pen_up_immediately_after_command)
    end
    return logfile
end

"""
    plot_commands!(destination, commands; rate_limit_duration_sec=0.2,
                   pen_up_immediately_after_command=true, logfile=missing)

Send a series of `commands`` to `destination` via [`plot_command!`](@ref), with a
pause of `rate_limit_duration_sec` between each command. If `logfile` is not missing,
will additionally append `commands` to `logfile`.
"""
function plot_commands!(destination, commands; rate_limit_duration_sec=0.2,
                        pen_up_immediately_after_command=true,
                        logfile=missing)
    for command in commands
        plot_command!(destination, command; pen_up_immediately_after_command)
        plot_command!(logfile, command; pen_up_immediately_after_command)
        rate_limit_duration_sec == 0 || sleep(rate_limit_duration_sec)
    end
    return nothing
end

"""
    plot_hpgl_file!(destination, commands; rate_limit_duration_sec=0.2,
                   pen_up_immediately_after_command=false)

Send a file of HPGL `commands`` to `destination` via [`plot_commands!`](@ref), with a
pause of `rate_limit_duration_sec` between each command.
"""
function plot_hpgl_file!(destination, hpgl_file; rate_limit_duration_sec=0.2,
                         pen_up_immediately_after_command=false)
    commands = read_hpgl_commands(hpgl_file)
    return plot_commands!(destination, commands; rate_limit_duration_sec,
                          pen_up_immediately_after_command)
end

#####
##### Validation
#####

function validate_hpgl_commands(destination, commands)
    @warn "`validate_hpgl_commands` not implemented for destination of type $(typeof(destination))"
    return nothing
end

function validate_hpgl_file(destination, hpgl_file)
    commands = read_hpgl_commands(hpgl_file)
    return validate_hpgl_commands(destination, commands)
end

#####
##### Pen plotter (communication via serial port)
#####

handle_command!(port::SerialPort, command::String) = write(port, command)

function set_up_serial_port_plotter(; portname="/dev/tty.usbserial-10", baudrate=9600)
    if !((portname in get_port_list()) ||
         (replace(portname, "tty" => "cu") in get_port_list()))
        @warn "Port `$(portname) not found; ensure plotter is connected!" found = list_ports()
        return missing
    end
    # TODO-future: make idempotent; check if port already open, return it if so; could maybe add a global var for it? would we
    # ever have multiple open at once??
    return LibSerialPort.open(portname, baudrate)
end

#####
##### Log file (write each command to file)
#####

function handle_command!(filepath::String, command::String)
    if !isfile(filepath)
        mkpath(dirname(filepath))
        touch(filepath)
    end
    open(f -> write(f, command), filepath, "a")
    return nothing
end

#####
##### Includes
#####

include("./file-handling.jl")
include("./audio.jl")
include("./visualize.jl")

end # module HPGL
