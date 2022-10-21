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
	write_co2_emission_balance_zone(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting co2 balance of resources across different zones.
"""
function write_co2_emission_balance_zone(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfGen = inputs["dfGen"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## CO2 balance for each zone
	dfCO2Balance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 8)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Power Emissions", "H2 Emissions", "DAC Emissions",  "Biorefinery Emissions", "Bioresource Emissions", "DAC Capture", "Biorefinery Capture", "CO2 Pipeline Loss"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))
	   	for t in 1:T
			dfTemp1[t+rowoffset,1] = value(EP[:eEmissionsByZone][z,t])
	     	
			if setup["ModelH2"] == 1
				dfTemp1[t+rowoffset,2] = value(EP[:eH2EmissionsByZone][z,t])
			else
				dfTemp1[t+rowoffset,2] = 0
			end

			dfTemp1[t+rowoffset,3] = value(EP[:eDAC_Emissions_per_zone_per_time][z,t])

			if setup["ModelBIO"] == 1
				dfTemp1[t+rowoffset,4] = value(EP[:eBiorefinery_CO2_emissions_per_zone_per_time][z,t])
				dfTemp1[t+rowoffset,5] = value(EP[:eHerb_biomass_emission_per_zone_per_time][z,t]) + value(EP[:eWood_biomass_emission_per_zone_per_time][z,t])
			else
				dfTemp1[t+rowoffset,4] = 0
				dfTemp1[t+rowoffset,5] = 0
			end

			dfTemp1[t+rowoffset,6]= - value(EP[:eDAC_CO2_Captured_per_zone_per_time][z,t])

			if setup["ModelBIO"] == 1
				dfTemp1[t+rowoffset,7] = - value(EP[:eBIO_CO2_captured_per_zone_per_time][z,t])
			else
				dfTemp1[t+rowoffset,7] = 0
			end

			if Z>=2
				dfTemp1[t+rowoffset,8] = value(EP[:eCO2Loss_Pipes_zt][z,t])
			end

			if setup["ParameterScale"] == 1
				dfTemp1[t+rowoffset,1] = dfTemp1[t+rowoffset,1] * ModelScalingFactor
				dfTemp1[t+rowoffset,2] = dfTemp1[t+rowoffset,2] * ModelScalingFactor
				dfTemp1[t+rowoffset,3] = dfTemp1[t+rowoffset,3] * ModelScalingFactor
				dfTemp1[t+rowoffset,4] = dfTemp1[t+rowoffset,4] * ModelScalingFactor
				dfTemp1[t+rowoffset,5] = dfTemp1[t+rowoffset,5] * ModelScalingFactor
				dfTemp1[t+rowoffset,6] = dfTemp1[t+rowoffset,6] * ModelScalingFactor
				dfTemp1[t+rowoffset,7] = dfTemp1[t+rowoffset,7] * ModelScalingFactor
				dfTemp1[t+rowoffset,8] = dfTemp1[t+rowoffset,8] * ModelScalingFactor
			end
			# DEV NOTE: need to add terms for electricity consumption from H2 balance
	   	end
		if z==1
			dfCO2Balance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfCO2Balance = hcat(dfCO2Balance, dfTemp1)
		end
	end
	for c in 2:size(dfCO2Balance,2)
	   	dfCO2Balance[rowoffset,c]=sum(inputs["omega"].*dfCO2Balance[(rowoffset+1):size(dfCO2Balance,1),c])
	end
	dfCO2Balance = DataFrame(dfCO2Balance, :auto)
	CSV.write(string(path,sep,"Zone_CO2_emission_balance.csv"), dfCO2Balance, writeheader=false)
end
