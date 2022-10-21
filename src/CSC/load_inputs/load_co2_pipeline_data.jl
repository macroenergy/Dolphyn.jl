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
    load_network_data(setup::Dict, path::AbstractString, sep::AbstractString, inputs_co2_nw::Dict)

Function for reading input parameters related to the electricity transmission network
"""
function load_co2_pipeline_data(setup::Dict, path::AbstractString, sep::AbstractString, inputs_co2_nw::Dict)

    # Network zones inputs and Network topology inputs
    co2_pipeline_var = DataFrame(CSV.File(string(path,sep,"CSC_pipelines.csv"), header=true), copycols=true)

    inputs_co2_nw["Z"] = size(findall(s -> (startswith(s, "z")) & (tryparse(Float64, s[2:end]) != nothing), names(co2_pipeline_var)),1)

    #Number of CO2 Pipelines = L
    inputs_co2_nw["CO2_P"]=size(collect(skipmissing(co2_pipeline_var[!,:CO2_Pipelines])),1)

    #Find first column of pipe map table
    start = findall(s -> s == "z1", names(co2_pipeline_var))[1]

    #Select pipe map L x N matrix  where L is number of pipelines and N is number of nodes
    co2_pipe_map = co2_pipeline_var[1:inputs_co2_nw["CO2_P"], start:start+inputs_co2_nw["Z"]-1]

    #Create pipe number column
    co2_pipe_map[!,:pipe_no] = 1:size(co2_pipe_map,1)
    #Pivot table
    co2_pipe_map = stack(co2_pipe_map, 1:inputs_co2_nw["Z"])
    #Create zone column
    co2_pipe_map[!,:Zone] = parse.(Float64,SubString.(co2_pipe_map[!,:variable],2))
    #Remove redundant rows
    co2_pipe_map = co2_pipe_map[co2_pipe_map[!,:value].!=0,:]

    #Rename column
    colnames_co2_pipe_map = ["pipe_no", "zone_str", "d", "Zone"]
    rename!(co2_pipe_map, Symbol.(colnames_co2_pipe_map))

    inputs_co2_nw["CO2_Pipe_Map"] = co2_pipe_map
    

    # Number of pipelines routes in the network
    inputs_co2_nw["CO2_P"]=size(collect(skipmissing(co2_pipeline_var[!,:CO2_Pipelines])),1)

    # Length in miles of each pipeline
    inputs_co2_nw["pCO2_Pipe_length_miles"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:Pipe_length_miles])))

    # Length between two booster compressor stations in miles
    inputs_co2_nw["CO2_len_bw_comp_mile"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:CO2_len_bw_comp_mile])))

    # Number of booster compressors between source and sink
    # DEV NOTE: we should make the total number of compressors if the ratio is less than 1 for a particular line

    #############################################################################################################
    #Check if there should be a "." after inputs_co2_nw["pCO2_Pipe_length_miles"] for division    
    inputs_co2_nw["CO2_no_booster_comp_stations"] = floor.(inputs_co2_nw["pCO2_Pipe_length_miles"]./inputs_co2_nw["CO2_len_bw_comp_mile"]) - ones(length(inputs_co2_nw["CO2_len_bw_comp_mile"]))
    
    #Maximum number of pipelines
    inputs_co2_nw["pCO2_Pipe_No_Max"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:Max_No_Pipe])))

    #Current number of pipelines
    inputs_co2_nw["pCO2_Pipe_No_Curr"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:Existing_No_Pipe])))

    #Maxiumum Pipe Flow per Pipe
    inputs_co2_nw["pCO2_Pipe_Max_Flow"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:Max_Flow_Tonne_p_hr_Per_Pipe])))

    #Maximum Pipeline storage capacity in tonnes per pipe
    inputs_co2_nw["pCO2_Pipe_Max_Cap"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:CO2PipeCap_tonne_per_mile]))) .* inputs_co2_nw["pCO2_Pipe_length_miles"]

    #Minimum Pipeline storage capacity in tonnes per pipe
    inputs_co2_nw["pCO2_Pipe_Min_Cap"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:Min_pipecap_stor_frac]))) .* inputs_co2_nw["pCO2_Pipe_Max_Cap"]

    #Capital Cost Per Pipe using mean cost
    inputs_co2_nw["pCAPEX_CO2_Pipe"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:CO2Pipe_Inv_Cost_per_mile_yr_Mean]))) .* inputs_co2_nw["pCO2_Pipe_length_miles"]
    inputs_co2_nw["pFixed_OM_CO2_Pipe"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:CO2Pipe_Fixed_OM_Cost_per_mile_yr_Mean]))) .* inputs_co2_nw["pCO2_Pipe_length_miles"]
    inputs_co2_nw["pMWh_per_tonne_CO2_Pipe"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:CO2Pipe_Energy_MWh_per_mile_per_tonne_Mean]))) .* inputs_co2_nw["pCO2_Pipe_length_miles"]

    inputs_co2_nw["pLoss_tonne_per_tonne_CO2_Pipe"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:CO2PipeLoss_tonne_per_mile_per_tonne]))) .* inputs_co2_nw["pCO2_Pipe_length_miles"]
    
    #Capital cost associated with booster compressors per pipe= capex per tonne/hour flow rate x pipe max flow rate (tonne/hour) x number of booster compressor stations per pipe route
    inputs_co2_nw["pCAPEX_Comp_CO2_Pipe"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:BoosterCompCapex_per_tonne_p_hr_yr]))).* inputs_co2_nw["pCO2_Pipe_Max_Flow"].*inputs_co2_nw["CO2_no_booster_comp_stations"] 

    #Compression energy requirement Per Pipe  = MWh electricity per tonne of gas flow rate x number of compressor stations enroute a pipeline route
    inputs_co2_nw["pComp_MWh_per_tonne_CO2_Pipe"] = convert(Array{Float64}, collect(skipmissing(co2_pipeline_var[!,:BoosterCompEnergy_MWh_per_tonne]))).* inputs_co2_nw["CO2_no_booster_comp_stations"] 


    println("CO2_pipelines.csv Successfully Read!")

    return inputs_co2_nw
end
