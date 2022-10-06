"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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
	write_h2_balance(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

"""
function write_h2_balance(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

	dfSynGen = inputs["dfSynGen"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	SYN_FLEX = inputs["SYN_FLEX"] # Set of demand flexibility resources
	SYN_STOR_ALL = inputs["SYN_STOR_ALL"] # Set of H2 storage resources
	## Hydrogen balance for each zone
	dfSynBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 10)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Generation",
	           "Flexible_Demand_Defer", "Flexible_Demand_Satisfy",
			   "Storage Discharging", "Storage Charging",
               "Non_served_Energy",
			   "Syn_Pipeline_Import/Export",
			   "Syn_Truck_Import/Export",
	           "Demand"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))
	   	for t in 1:T
	     	dfTemp1[t+rowoffset,1]= sum(value.(EP[:vH2Gen][dfSynGen[(dfSynGen[!,:SYN_GEN_TYPE].>0) .&  (dfSynGen[!,:Zone].==z),:][!,:R_ID],t]))
	     	dfTemp1[t+rowoffset,2] = 0
            dfTemp1[t+rowoffset,3] = 0
			dfTemp1[t+rowoffset,4] = 0
            dfTemp1[t+rowoffset,5] = 0
	     	if !isempty(intersect(dfSynGen[dfSynGen.Zone.==z,:R_ID],SYN_FLEX))
	     	    dfTemp1[t+rowoffset,2] = sum(value.(EP[:vH2_CHARGE_FLEX][y,t]) for y in intersect(dfSynGen[dfSynGen.Zone.==z,:R_ID],SYN_FLEX))
                dfTemp1[t+rowoffset,3] = -sum(value.(EP[:vH2Gen][dfSynGen[(dfSynGen[!,:SYN_FLEX].>=1) .&  (dfSynGen[!,:Zone].==z),:][!,:R_ID],t]))
	     	end
			 if !isempty(intersect(dfSynGen[dfSynGen.Zone.==z,:R_ID],SYN_STOR_ALL))
				dfTemp1[t+rowoffset,4] = sum(value.(EP[:vH2Gen][y,t]) for y in intersect(dfSynGen[dfSynGen.Zone.==z,:R_ID],SYN_STOR_ALL))
			   dfTemp1[t+rowoffset,5] = -sum(value.(EP[:vH2_CHARGE_STOR][y,t]) for y in intersect(dfSynGen[dfSynGen.Zone.==z,:R_ID],SYN_STOR_ALL))
			end

	     	dfTemp1[t+rowoffset,6] = value(EP[:vH2NSE][1,t,z])

			if setup["ModelH2Pipelines"] == 1
			 	dfTemp1[t+rowoffset,7] = value.(EP[:ePipeZoneDemand][t,z])
			else
				dfTemp1[t+rowoffset,7] = 0
			end


			if setup["ModelH2Trucks"] == 1
				dfTemp1[t+rowoffset,8] = value.(EP[:eH2TruckFlow][t,z])
			else
				dfTemp1[t+rowoffset,8] = 0
			end

			if setup["ModelH2G2P"] == 1
				dfTemp1[t+rowoffset,9] = sum(value.(EP[:vH2G2P][dfH2G2P[(dfH2G2P[!,:Zone].==z),:][!,:R_ID],t]))
			else
				dfTemp1[t+rowoffset,9] = 0
			end

	     	dfTemp1[t+rowoffset,10] = -inputs["H2_D"][t,z]
	   	end

		if z == 1
			dfSynBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfSynBalance = hcat(dfSynBalance, dfTemp1)
		end
	end

	for c in 2:size(dfSynBalance,2)
		dfSynBalance[rowoffset,c]=sum(inputs["omega"].*dfSynBalance[(rowoffset+1):size(dfSynBalance,1),c])
	end

	dfSynBalance = DataFrame(dfSynBalance, :auto)

	CSV.write(joinpath(path, "HSC_h2_balance.csv"), dfSynBalance, writeheader=false)
end
