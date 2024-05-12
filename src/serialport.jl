function set_up_plotter(; portname="/dev/tty.usbserial-10",
                        baudrate=9600)
    if !((portname in get_port_list()) ||
         (replace(portname, "tty" => "cu") in get_port_list()))
        @warn "Port `$(portname) not found; ensure plotter is connected!" found = list_ports()
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

#TODO: actual julia repl mode for plotter
#TODO: move kwargs into options struct
#TODO: if port is missing, handle that nicely too
#TODO: rename `logfile` to `logfile`

function send_plotter_cmds(port, cmds; kwargs...)
    for cmd in cmds
         @debug "okay" cmd
        send_plotter_cmd(port, cmd; kwargs...)
        # sleep(.2)
    end
    return nothing
end

function send_plotter_cmd(port, cmd::String; safety_up=true, logfile)
    if !ismissing(logfile) && !isfile(logfile)
        mkpath(dirname(logfile))
        touch(logfile)
        @info "Saving commands out to $logfile"
    end

    endswith(cmd, ";") || (cmd *= ";")
    cmd *= "\n"

    @debug "Sending: " cmd
    write(port, cmd)
    append_to_file!(logfile, cmd)

    if safety_up && (startswith(cmd, "PA") || startswith(cmd, "PD"))
        cmd_up = "PU;"
        write(port, cmd_up)
        append_to_file!(logfile, cmd_up * "\n")
    end
    return nothing
end

append_to_file!(_, ::Missing) = nothing
function append_to_file!(file, str)
    return open(file, "a") do f
        return write(f, str)
    end
end
