"""
CaptureX: An Configurable Capacity Expansion Model
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

function write_co2_storage_injection_power_consumption(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfCO2Storage = inputs["dfCO2Storage"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Carbon balance for each zone
	dfCO2InjectionConsumption = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 1)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Power Consumption"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))
	   	for t in 1:T
	     	dfTemp1[t+rowoffset,1]= sum(value.(EP[:vPower_CO2_Injection][dfCO2Storage[(dfCO2Storage[!,:Zone].==z),:][!,:R_ID],t]))
	   	end

		if z==1
			dfCO2InjectionConsumption =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfCO2InjectionConsumption = hcat(dfCO2InjectionConsumption, dfTemp1)
		end
	end
	for c in 2:size(dfCO2InjectionConsumption,2)
		dfCO2InjectionConsumption[rowoffset,c]=sum(inputs["omega"].*dfCO2InjectionConsumption[(rowoffset+1):size(dfCO2InjectionConsumption,1),c])
	end
	dfCO2InjectionConsumption = DataFrame(dfCO2InjectionConsumption, :auto)
	CSV.write(string(path,sep,"CSC_co2_storage_injection_power_consumption_zone.csv"), dfCO2InjectionConsumption, writeheader=false)
end
