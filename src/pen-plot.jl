function set_up_plotter(; portname="/dev/tty.usbserial-10",
                        baudrate=9600)
    if !((portname in get_port_list()) ||
         (replace(portname, "tty" => "cu") in get_port_list()))
        @warn "Port `$(portname) not found; ensure plotter is connected!" found = list_ports()
        return missing
    end
    return LibSerialPort.open(portname, baudrate)
end

function run_plotter_repl(port; safety_up=true, logfile="plotter_repl_debug_$(now()).hpgl")
    if isdefined(Main, :VSCodeServer)
        @warn "Likely cannot run `plotter_repl` from an interactive VSCode session; user input broken"
    end
    while true
        print("Enter next command: ")
        cmd = readline()
        cmd == "exit()" && break
        send_plotter_cmd(port, cmd; safety_up, logfile)
    end
    return logfile
end

"""
    send_plotter_cmds(port, cmds; rate_limit_duration_sec=0.2, kwargs...)

Send a series of commands via [`send_plotter_cmd`](@ref), with a `rate_limit_duration_sec`
pause between each function.
"""
function send_plotter_cmds(port, cmds; rate_limit_duration_sec=0.2, kwargs...)
    for cmd in cmds
        send_plotter_cmd(port, cmd; kwargs...)
        @debug "Sent cmd" cmd
        rate_limit_duration_sec == 0 || sleep(rate_limit_duration_sec)
    end
    return nothing
end

"""
    send_plotter_cmd(port, cmd::String; safety_up=true, logfile)

Send single `cmd` to plotter serial port `port`. If `safety_up` is true, any pen down/pen move
instructions are followed by a "pen up command". `cmd` will additionally be appended
to `logfile` path, unless `logfile` is `missing`.
"""
function send_plotter_cmd(port, cmd::String; safety_up=true, logfile)
    if !ismissing(logfile) && !isfile(logfile)
        mkpath(dirname(logfile))
        touch(logfile)
        @info "Saving commands out to $logfile"
    end

    endswith(cmd, ";") || (cmd *= ";")
    cmd *= "\n"

    @debug "Sending: " cmd
    !ismissing(port) && write(port, cmd)
    append_to_file!(logfile, cmd)

    if safety_up && (startswith(cmd, "PA") || startswith(cmd, "PD"))
        cmd_up = "PU;"
        !ismissing(port) && write(port, cmd_up)
        append_to_file!(logfile, cmd_up * "\n")
    end
    return nothing
end

append_to_file!(::Missing, _) = nothing
function append_to_file!(file, str)
    return open(file, "a") do f
        return write(f, str)
    end
end
