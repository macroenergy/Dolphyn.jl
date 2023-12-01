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
    write_co2_spur_inflow_storage_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting CO2 storage and spur pipeline inflow balance across different zones with time.
"""

function write_co2_spur_inflow_storage_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
    S = inputs["S"]     # Number of CO2 Storage Sites

	## CO2 balance for each zone
	dfCO2StorBalance = Array{Any}
	rowoffset=3
	for s in 1:S
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 2)
	   	dfTemp1[1,1:size(dfTemp1,2)] = [ "CO2 Pipeline Inflow", "CO2 Storage"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([s],size(dfTemp1,2))
	   	for t in 1:T

			dfTemp1[t+rowoffset,1] = value(EP[:ePipeZoneCO2Demand_Inflow_Spur][t,s])

            dfTemp1[t+rowoffset, 2] = -value(EP[:eCO2_Injected_per_zone][s,t])

            if setup["ParameterScale"] == 1
                dfTemp1[t+rowoffset,1] = dfTemp1[t+rowoffset,1] * ModelScalingFactor
				dfTemp1[t+rowoffset,2] = dfTemp1[t+rowoffset,2] * ModelScalingFactor
            end
        end
 
		if s==1
			dfCO2StorBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfCO2StorBalance = hcat(dfCO2StorBalance, dfTemp1)
		end
	end
	for c in 2:size(dfCO2StorBalance,2)
	   	dfCO2StorBalance[rowoffset,c]=sum(inputs["omega"].*dfCO2StorBalance[(rowoffset+1):size(dfCO2StorBalance,1),c])
	end
	dfCO2StorBalance = DataFrame(dfCO2StorBalance, :auto)
	CSV.write(string(path,sep,"CSC_spur_inflow_storage_balance.csv"), dfCO2StorBalance, writeheader=false)
end
