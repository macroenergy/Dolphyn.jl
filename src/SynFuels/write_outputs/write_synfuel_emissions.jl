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

function write_synfuel_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfSynFuels= inputs["dfSynFuels"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	NSFByProd = inputs["NSFByProd"]

	## SynFuel balance for each zone
	dfSFBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 4 + NSFByProd)
		byprodHead = "ByProd_Cons_Emissions_" .* string.(collect(1:NSFByProd))
	   	dfTemp1[1,1:size(dfTemp1,2)] = vcat(["CO2_In","SF_Prod_Emissions", "SF_Cons_Emissions", "Conv_Fuel_Cons_Emissions"], byprodHead)
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

	   	for t in 1:T
			dfTemp1[t+rowoffset,1]=value.(EP[:eSynFuelCO2ConsNoCommit][t,z])
			dfTemp1[t+rowoffset,2]=value.(EP[:eSynFuelProdEmissionsByZone][z,t])
			dfTemp1[t+rowoffset,3]=value.(EP[:eSyn_Fuels_Cons_CO2_Emissions_By_Zone][z,t])
			dfTemp1[t+rowoffset,4]=value.(EP[:eLiquid_Fuels_CO2_Emissions_By_Zone][z,t])

			for b in 1:NSFByProd
				dfTemp1[t+rowoffset, 4 + b] = sum(value.(EP[:eByProdConsCO2EmissionsByZoneB][b,z,t]))
			end

	   	end

		if z==1
			dfSFBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfSFBalance = hcat(dfSFBalance, dfTemp1)
		end
	end
	for c in 2:size(dfSFBalance,2)
		dfSFBalance[rowoffset,c]=sum(inputs["omega"].*dfSFBalance[(rowoffset+1):size(dfSFBalance,1),c])
	end
	dfSFBalance = DataFrame(dfSFBalance, :auto)
	CSV.write(string(path,sep,"Syn_Fuel_Emissions_Balance.csv"), dfSFBalance, writeheader=false)
end
