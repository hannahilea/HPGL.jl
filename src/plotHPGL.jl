
module PlotHPGL

using CairoMakie
using CairoMakie.Colors
using HPGL: read_commands, get_coords_from_parameter_str, get_pen_index, validate_file,
            validate_commands

CairoMakie.activate!(; type="svg")

export plot_file, plot!, plot_command!, plot_commands!, PlotterConfig, PlotState

const DEFAULT_PLOT_SIZE = (10300, 7650)
const DEBUG_PEN_UP_COLOR = colorant"purple"
const MISSING_COLOR = alphacolor(colorant"white", 0)
const DEFAULT_PEN_COLORS = [alphacolor(RGB(0, 0, 0), 0.8),
                            alphacolor(colorant"red2", 0.8),
                            alphacolor(colorant"gold1", 0.8),
                            alphacolor(colorant"mediumblue", 0.8)]

Base.@kwdef struct PlotterConfig
    plot_dimensions = DEFAULT_PLOT_SIZE
    pen_colors = DEFAULT_PEN_COLORS
    linewidth = 1.5 # pen thickness
    debug = false
end

Base.@kwdef mutable struct PlotState
    config::PlotterConfig
    figAxPlot::Any
    points::Any
    colors::Any
    i_pen::Int = 0
    pen_is_down::Bool = false
end

function PlotState(config)
    points = Observable([Point2(0, 0)])
    colors = Observable([MISSING_COLOR])
    figAxPlot = lines(points; color=colors, size=config.plot_dimensions, config.linewidth,
                      axis=(;
                            limits=(-10, first(config.plot_dimensions) + 10, -10,
                                    last(config.plot_dimensions) + 10)))
    hidedecorations!(figAxPlot.axis)
    config.debug || hidespines!(figAxPlot.axis)  # hide the frame
    return PlotState(; figAxPlot, points, colors, config)
end

Base.display(s::PlotState) = Base.display(s.figAxPlot)

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

function plot_file(filename; config=PlotterConfig(), outfile=missing)
    # Safety first (will warn, not error)
    validate_file(filename) ## Won't fail but will print warnings
    raw_commands = read_commands(filename)
    commands = splat_commands(raw_commands)
    validate_commands(commands)
    for pos in filter(startswith("PA"), commands)
        validate_position(pos[3:end], config.plot_dimensions) ## Will print warning if any positions are out of bounds
    end

    ps = PlotState(config)
    plot_commands!(ps, commands)
    !ismissing(outfile) && save(outfile, ps.figAxPlot.figure)
    return ps
end

function _get_current_pen_color(state)
    if state.pen_is_down
        return state.i_pen == 0 ? MISSING_COLOR : state.config.pen_colors[state.i_pen]
    end
    return state.config.debug ? DEBUG_PEN_UP_COLOR : MISSING_COLOR
end

function _move_to_point!(state::PlotState, pos)
    isnothing(validate_position(pos, state.config.plot_dimensions)) || return nothing
    push!(state.points[], pos)
    push!(state.colors[], _get_current_pen_color(state))
    notify(state.points)
    notify(state.colors)
    return state
end

# assumes validated commands
# assumes fig's axis has already been constructed via set_up_figure
function plot_commands!(state::PlotState, commands::AbstractVector)
    for cmd in commands
        plot_command!(state, cmd)
    end
    return state.figAxPlot.figure
end

function plot_command!(state::PlotState, cmd)
    if cmd == "PD"
        # If pen is already down, putting it down does nothing
        if !state.pen_is_down
            state.pen_is_down = true
            _move_to_point!(state, last(state.points[]))
        end
    elseif cmd == "PU"
        # If pen is already up, putting it up does nothing
        if state.pen_is_down
            state.pen_is_down = false
            _move_to_point!(state, last(state.points[]))
        end
    elseif cmd == "IN"
        # do nothing...
    elseif startswith(cmd, "SP")
        _move_to_point!(state, (0, 0))
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
    return state.figAxPlot.figure
end

end # module PlotHPGL
