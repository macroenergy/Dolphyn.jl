"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
    load_h2_pipeline_data(setup::Dict, path::AbstractString, sep::AbstractString, inputs_nw::Dict)

Function for reading input parameters related to the hydrogen transmission network via pipelines.
"""
function load_h2_pipeline_data(
    setup::Dict,
    path::AbstractString,
    sep::AbstractString,
    inputs_nw::Dict,
)

    Zones = inputs_nw["Zones"]
    Z = inputs_nw["Z"]

    # Network zones inputs and Network topology inputs
    pipeline_var = DataFrame(
        CSV.File(joinpath(path, "HSC_pipelines.csv"), header = true),
        copycols = true,
    )

    # Filter pipeline by zone
    if "Start_Zone" in names(pipeline_var)        
        pipeline_var = filter(row -> (row.Start_Zone in Zones && row.End_Zone in Zones), pipeline_var)
    else
        @warn "Filtering zones not implemented when using matrix-style pipeline input"
    end

    # Number of H2 Pipelines = L
    inputs_nw["H2_P"] = size(collect(skipmissing(pipeline_var[!, :H2_Pipelines])), 1)
    L = inputs_nw["H2_P"]

    pipe_map = load_h2_network_map(pipeline_var, Z, L, Zones)

    inputs_nw["H2_Pipe_Map"] = pipe_map

    # Number of pipelines routes in the network
    inputs_nw["H2_P"] = size(collect(skipmissing(pipeline_var[!, :H2_Pipelines])), 1)

    # Length in miles of each pipeline
    inputs_nw["pPipe_length_miles"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :Pipe_length_miles])))

    # Length between two booster compressor stations in miles
    inputs_nw["len_bw_comp_mile"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :len_bw_comp_mile])))

    # Number of booster compressors between source and sink
    # DEV NOTE: we should make the total number of compressors if the ratio is less than 1 for a particular line
    inputs_nw["no_booster_comp_stations"] =
        inputs_nw["pPipe_length_miles"] ./ inputs_nw["len_bw_comp_mile"]
    # floor.(inputs_nw["pPipe_length_miles"] ./ inputs_nw["len_bw_comp_mile"])
    #Maximum number of pipelines
    inputs_nw["pH2_Pipe_No_Max"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :Max_No_Pipe])))

    #Current number of pipelines
    inputs_nw["pH2_Pipe_No_Curr"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :Existing_No_Pipe])))

    #Maxiumum Pipe Flow per Pipe
    inputs_nw["pH2_Pipe_Max_Flow"] = convert(
        Array{Float64},
        collect(skipmissing(pipeline_var[!, :Max_Flow_Tonne_p_Hr_Per_Pipe])),
    )

    #Maximum Pipeline storage capacity in tonnes per pipe
    inputs_nw["pH2_Pipe_Max_Cap"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :H2PipeCap_tonne_per_mile])),
        ) .* inputs_nw["pPipe_length_miles"]

    #Minimum Pipeline storage capacity in tonnes per pipe
    inputs_nw["pH2_Pipe_Min_Cap"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :Min_pipecap_stor_frac])),
        ) .* inputs_nw["pH2_Pipe_Max_Cap"]

    #Capital Cost Per Pipe
    inputs_nw["pCAPEX_H2_Pipe"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :H2Pipe_Inv_Cost_per_mile_yr])),
        ) .* inputs_nw["pPipe_length_miles"]

    #Capital cost associated with booster compressors per pipe= capex per tonne/hour flow rate x pipe max flow rate (tonne/hour) x number of booster compressor stations per pipe route
    inputs_nw["pCAPEX_Comp_H2_Pipe"] =
        inputs_nw["pH2_Pipe_Max_Flow"] .* (
            convert(
                Array{Float64},
                collect(skipmissing(pipeline_var[!, :H2PipeCompCapex])),
            ) .+
            inputs_nw["no_booster_comp_stations"] .* convert(
                Array{Float64},
                collect(skipmissing(pipeline_var[!, :BoosterCompCapex_per_tonne_p_hr_yr])),
            )
        )

    #Compression energy requirement Per Pipe  = MWh electricity per tonne of gas flow rate x number of compressor stations enroute a pipeline route
    inputs_nw["pComp_MWh_per_tonne_Pipe"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :H2PipeCompEnergy]))
        ) .+ 
        inputs_nw["no_booster_comp_stations"] .* convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :BoosterCompEnergy_MWh_per_tonne])),
        )

    print_and_log("HSC_pipelines.csv Successfully Read!")

    return inputs_nw
end

@doc raw"""
    load_h2_network_map_from_list(network_var::DataFrame, Z, L, list_columns)

Loads the H2 network map from a list-style interface
```
..., H2_Pipelines, Start_Zone, End_Zone, ...
                 1,           1,                2,
                 2,           1,                3,
```
"""
function load_h2_network_map_from_list(pipeline_var::DataFrame, Z, L, list_columns, Zones)
    start_col, end_col = list_columns
    pipe_map = zeros(Int64, L, Z)
    start_zones = collect(skipmissing(pipeline_var[!, start_col]))
    end_zones = collect(skipmissing(pipeline_var[!, end_col]))
    for l in 1:L
        z_start = indexin([pipeline_var[!, :Start_Zone][l]], Zones)[1]
        z_end = indexin([pipeline_var[!, :End_Zone][l]], Zones)[1]
        pipe_map[l, z_start] = 1
        pipe_map[l, z_end] = -1
    end
    pipe_map = DataFrame(pipe_map, Symbol.(Zones))
    
    ## Create pipe number column
    pipe_map[!, :pipe_no] = 1:size(pipe_map, 1)
    ## Pivot table
    pipe_map = stack(pipe_map, Zones)
    ## Remove redundant rows
    pipe_map = pipe_map[pipe_map[!, :value].!=0, :]
    ## Rename column
    colnames_pipe_map = ["pipe_no", "Zone", "d"]
    rename!(pipe_map, Symbol.(colnames_pipe_map))
    pipe_map[!, :zone_str] = pipe_map[!, :Zone]
    #TODO: Avoid type error of pipe_map
    ## Check input zone type - Zone column should be Int64 in ```h2_pipeline```, input zone list should be Int64
    if typeof(Zones[1]) == Int64
        pipe_map[!, :Zone] = [parse(Int64, x) for x in pipe_map[!, :Zone]]
    end
    return pipe_map
end

@doc raw"""
    load_h2_network_map_from_matrix(network_var::DataFrame, Z, L)

Loads the H2 network map from a matrix-style interface
```
..., H2_Pipelines, z1, z2, z3, ...
                 1,  1, -1,  0,
                 2,  1,  0, -1,
```
This is equivalent to the list-style interface where the zone zN with entry +1 is the
starting node of the line and the zone with entry -1 is the ending node of the line.
"""
function load_h2_network_map_from_matrix(pipeline_var::DataFrame, Z, L)
    # Find first column of pipe map table
    start = findall(s -> s == "z1", names(pipeline_var))[1]
    # Select pipe map L x N matrix  where L is number of pipelines and N is number of nodes
    pipe_map = pipeline_var[1:L, start:start+Z-1]
    # Create pipe number column
    pipe_map[!, :pipe_no] = 1:size(pipe_map, 1)
    # Pivot table
    pipe_map = stack(pipe_map, 1:Z)
    # Create zone column
    pipe_map[!, :Zone] = parse.(Float64, SubString.(pipe_map[!, :variable], 2))
    #Remove redundant rows
    pipe_map = pipe_map[pipe_map[!, :value].!=0, :]
    #Rename column
    colnames_pipe_map = ["pipe_no", "zone_str", "d", "Zone"]
    rename!(pipe_map, Symbol.(colnames_pipe_map))
    return pipe_map
end

function load_h2_network_map(pipeline_var::DataFrame, Z, L, Zones)
    columns = names(pipeline_var)

    list_columns = ["Start_Zone", "End_Zone"]
    has_pipeline_list = all([c in columns for c in list_columns])

    zones_as_strings = ["z" * string(i) for i in 1:Z]
    has_pipeline_matrix =  all([c in columns for c in zones_as_strings])

    instructions = """The H2 pipeline network should be specified in the form of a matrix
           (with columns z1, z2, ... zN) or in the form of lists (with Start_Zone, End_Zone),
           but not both. See the documentation for examples."""

    println(has_pipeline_list)
    println(has_pipeline_matrix)

    if has_pipeline_list && has_pipeline_matrix
        error("two types of transmission network map were provided.\n" * instructions)
    elseif !(has_pipeline_list || has_pipeline_matrix)
        error("no transmission network map was detected.\n" * instructions)
    elseif has_pipeline_list
        pipe_map = load_h2_network_map_from_list(pipeline_var, Z, L, list_columns, Zones)
    elseif has_pipeline_matrix
        pipe_map = load_h2_network_map_from_matrix(pipeline_var, Z, L)
    end
    return pipe_map
end