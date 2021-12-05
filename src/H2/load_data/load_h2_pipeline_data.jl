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
#DEV NOTE:  add DC power flow related parameter inputs in a subsequent commit
function load_h2_pipeline_data(setup::Dict, path::AbstractString, sep::AbstractString, inputs_nw::Dict)

    # Network zones inputs and Network topology inputs
    pipeline_var = DataFrame(CSV.File(string(path,sep,"H2_pipelines.csv"), header=true), copycols=true)

    # Number of lines in the network
    inputs_nw["H2_P"]=size(collect(skipmissing(pipeline_var[!,:H2_Pipelines])),1)

    # Topology of the network source-sink matrix
    start = findall(s -> s == "z1", names(pipeline_var))[1]
    inputs_nw["pH2_Pipe_Map"] = Matrix{Float64}(pipeline_var[1:inputs_nw["H2_P"],start:start+inputs_nw["Z"]-1])

    inputs_nw["pH2_Pipe_Max"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Max_No_Pipe])))

    inputs_nw["pH2PipeCap"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Tonne_Hr_Per_Pipe])))

    # Line percentage Loss - valid for case when modeling losses as a fixed percent of absolute value of power flows
    inputs_nw["pH2Pipe_Distance"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:distance_mile])))

    # Number of compressors in a pipe
    inputs_nw["pH2Pipe_Comp_Per_Mile"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:compressor_per_mile])))

    # Compressor cost $/compressor / tonne /hr
    inputs_nw["pCH2Pipe_Comp_Per_Comp_Tonne_Hr"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:BoosterCompCapex_per_tonne_hr])))

    # Compressor energy consumption / comp / tonne/hr
    inputs_nw["pH2Pipe_MWh_Per_Comp_Tonne_Hr"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:BoosterCompEnergy_MWh_per_tonne])))

    # #Max pipeline capacity
    # inputs_nw["p_H2_Pipe_Max_Possible"] = zeros(Float64, inputs_nw["H2_P"])
        
    # if setup["H2PipelineExpansion"]==1

    #         # Read between zone network reinforcement costs per peak MW of capacity added
    #         inputs_nw["pC_H2_Pipe_Expansion"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Pipe_Expansion_Cost_per_Tonne_Hryr])))
    #         # Maximum reinforcement allowed in MW
    #         #NOTE: values <0 indicate no expansion possible
    #         inputs_nw["pMax_H2_Pipe_Expansion"] = convert(Array{Float64}, collect(skipmissing(pipeline_var[!,:Pipe_Max_Expansion_Tonne_Hr])))

    #     for l in 1:inputs_nw["H2_P"]
    #         if inputs_nw["pMax_H2_Pipe_Expansion"][l] > 0
    #             inputs_nw["p_H2_Pipe_Max_Possible"][l] = inputs_nw["pH2_Pipe_Max"][l] + inputs_nw["pMax_H2_Pipe_Expansion"][l]
    #         else
    #             inputs_nw["p_H2_Pipe_Max_Possible"][l] = inputs_nw["pH2_Pipe_Max"][l]
    #         end
    #     end
    # else
    #     inputs_nw["p_H2_Pipe_Max_Possible"] = inputs_nw["pH2_Pipe_Max"]
    # end

    # if setup["H2PipelineExpansion"] == 1
    #     # Network lines and zones that are expandable have non-negative maximum reinforcement inputs
    #     inputs_nw["EXPANSION_H2_Pipes"] = findall(inputs_nw["pMax_H2_Pipe_Expansion"].>=0)
    #     inputs_nw["NO_EXPANSION_H2_Pipes"] = findall(inputs_nw["pMax_H2_Pipe_Expansion"].<0)
    #end

    println("H2_pipelines.csv Successfully Read!")

    return inputs_nw, pipeline_var
end
