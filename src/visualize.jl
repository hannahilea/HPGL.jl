Base.@kwdef struct VisualizationConfig
    plot_dimensions = (10300, 7650)
    pen_colors = [:black, :red, :yellow, :blue]
    linewidth = 20 # pen thickness
    debug = false
    debug_pen_up_color = :magenta
end

Base.@kwdef mutable struct VisualizationState
    config::VisualizationConfig
    i_pen::Int = 0
    pen_is_down::Bool = false
    pen_position = Point2{Int64}(0, 0)
    f::Figure
    ax::Axis
end

function VisualizationState(config)
    f = Figure(; size=config.plot_dimensions)
    ax = Axis(f[1, 1];
              limits=(-10, first(config.plot_dimensions) + 10, -10,
                      last(config.plot_dimensions) + 10))
    hidedecorations!(ax)
    config.debug || hidespines!(ax)  # hide the frame
    return VisualizationState(; config, f, ax)
end

set_up_visualization_plotter(config=VisualizationConfig()) = VisualizationState(config)

Base.display(s::VisualizationState) = Base.display(s.f)
save_visualization(ps::VisualizationState, outfile) = save(outfile, ps.f)

function handle_command!(state::VisualizationState, cmd)
    cmd = rstrip(cmd, '\n')
    cmd = rstrip(cmd, ';')
    if startswith(cmd, "PD")
        state.pen_is_down = true
        coords = get_coords_from_parameter_str(cmd[3:end])
        for c in coords
            pos = Point2(c)
            _move_to_point!(state, pos)
        end
    elseif cmd == "PU"
        state.pen_is_down = false
    elseif cmd == "IN"
        _move_to_point!(state, Point2{Int64}(0, 0))
        state.pen_is_down = false
        state.i_pen = 0
    elseif startswith(cmd, "SP")
        _move_to_point!(state, Point2{Int64}(0, 0))
        state.pen_is_down = false
        state.i_pen = get_pen_index(cmd)
    elseif startswith(cmd, "PA")
        coords = get_coords_from_parameter_str(cmd[3:end])
        for c in coords
            pos = Point2(c)
            _move_to_point!(state, pos)
        end
    else
        @warn "`$cmd` is currently unsupported by visualizer; skipping"
    end
    return nothing
end

function validate_hpgl_commands(::VisualizationConfig, commands)
    first(commands) == "IN" || @warn "Expected first command to be `IN`"
    startswith(commands[2], "SP") ||
        @warn "Expected second command to select a pen (e.g. `SP1`)"

    for cmd in commands
        if startswith(cmd, "SP")
            get_pen_index(cmd) ## Will print warning if unexpected pen is found
        elseif startswith(cmd, "PA") || startswith(cmd, "PD") || startswith(cmd, "PU")
            get_coords_from_parameter_str(cmd[3:end]) ## Will print warning if formatting is unexpected
        elseif !in(cmd, ["IN"])
            @warn "Unexpected command `$cmd` (could still be a valid command, just not yet handled by visualize.jl)"
        end
    end
    #TODO-future: test that PU always happens before changing a pen
    # TODO-future: ensure there's no more than one PA before PD; ensure PD/PU order is meaningful

    commands[end - 1] == "PU" || @warn "Expected penultimate command to be `PU` (pen up)"
    last(commands) == "SP0" || @warn "Expected final command to be `SP0` (deselect pen)"
    return nothing
end

#####
##### Validation utils
#####

function validate_position(pos_string::AbstractString, args...)
    coords = get_coords_from_parameter_str(pos_string)
    if length(coords) != 1
        str = "Currently only one position per mnemonic is supported by this plotting visualization!"
        @warn str
        return str
    end
    return validate_position(only(coords), args...)
end

function validate_position(pos, plot_dimensions)
    if !(0 <= first(pos) <= first(plot_dimensions) &&
         0 <= last(pos) <= last(plot_dimensions))
        str = "Requested position `$pos` outside of plottable area `$(plot_dimensions)! Will be ignored."
        @warn str
        return str
    end
    return nothing
end

function _get_current_pen_color(state)
    if state.pen_is_down && state.i_pen != 0
        return state.config.pen_colors[state.i_pen]
    end
    return state.config.debug_pen_up_color
end

function _move_to_point!(state::VisualizationState, pos)
    isnothing(validate_position(pos, state.config.plot_dimensions)) || return nothing
    if state.pen_is_down || state.config.debug
        points = [state.pen_position, pos]
        color = _get_current_pen_color(state)
        @debug points color
        lines!(points; color, state.config.linewidth)
    end
    state.pen_position = pos
    return state
end

#TODO-future: nicely handle bad format, fail nicely or something
function get_coords_from_parameter_str(str::AbstractString)
    str = rstrip(lstrip(str))
    isempty(str) && return []
    return map(split(str, " ")) do param
        coord_strs = split(rstrip(lstrip(param)), ",")
        #TODO-future: handle float + 4 digits?
        coords = let
            fl = parse.(Float64, filter(!isempty, coord_strs))
            Int.(round.(fl))
        end
        length(coords) == 2 ||
            (@warn "Unexpected position command (`$param`); expected format `x,y`")
        return coords
    end
end

function get_pen_index(cmd)
    startswith(cmd, "SP") || (@warn "Unexpected prefix for position ($cmd)")
    i = parse(Int, lstrip(cmd[3:end]))
    i > 8 && (@warn "Pen index `$i` may be out of bounds for supported number of pens")
    return i
end
