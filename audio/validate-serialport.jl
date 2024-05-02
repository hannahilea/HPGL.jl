using Pkg
Pkg.activate("/Users/skye/Documents/CODE/RC/HPGL.jl/audio")
using HPGL
using LibSerialPort

# Okay, set up plotter...
portname = "/dev/tty.usbserial-10"
baudrate = 9600

# Snippet from examples/mwe.jl
@assert (portname in get_port_list()) ||
        (replace(portname, "tty" => "cu") in get_port_list())
port = LibSerialPort.open(portname, baudrate)

write(port, "IN;\n")
write(port, "SP2;\n")

# Reminder: cannot be run as interactive vscode script, "readline()" breaks woooo
@info "Enter commands manually! Remember to pick the pen up (PU) after each PA, unless you're rapidly sending a bunch of them...."
function plotter_repl(; safety_up=true)
    while true
        print("Enter next command: ")
        cmd = readline()
        cmd == "exit()" && break
        endswith(cmd, ";") || (cmd *= ";")
        @debug "Sending: " cmd
        write(port, cmd * "\n")
        if safety_up && (startswith(cmd, "PA") || startswith(cmd, "PD"))
            write(port, "PU\n")
        end
    end
    return nothing
end
plotter_repl(; safety_up=true)
# Success!
