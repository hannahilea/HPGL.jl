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

    if !ismissing(outfile)
        mkpath(dirname(outfile))
        touch(outfile)
        @info "Saving commands out to $outfile"
    end

    run_command = (cmd) -> begin
        endswith(cmd, ";") || (cmd *= ";")
        cmd *= "\n"
        @debug "Sending: " cmd
        write(port, cmd)
        if !ismissing(outfile)
            open(outfile, "a") do f
                # Make sure we write 64bit integer in little-endian byte order
                return write(f, cmd)
            end
        end
        return nothing
    end

    while true
        print("Enter next command: ")
        cmd = readline()
        cmd == "exit()" && break

        run_command(cmd)
        if safety_up && (startswith(cmd, "PA") || startswith(cmd, "PD"))
            run_command("PU")
        end
    end
    return nothing
end
