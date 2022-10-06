"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021, Massachusetts Institute of Technology and Peking University
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
    load_h2_pipeline_data(path::AbstractString, setup::Dict, inputs::Dict)

Function for reading input parameters related to the hydrogen transmission network
"""
function load_h2_pipeline_data(path::AbstractString, setup::Dict, inputs::Dict)

    # Network zones inputs and Network topology inputs
    pipeline_var = DataFrame(
        CSV.File(joinpath(path, "HSC_pipelines.csv"), header = true),
        copycols = true,
    )

    # Number of zones in the network
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    # Filter pipelines in modeled zones
    pipeline_var = filter(row -> (row.StartZone in ["z$z" for z in Zones] && row.EndZone in ["z$z" for z in Zones]), pipeline_var)

    # Number of H2 Pipelines
    inputs["H2_P"] = size(collect(skipmissing(pipeline_var[!, :H2_Pipelines])), 1)
    L = inputs["H2_P"]

    # Topology of the pipeline network source-sink matrix
    pipe_map = zeros(Int64, L, Z)
    for l in 1:L
        z_start = parse(Int32, pipeline_var[!, :StartZone][l][2:end])
        z_end = parse(Int32, pipeline_var[!, :EndZone][l][2:end])
        pipe_map[l, z_start] = 1
        pipe_map[l, z_end] = -1
    end

    pipe_map = DataFrame(pipe_map, :auto)

    # Create pipe number column
    pipe_map[!, :pipe_no] = 1:size(pipe_map, 1)

    # Pivot table
    pipe_map = stack(pipe_map, Zones)

    # Create zone column
    pipe_map[!, :Zone] = parse.(Int32, SubString.(pipe_map[!, :variable], 2))

    # Remove redundant rows
    pipe_map = pipe_map[pipe_map[!, :value].!=0, :]

    # Rename column
    colnames_pipe_map = ["pipe_no", "zone_str", "d", "Zone"]
    rename!(pipe_map, Symbol.(colnames_pipe_map))

    inputs["H2_Pipe_Map"] = pipe_map

    # Length in miles of each pipeline
    inputs["pPipe_length_miles"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :Pipe_length_miles])))

    # Length between two booster compressor stations in miles
    inputs["len_bw_comp_mile"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :len_bw_comp_mile])))

    # Number of booster compressors between source and sink
    # DEV NOTE: we should make the total number of compressors if the ratio is less than 1 for a particular line
    inputs["no_booster_comp_stations"] =
        inputs["pPipe_length_miles"] ./ inputs["len_bw_comp_mile"]
    # floor.(inputs["pPipe_length_miles"] ./ inputs["len_bw_comp_mile"])
    #Maximum number of pipelines
    inputs["pH2_Pipe_No_Max"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :Max_No_Pipe])))

    #Current number of pipelines
    inputs["pH2_Pipe_No_Curr"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :Existing_No_Pipe])))

    #Maxiumum Pipe Flow per Pipe
    inputs["pH2_Pipe_Max_Flow"] = convert(
        Array{Float64},
        collect(skipmissing(pipeline_var[!, :Max_Flow_Tonne_p_Hr_Per_Pipe])),
    )

    #Maximum Pipeline storage capacity in tonnes per pipe
    inputs["pH2_Pipe_Max_Cap"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :H2PipeCap_tonne_per_mile])),
        ) .* inputs["pPipe_length_miles"]

    #Minimum Pipeline storage capacity in tonnes per pipe
    inputs["pH2_Pipe_Min_Cap"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :Min_pipecap_stor_frac])),
        ) .* inputs["pH2_Pipe_Max_Cap"]

    #Capital Cost Per Pipe
    inputs["pCAPEX_H2_Pipe"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :H2Pipe_Inv_Cost_per_mile_yr])),
        ) .* inputs["pPipe_length_miles"]

    #Capital cost associated with booster compressors per pipe= capex per tonne/hour flow rate x pipe max flow rate (tonne/hour) x number of booster compressor stations per pipe route
    inputs["pCAPEX_Comp_H2_Pipe"] =
        inputs["pH2_Pipe_Max_Flow"] .* (
            convert(
                Array{Float64},
                collect(skipmissing(pipeline_var[!, :H2PipeCompCapex])),
            ) .+
            inputs["no_booster_comp_stations"] .* convert(
                Array{Float64},
                collect(skipmissing(pipeline_var[!, :BoosterCompCapex_per_tonne_p_hr_yr])),
            )
        )

    #Compression energy requirement Per Pipe  = MWh electricity per tonne of gas flow rate x number of compressor stations enroute a pipeline route
    inputs["pComp_MWh_per_tonne_Pipe"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :H2PipeCompEnergy]))
        ) .+
        inputs["no_booster_comp_stations"] .* convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :BoosterCompEnergy_MWh_per_tonne])),
        )

    println("HSC_pipelines.csv Successfully Read!")

    return inputs
end
