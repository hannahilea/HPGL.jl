
module PlotHPGL

using CairoMakie
using HPGL: read_commands, get_coords_from_parameter_str, get_pen_index, validate_file,
            validate_commands

CairoMakie.activate!(; type="svg") #Can be svg

export plot_file, plot!, plot_command!, plot_commands!, PlotterConfig, PlotState

const DEFAULT_PLOT_SIZE = (10300, 7650)
const DEBUG_PEN_UP_COLOR = :magenta
const DEFAULT_PEN_COLORS = [:black, :red, :yellow, :blue]

Base.@kwdef struct PlotterConfig
    plot_dimensions = DEFAULT_PLOT_SIZE
    pen_colors = DEFAULT_PEN_COLORS
    linewidth = 20 # pen thickness
    debug = false
end

Base.@kwdef mutable struct PlotState
    config::PlotterConfig
    i_pen::Int = 0
    pen_is_down::Bool = false
    pen_position = Point2{Int64}(0, 0)
    f::Figure
    ax::Axis
end

function PlotState(config)
    f = Figure(; size=config.plot_dimensions)
    ax = Axis(f[1, 1];
              limits=(-10, first(config.plot_dimensions) + 10, -10,
                      last(config.plot_dimensions) + 10))
    hidedecorations!(ax)
    config.debug || hidespines!(ax)  # hide the frame
    return PlotState(; config, f, ax)
end

Base.display(s::PlotState) = Base.display(s.f)

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

function splat_commands(raw_commands)
    commands = []
    for cmd in raw_commands
        split_commands = split(cmd, " "; limit=2)
        if length(split_commands) == 1
            push!(commands, cmd)
        else
            # TODO-future: makes gross assumption that any params ARE coordinates! fix that.
            # TODO-future: makes gross assumption that any params ARE coordinates! fix that.
            mnemonic = first(split_commands)
            if mnemonic != "PA"
                push!(commands, mnemonic)
            end
            for coord in get_coords_from_parameter_str(last(split_commands))
                push!(commands, string("PA", " ", first(coord), ",", last(coord)))
            end
        end
    end
    return commands
end

function plot_file(filename; config=PlotterConfig(), outfile=missing,
                   pause_before_each_command=false)
    # Safety first (will warn, not error)
    validate_file(filename) ## Won't fail but will print warnings
    raw_commands = read_commands(filename)
    commands = splat_commands(raw_commands)
    validate_commands(commands)
    for pos in filter(startswith("PA"), commands)
        validate_position(pos[3:end], config.plot_dimensions) ## Will print warning if any positions are out of bounds
    end

    ps = PlotState(config)
    plot_commands!(ps, commands; pause_before_each_command)
    !ismissing(outfile) && save(outfile, ps.f)
    display(ps)
    return ps
end

function _get_current_pen_color(state)
    if state.pen_is_down && state.i_pen != 0
        return state.config.pen_colors[state.i_pen]
    end
    return DEBUG_PEN_UP_COLOR
end

function _move_to_point!(state::PlotState, pos)
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

# assumes validated commands
# assumes fig's axis has already been constructed via set_up_figure
function plot_commands!(state::PlotState, commands::AbstractVector;
                        pause_before_each_command::Bool)
    for cmd in commands
        if pause_before_each_command
            display(state)
            print("Type any command to do next command `$cmd`")
            readline()
        end
        plot_command!(state, cmd)
    end
    return state
end

function plot_command!(state::PlotState, cmd)
    if cmd == "PD"
        state.pen_is_down = true
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
        # Assume that this is only one point....which is fair, because we've already 
        # run through the validation that would catch this error
        coords = get_coords_from_parameter_str(cmd[3:end])
        for c in coords
            pos = Point2(c)
            _move_to_point!(state, pos)
        end
    else
        @warn "Command `$cmd` is currently unsupported by this visualizer"
    end
    return state
end

end # module PlotHPGL
