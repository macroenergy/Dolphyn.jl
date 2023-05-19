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
	write_h2_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting hydrogen balance.
"""
function write_h2_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfH2Gen = inputs["dfH2Gen"]

	if setup["ModelH2G2P"] == 1
		dfH2G2P = inputs["dfH2G2P"]
	end

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	Zones = inputs["Zones"] # List of zones
	H2_SEG = inputs["H2_SEG"] # Number of load curtailment segments
	H2_FLEX = inputs["H2_FLEX"] # Set of demand flexibility resources
	H2_STOR_ALL = inputs["H2_STOR_ALL"] # Set of H2 storage resources
	## Hydrogen balance for each zone
	dfH2Balance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 13)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Generation", 
	           "Flexible_Demand_Defer", "Flexible_Demand_Satisfy",
			   "Storage Discharging", "Storage Charging",
               "Nonserved_Energy",
			   "H2_Pipeline_Import/Export",
			   "H2_Truck_Import/Export","G2P Demand",
	           "Demand", "Transmission"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))
	   	for t in 1:T
	     	dfTemp1[t+rowoffset,1]= sum(value.(EP[:vH2Gen][dfH2Gen[(dfH2Gen[!,:H2_GEN_TYPE].>0) .&  (dfH2Gen[!,:Zone].==Zones[z]),:][!,:R_ID],t]))
	     	dfTemp1[t+rowoffset,2] = 0
            dfTemp1[t+rowoffset,3] = 0
			dfTemp1[t+rowoffset,4] = 0
            dfTemp1[t+rowoffset,5] = 0
	     	if !isempty(intersect(dfH2Gen[dfH2Gen.Zone.==Zones[z],:R_ID],H2_FLEX))
	     	    dfTemp1[t+rowoffset,2] = sum(value.(EP[:vH2_CHARGE_FLEX][y,t]) for y in intersect(dfH2Gen[dfH2Gen.Zone.==Zones[z],:R_ID],H2_FLEX))
                dfTemp1[t+rowoffset,3] = -sum(value.(EP[:vH2Gen][dfH2Gen[(dfH2Gen[!,:H2_FLEX].>=1) .&  (dfH2Gen[!,:Zone].==Zones[z]),:][!,:R_ID],t]))
	     	end
			 if !isempty(intersect(dfH2Gen[dfH2Gen.Zone.==Zones[z],:R_ID],H2_STOR_ALL))
				dfTemp1[t+rowoffset,4] = sum(value.(EP[:vH2Gen][y,t]) for y in intersect(dfH2Gen[dfH2Gen.Zone.==Zones[z],:R_ID],H2_STOR_ALL))
			   dfTemp1[t+rowoffset,5] = -sum(value.(EP[:vH2_CHARGE_STOR][y,t]) for y in intersect(dfH2Gen[dfH2Gen.Zone.==Zones[z],:R_ID],H2_STOR_ALL))
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


		# if Z>=2
		# 	dfTemp1[t+rowoffset,5] = value(EP[:ePowerBalanceNetExportFlows][t,z])
		# 	dfTemp1[t+rowoffset,6] = -1/2 * value(EP[:eLosses_By_Zone][z,t])
		# end

			if setup["ModelH2G2P"] == 1
				dfTemp1[t+rowoffset,9] = sum(value.(EP[:vH2G2P][dfH2G2P[(dfH2G2P[!,:Zone].==Zones[z]),:][!,:R_ID],t])) 
			else
				dfTemp1[t+rowoffset,9] = 0
			end

	     	dfTemp1[t+rowoffset,10] = -inputs["H2_D"][t,z]

			if setup["ModelH2Liquid"] == 1
				dfTemp1[t+rowoffset,11] = sum(value.(EP[:vH2Gen][dfH2Gen[(dfH2Gen[!,:H2_LIQ].>0) .&  (dfH2Gen[!,:H2_LIQ].<3) .& (dfH2Gen[!,:Zone].==z),:][!,:R_ID],t]))
				dfTemp1[t+rowoffset,13] = sum(value.(EP[:vH2Gen][dfH2Gen[(dfH2Gen[!,:H2_LIQ].>2) .&  (dfH2Gen[!,:Zone].==z),:][!,:R_ID],t]))
				dfTemp1[t+rowoffset,12] = -inputs["H2_D_L"][t,z]
			else
				dfTemp1[t+rowoffset,11] = 0
				dfTemp1[t+rowoffset,12] = 0
				dfTemp1[t+rowoffset,13] = 0
			end 

	   	end

		if z==1
			dfH2Balance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfH2Balance = hcat(dfH2Balance, dfTemp1)
		end
	end
	for c in 2:size(dfH2Balance,2)
		dfH2Balance[rowoffset,c]=sum(inputs["omega"].*dfH2Balance[(rowoffset+1):size(dfH2Balance,1),c])
	end
	dfH2Balance = DataFrame(dfH2Balance, :auto)
	CSV.write(string(path,sep,"HSC_h2_balance.csv"), dfH2Balance, writeheader=false)
end
