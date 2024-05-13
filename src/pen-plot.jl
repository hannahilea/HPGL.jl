function set_up_serial_port_plotter(; portname="/dev/tty.usbserial-10",
                                    baudrate=9600)
    if !((portname in get_port_list()) ||
         (replace(portname, "tty" => "cu") in get_port_list()))
        @warn "Port `$(portname) not found; ensure plotter is connected!" found = list_ports()
        return missing
    end
    # TODO-future: make idempotent; check if port already open, return it if so; could maybe add a global var for it? would we
    # ever have multiple open at once??
    return LibSerialPort.open(portname, baudrate)
end

#TODO-future: actual julia repl mode for plotter
function run_plotter_repl(port; safety_up=true, logfile="plotter_repl_debug_$(now()).hpgl")
    if isdefined(Main, :VSCodeServer)
        @warn "Likely cannot run `plotter_repl` from an interactive VSCode session; user input broken"
    end
    while true
        print("Enter next command: ")
        cmd = readline()
        cmd == "exit()" && break
        run_command(port, cmd; safety_up)
        run_command(logfile, cmd; safety_up)
    end
    return logfile
end

"""
    send_plotter_cmds(port, cmds; rate_limit_duration_sec=0.2, safety_up=true)

Send a series of commands via [`run_command`](@ref), with a `rate_limit_duration_sec`
pause between each function.
"""
function send_plotter_cmds(port, cmds; rate_limit_duration_sec=0.2, safety_up=true,
                           logfile=missing)
    for cmd in cmds
        run_command(port, cmd; safety_up)
        run_command(port, cmd; safety_up)
        run_command(logfile, cmd; safety_up)
        @debug "Sent cmd" cmd
        rate_limit_duration_sec == 0 || sleep(rate_limit_duration_sec)
    end
    return nothing
end

"""
    run_command(plotter, cmd; safety_up)

Send single `cmd` to plotter serial port `port`. If `safety_up` is true, any pen down/pen move
instructions are followed by a "pen up command". `cmd` will additionally be appended
to `logfile` path, unless `logfile` is `missing`.
"""
function run_command(plotter, cmd; safety_up::Bool)
    endswith(cmd, ";") || (cmd *= ";")
    cmd *= "\n"
    @debug "Sending: " cmd

    handle_cmd(plotter, cmd)

    if safety_up && (startswith(cmd, "PA") || startswith(cmd, "PD"))
        handle_cmd(plotter, "PU;\n")
    end
    return nothing
end

handle_cmd(::Missing, cmd) = nothing

handle_cmd(port::SerialPort, cmd::String) = write(port, cmd)

function handle_cmd(filepath::String, cmd::String)
    if !isfile(filepath)
        mkpath(dirname(filepath))
        touch(filepath)
    end
    return open(filepath, "a") do file
        return write(file, cmd)
    end
    return nothing
end
