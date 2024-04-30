module HPGL

export validate_file
export plot_file, plot_command!, plot_commands!, PlotterConfig, PlotState # From PlotHPGL

function read_commands(filename)
    if !isfile(filename)
        throw(ArgumentError("File $filename not found!"))
    end
    return get_commands(read(filename, String))
end

function get_commands(str::String)
    raw_commands = split(replace(str, "\n" => ";"), ";")
    cmds = map(raw_commands) do cmd
        return rstrip(lstrip(cmd))
    end
    return filter(!isempty, cmds)
end

#TODO-future: nicely handle bad format, fail nicely or something
function get_coords_from_parameter_str(str::AbstractString)
    str = rstrip(lstrip(str))
    isempty(str) && return []
    return map(split(str, " ")) do param
        coord_strs = split(rstrip(lstrip(param)), ",")
        coords = parse.(Int, filter(!isempty, coord_strs)) #TODO-future: check if float supported by printer?
        length(coords) == 2 ||
            (@warn "Unexpected position command (`$cmd`); expected format `PA x,y`")
        return coords
    end
end

function get_pen_index(cmd)
    startswith(cmd, "SP") || (@warn "Unexpected prefix for position ($cmd)")
    i = parse(Int, lstrip(cmd[3:end]))
    i > 8 && (@warn "Pen index `$i` may be out of bounds for supported number of pens")
    return i
end

function validate_file(filename)
    contents = read(filename, String)
    commands = get_commands(contents)
    first(commands) == "IN" || @warn "Expected first command to be `IN`"
    startswith(commands[2], "SP") ||
        @warn "Expected second command to select a pen (e.g. `SP1`)"

    for cmd in commands
        if startswith(cmd, "SP")
            get_pen_index(cmd) ## Will print warning if unexpected pen is found
        elseif startswith(cmd, "PA") || startswith(cmd, "PD") || startswith(cmd, "PU")
            get_coords_from_parameter_str(cmd[3:end]) ## Will print warning if formatting is unexpected 
        elseif !in(cmd, ["IN"])
            @warn "Unexpected command `$cmd` (could still be a valid command, and not yet handled by PlotHPGL.jl)"
        end
    end
    #TODO-future: test that PU always happens before changing a pen
    # TODO-future: ensure there's no more than one PA before PD; ensure PD/PU order is meaningful

    commands[end - 1] == "PU" || @warn "Expected penultimate command to be `PU` (pen up)"
    last(commands) == "SP0" || @warn "Expected final command to be `SP0` (deselect pen)"
    return nothing
end

include("./plotHPGL.jl")
using .PlotHPGL

end # module HPGL
