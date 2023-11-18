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
    write_co2_spur_pipeline_expansion(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

This file is responsible for writing the pipeline capacity expansion related to spur pipelines
"""
function write_co2_spur_pipeline_expansion(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	L = inputs["Spur_CO2_P"]     # Number of CO2 pipelines
    
	Existing_Trans_Cap = zeros(L) # Transmission network reinforcements in tonne/hour
	transcap = zeros(L) # Transmission network reinforcements in tonne/hour
	Pipes = zeros(L) # Transmission network reinforcements in tonne/hour
	Fixed_Cost = zeros(L)
	#Comp_Cost = zeros(L)



	for i in 1:L
		Existing_Trans_Cap = inputs["Spur_pCO2_Pipe_Max_Flow"].*inputs["Spur_pCO2_Pipe_No_Curr"]
		transcap[i] = (value.(EP[:vCO2NPipe_Spur][i]) -inputs["Spur_pCO2_Pipe_No_Curr"][i]).*inputs["Spur_pCO2_Pipe_Max_Flow"][i]
		Pipes[i] = value.(EP[:vCO2NPipe_Spur][i])
		Fixed_Cost[i] = value.(EP[:eCO2NPipeNew_spur][i]) * inputs["Spur_pCAPEX_CO2_Pipe"][i] + value.(EP[:vCO2NPipe_Spur][i]) * inputs["Spur_pFixed_OM_CO2_Pipe"][i]
		#Comp_Cost[i] = value.(EP[:eCO2NPipeNew][i]) * inputs["pCAPEX_Comp_CO2_Pipe"][i]
	end

	dfTransCap = DataFrame(
	Line = 1:L,
	Existing_Trans_Capacity = convert(Array{Union{Missing,Float32}}, Existing_Trans_Cap),
    New_Trans_Capacity = convert(Array{Union{Missing,Float32}}, transcap),
	Total_Pipes = convert(Array{Union{Missing,Float32}}, Pipes),
	Fixed_Cost_Pipes = convert(Array{Union{Missing,Float32}}, Fixed_Cost),
	#Comp_Cost_pipes = convert(Array{Union{Missing,Float32}}, Comp_Cost),
	)

	CSV.write(string(path,sep,"CSC_spur_pipeline_expansion.csv"), dfTransCap)
end
