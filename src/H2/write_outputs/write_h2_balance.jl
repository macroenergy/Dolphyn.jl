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

function write_h2_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfH2Gen = inputs["dfH2Gen"]
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	H2_SEG = inputs["H2_SEG"] # Number of load curtailment segments

	println(Z)
	H2_FLEX = inputs["H2_FLEX"]
	## Power balance for each zone
	dfPowerBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 7)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Generation", 
	           "Flexible_Demand_Defer", "Flexible_Demand_Stasify",
               "Nonserved_Energy",
			   "Transmission_NetExport", "Transmission_Losses",
	           "Demand"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))
	   	for t in 1:T
	     	dfTemp1[t+rowoffset,1]= sum(value.(EP[:vH2Gen][dfH2Gen[(dfH2Gen[!,:H2_FLEX].!=1) .&  (dfH2Gen[!,:Zone].==z),:][!,:R_ID],t])) 
	     	dfTemp1[t+rowoffset,2] = 0
            dfTemp1[t+rowoffset,3] = 0
	     	if !isempty(intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_FLEX))
	     	    dfTemp1[t+rowoffset,2] = sum(value.(EP[:vH2_CHARGE_FLEX][y,t]) for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_FLEX))
                dfTemp1[t+rowoffset,3] = -sum(value.(EP[:vH2Gen][dfH2Gen[(dfH2Gen[!,:H2_FLEX].>=1) .&  (dfH2Gen[!,:Zone].==z),:][!,:R_ID],t]))
	     	end
	     	
	     	dfTemp1[t+rowoffset,4] = value(EP[:vH2NSE][1,t,z])
	     	dfTemp1[t+rowoffset,5] = 0
	     	dfTemp1[t+rowoffset,6] = 0
		
		# if Z>=2
		# 	dfTemp1[t+rowoffset,5] = value(EP[:ePowerBalanceNetExportFlows][t,z])
		# 	dfTemp1[t+rowoffset,6] = -1/2 * value(EP[:eLosses_By_Zone][z,t])
		# end
	     	dfTemp1[t+rowoffset,7] = -inputs["H2_D"][t,z]

			
	   	end
		if z==1
			dfPowerBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfPowerBalance = hcat(dfPowerBalance, dfTemp1)
		end
	end
	for c in 2:size(dfPowerBalance,2)
	   	dfPowerBalance[rowoffset,c]=sum(inputs["omega"].*dfPowerBalance[(rowoffset+1):size(dfPowerBalance,1),c])
	end
	dfPowerBalance = DataFrame(dfPowerBalance, :auto)
	CSV.write(string(path,sep,"h2_balance.csv"), dfPowerBalance, writeheader=false)
end
