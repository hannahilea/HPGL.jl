function set_up_plotter(; portname="/dev/tty.usbserial-10",
                        baudrate=9600)
    if !((portname in get_port_list()) ||
         (replace(portname, "tty" => "cu") in get_port_list()))
        @warn "Port `$(portname) not found; ensure plotter is connected!" found = list_ports()
    end
    return LibSerialPort.open(portname, baudrate)
end

function run_plotter_repl(port; safety_up=true, outfile="plotter_repl_debug_$(now()).hpgl")
    if isdefined(Main, :VSCodeServer)
        @warn "Likely cannot run `plotter_repl` from an interactive VSCode session; user input broken"
    end
    while true
        print("Enter next command: ")
        cmd = readline()
        cmd == "exit()" && break
        send_plotter_cmd(port, cmd; safety_up, outfile)
    end
    return outfile
end

#TODO: actual julia repl mode for plotter
#TODO: move kwargs into options struct
#TODO: if port is missing, handle that nicely too
#TODO: rename `outfile` to `logfile`

function send_plotter_cmds(port, cmds; kwargs...)
    for cmd in cmds
        send_plotter_cmd(port, cmd; kwargs...)
        sleep(.2)
    end
    return nothing
end

function send_plotter_cmd(port, cmd::String; safety_up=true, outfile)
    if !ismissing(outfile) && !isfile(outfile)
        mkpath(dirname(outfile))
        touch(outfile)
        @info "Saving commands out to $outfile"
    end

    endswith(cmd, ";") || (cmd *= ";")
    cmd *= "\n"

    @debug "Sending: " cmd
    write(port, cmd)
    append_to_file!(outfile, cmd)

    if safety_up && (startswith(cmd, "PA") || startswith(cmd, "PD"))
        cmd_up = "PU;"
        write(port, cmd_up)
        append_to_file!(outfile, cmd_up * "\n")
    end
    return nothing
end

append_to_file!(_, ::Missing) = nothing
function append_to_file!(file, str)
    return open(file, "a") do f
        return write(f, str)
    end
end