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

function write_liquid_fuel_demand_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfSynFuels= inputs["dfSynFuels"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	## SynFuel balance for each zone
	dfSFBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 3)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Syn_Fuel_Generation", "Conventional_Fuel_Demand", "Demand"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))
	   	for t in 1:T
	     	dfTemp1[t+rowoffset,1]= sum(value.(EP[:vSFProd][dfSynFuels[(dfSynFuels[!,:Zone].==z),:][!,:R_ID],t]))
	     	dfTemp1[t+rowoffset,2] = value.(EP[:vConvLFDemand][t,z])
			dfTemp1[t+rowoffset,3] = -inputs["Liquid_Fuels_D"][t,z]
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
	CSV.write(string(path,sep,"LF_balance.csv"), dfSFBalance, writeheader=false)
end
