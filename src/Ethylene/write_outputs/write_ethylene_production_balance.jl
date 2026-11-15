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
	write_syn_ng_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting input and output balance of synthetic gas resources across different zones with time.
"""
function write_ethylene_production_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfEthylene = inputs["dfEthylene"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Ethylene Production balance for each zone
	dfEthyleneBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 6)
	   	dfTemp1[1,1:size(dfTemp1,2)] = vcat(["Power In", "NG In", "H2 Out", "CH4 Out","LPG Out","Ethylene Out"])
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

        

	   	for t in 1:T
			dfTemp1[t+rowoffset,1] = value.(EP[:eEthylene_Power_RES][t,z])
			dfTemp1[t+rowoffset,2] = value.(EP[:eEthylene_NG_RES][t,z]) 
			dfTemp1[t+rowoffset,3] = value.(EP[:eEthylene_H2_RES][t,z])
			dfTemp1[t+rowoffset,4] = value.(EP[:eEthylene_CH4_RES][t,z])
			dfTemp1[t+rowoffset,5] = value.(EP[:eEthylene_C3plus_RES][t,z])
			dfTemp1[t+rowoffset,6] = sum(value.(EP[:vEthylene_Prod_GF][dfEthylene[(dfEthylene[!,:Zone].==z),:][!,:R_ID],t]))
	   	end

		if z==1
			dfEthyleneBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfEthyleneBalance = hcat(dfEthyleneBalance, dfTemp1)
		end
	end

	for c in 2:size(dfEthyleneBalance,2)
		dfEthyleneBalance[rowoffset,c]=sum(inputs["omega"].*dfEthyleneBalance[(rowoffset+1):size(dfEthyleneBalance,1),c])
	end
	dfEthyleneBalance = DataFrame(dfEthyleneBalance, :auto)
	CSV.write(string(path,sep,"Ethylene_Production_balance.csv"), dfEthyleneBalance, writeheader=false)
end
