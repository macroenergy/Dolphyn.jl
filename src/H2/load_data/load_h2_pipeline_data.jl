"""
GenX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
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
    load_network_data(setup::Dict, path::AbstractString, sep::AbstractString, inputs_nw::Dict)

Function for reading input parameters related to the electricity transmission network
"""
function load_h2_pipeline_data(setup::Dict, path::AbstractString, sep::AbstractString, inputs_nw::Dict)

    # Network zones inputs and Network topology inputs
    pipeline_var = DataFrame(CSV.File(string(path,sep,"H2_Pipelines.csv"), header=true), copycols=true)

    #Number of H2 Pipelines
    inputs_nw["H2_P"]=size(collect(skipmissing(pipeline_var[!,:H2_Pipelines])),1)

    #Find first column of pipe map table
    start = findall(s -> s == "z1", names(pipeline_var))[1]

    #Select pipe map
    pipe_map = pipeline_var[1:inputs_nw["H2_P"], start:start+inputs_nw["Z"]-1]

    #Create pipe number column
    pipe_map[!,:pipe_no] = 1:size(pipe_map,1)
    #Pivot table
    pipe_map = stack(pipe_map, 1:inputs_nw["Z"])
    #Create zone column
    pipe_map[!,:Zone] = parse.(Float64,SubString.(pipe_map[!,:variable],2))
    #Remove redundant rows
    pipe_map = pipe_map[pipe_map[!,:value].!=0,:]

    #Rename column
    colnames_pipe_map = ["pipe_no", "zone_str", "d", "Zone"]
    rename!(pipe_map, Symbol.(colnames_pipe_map))

    inputs_nw["H2_Pipe_Map"] = pipe_map
    
    #pipe_to_zone_map = unstack(pipe_map, :pipe_no, :value, :Zone)

    # Number of pipelines routes in the network
    inputs_nw["H2_P"]=size(collect(skipmissing(pipeline_var[!,:H2_Pipelines])),1)

    #Maximum number of pipelines
    inputs_nw["pH2_Pipe_No_Max"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Max_No_Pipe])))

    #Current number of pipelines
    inputs_nw["pH2_Pipe_No_Curr"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Curr_No_Pipe])))

    #Maxiumum Pipe Flow per Pipe
    inputs_nw["pH2_Pipe_Max_Flow"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Max_Flow_Tonne_Hr_Per_Pipe])))

    #Maximum Pipe Cpacity 
    inputs_nw["pH2_Pipe_Max_Cap"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Max_Cap_Per_Pipe])))

    #Minimum Pipe Capacity
    inputs_nw["pH2_Pipe_Min_Cap"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Min_Cap_Per_pipe])))

    #Cost Per Pipe
    inputs_nw["pH2_Comp_MWh_Pipe"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Comp_MWh_Per_Pipe])))

    #Cost Per Pipe
    inputs_nw["pCH2_Pipe"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Pipe_Cost_Per_Pipe])))

    #Cost Per Compressor
    inputs_nw["pCH2_PipeComp"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Comp_Cost_Per_Pipe])))

    println("H2_pipelines.csv Successfully Read!")

    return inputs_nw
end
