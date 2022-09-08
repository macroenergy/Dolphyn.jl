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

function write_co2_pipeline_expansion(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	L = inputs["CO2_P"]     # Number of CO2 pipelines
    
	
	transcap = zeros(L) # Transmission network reinforcements in tonne/hour
	for i in 1:L
		if setup["ParameterScale"]==1
			Existing_Trans_Cap[i] = (inputs["pCO2_Pipe_Max_Flow"][i].*inputs["pCO2_Pipe_No_Curr"][i])*ModelScalingFactor
			transcap[i] = ((value.(EP[:vCO2NPipe][i]) -inputs["pCO2_Pipe_No_Curr"][i]).*inputs["pCO2_Pipe_Max_Flow"][i])*ModelScalingFactor
		else
			Existing_Trans_Cap[i] = (inputs["pCO2_Pipe_Max_Flow"][i].*inputs["pCO2_Pipe_No_Curr"][i])
			transcap[i] = (value.(EP[:vCO2NPipe][i]) -inputs["pCO2_Pipe_No_Curr"][i]).*inputs["pCO2_Pipe_Max_Flow"][i]
		end
	end
	dfTransCap = DataFrame(
	Line = 1:L, 
	Existing_Trans_Capacity = convert(Array{Union{Missing,Float32}}, Existing_Trans_Cap), 
    New_Trans_Capacity = convert(Array{Union{Missing,Float32}}, transcap)
	)
	CSV.write(string(path,sep,"CSC_co2_pipeline_expansion.csv"), dfTransCap)
end
