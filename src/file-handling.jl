
#####
##### Full-file handling
#####

function read_hpgl_commands(hpgl_file)
    if !isfile(hpgl_file)
        throw(ArgumentError("File $(hpgl_file) not found!"))
    end
    str = read(hpgl_file, String)
    raw_commands = split(replace(str, "\n" => ";"), ";")
    cmds = map(raw_commands) do cmd
        return rstrip(lstrip(cmd))
    end
    return filter(!isempty, cmds)
end
