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
	write_co2_storage_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting co2 storage balance of resources across different zones.
"""
function write_co2_storage_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfGen = inputs["dfGen"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## CO2 balance for each zone
	dfCO2StorBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 6)
	   	dfTemp1[1,1:size(dfTemp1,2)] = [ "Power CCS", "H2 CCS", "DAC Capture", "Biorefinery Capture", "CO2 Pipeline Import",
	           "CO2 Storage"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))
	   	for t in 1:T

			dfTemp1[t+rowoffset,1] = value(EP[:ePower_CO2_captured_per_zone_per_time][z,t])

			if setup["ModelH2"] == 1
				dfTemp1[t+rowoffset,2] = value(EP[:eHydrogen_CO2_captured_per_zone_per_time][z,t])
			else
				dfTemp1[t+rowoffset,2] = 0
			end

			dfTemp1[t+rowoffset,3]= value(EP[:eDAC_CO2_Captured_per_zone_per_time][z,t])

			if setup["ModelBIO"] == 1
				dfTemp1[t+rowoffset,4] = value(EP[:eBIO_CO2_captured_per_zone_per_time][z,t])
			else
				dfTemp1[t+rowoffset,4] = 0
			end

			if Z>=2
				dfTemp1[t+rowoffset,5] = value(EP[:ePipeZoneCO2Demand][t,z])
			end

			dfTemp1[t+rowoffset,6] = - value(EP[:eCO2_Injected_per_zone][z,t])

			if setup["ParameterScale"] == 1
				dfTemp1[t+rowoffset,1] = dfTemp1[t+rowoffset,1] * ModelScalingFactor
				dfTemp1[t+rowoffset,2] = dfTemp1[t+rowoffset,2] * ModelScalingFactor
				dfTemp1[t+rowoffset,3] = dfTemp1[t+rowoffset,3] * ModelScalingFactor
				dfTemp1[t+rowoffset,4] = dfTemp1[t+rowoffset,4] * ModelScalingFactor
				dfTemp1[t+rowoffset,5] = dfTemp1[t+rowoffset,5] * ModelScalingFactor
				dfTemp1[t+rowoffset,6] = dfTemp1[t+rowoffset,6] * ModelScalingFactor
			end
			# DEV NOTE: need to add terms for electricity consumption from H2 balance
	   	end
		if z==1
			dfCO2StorBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfCO2StorBalance = hcat(dfCO2StorBalance, dfTemp1)
		end
	end
	for c in 2:size(dfCO2StorBalance,2)
	   	dfCO2StorBalance[rowoffset,c]=sum(inputs["omega"].*dfCO2StorBalance[(rowoffset+1):size(dfCO2StorBalance,1),c])
	end
	dfCO2StorBalance = DataFrame(dfCO2StorBalance, :auto)
	CSV.write(string(path,sep,"Zone_CO2_storage_balance.csv"), dfCO2StorBalance, writeheader=false)
end
