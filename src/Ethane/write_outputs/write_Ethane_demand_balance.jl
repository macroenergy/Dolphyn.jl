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
	write_ng_demand_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the natural gas balance of resources across different zones with time for each type of fuels.
"""
function write_Ethane_demand_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	###########################################################################################
	## Ethane balance for each zone
	dfEthaneBalance = Array{Any}
	rowoffset=3

	for z in 1:Z
		dfTemp1_Ethane = Array{Any}(nothing, T+rowoffset, 4)

		# dfTemp1_Ethylene[1,1:size(dfTemp1_Ethylene,2)] = ["Purchase", "CSC_Plant", "CSC_CCS_Plant", "ESC_Plant","Ethane_Plant","Ethane_CCS_Plant","CO2_MS_MTO","CO2_CTM_OCM","CO2_DFT","CO2_HTeCO_SFT","CO2_eCO_SFT","CO2_eCH4_OCM","CO2_HTeCO_SeC2H4","CO2_eCO_SeC2H4","CO2_DeC2H4","Ethylene_Demand"]
		dfTemp1_Ethane[1,1:size(dfTemp1_Ethane,2)] = ["Purchase", "Bio Ethane","Ethylene Sector","Ethane Demand"]
		
		dfTemp1_Ethane[2,1:size(dfTemp1_Ethane,2)] = repeat([z],size(dfTemp1_Ethane,2))
		
		
		
		
		for t in 1:T

			dfTemp1_Ethane[t+rowoffset,1] = 0
			dfTemp1_Ethane[t+rowoffset,2] = 0
			dfTemp1_Ethane[t+rowoffset,3] = 0
			dfTemp1_Ethane[t+rowoffset,4] = 0
			#dfTemp1_Ethylene[t+rowoffset,4] = 0
			#dfTemp1_Ethylene[t+rowoffset,5] = 0
			#dfTemp1_Ethylene[t+rowoffset,6] = 0
			#fTemp1_Ethylene[t+rowoffset,7] = 0
			#dfTemp1_Ethylene[t+rowoffset,8] = 0
			#dfTemp1_Ethylene[t+rowoffset,9] = 0
			#dfTemp1_Ethylene[t+rowoffset,10] = 0
			#dfTemp1_Ethylene[t+rowoffset,11] = 0
			#dfTemp1_Ethylene[t+rowoffset,12] = 0
			#dfTemp1_Ethylene[t+rowoffset,13] = 0
			#dfTemp1_Ethylene[t+rowoffset,14] = 0
			#dfTemp1_Ethylene[t+rowoffset,15] = 0
			#dfTemp1_Ethylene[t+rowoffset,16] = 0
			
			if setup["ModelEthanePurchase"] == 1
            	dfTemp1_Ethane[t+rowoffset,1] = value.(EP[:vConv_Ethane_Demand][t,z])
                dfTemp1_Ethane[t+rowoffset,3] = -value.(EP[:eEthylene_Ethane_RES][t, z])-value.(EP[:eEthylene_Ethane_Plant][t, z])
			end
		#	eEthylene_Ethane_Prod_EP[t=1:T]
		#	eEthylene_Ethane_Prod_GF[t=1:T]


			# eEthylene_Ethane_RES[t=1:T, z=1:Z]
			# eEthylene_Ethane_Plant[t=1:T, z=1:Z]
			# dfTemp1_Ethane[t+rowoffset,2] = value.(EP[:eEthylene_Prod_Plant][2*z-1,t])

			    #if setup["ModelEthyleneProduction"] == 1
				# dfTemp1_Ethylene[t+rowoffset,2] = value.(EP[:eEthylene_Prod_Plant][2*z-1,t]) # value.(EP[:eEthylene_Prod][t,z])
				# dfTemp1_Ethylene[t+rowoffset,3] = value.(EP[:eEthylene_Prod_Plant][2*z,t]) 
				#=
				dfTemp1_Ethylene[t+rowoffset,2] = value.(EP[:eEthylene_Prod_Plant][14*z-13,t]) # value.(EP[:eEthylene_Prod][t,z])
				dfTemp1_Ethylene[t+rowoffset,3] = value.(EP[:eEthylene_Prod_Plant][14*z-12,t]) 
				dfTemp1_Ethylene[t+rowoffset,4] = value.(EP[:eEthylene_Prod_Plant][14*z-11,t]) 
				dfTemp1_Ethylene[t+rowoffset,5] = value.(EP[:eEthylene_Prod_Plant][14*z-10,t]) 
				dfTemp1_Ethylene[t+rowoffset,6] = value.(EP[:eEthylene_Prod_Plant][14*z-9,t]) 
				dfTemp1_Ethylene[t+rowoffset,7] = value.(EP[:eEthylene_Prod_Plant][14*z-8,t]) 
				dfTemp1_Ethylene[t+rowoffset,8] = value.(EP[:eEthylene_Prod_Plant][14*z-7,t]) 
				dfTemp1_Ethylene[t+rowoffset,9] = value.(EP[:eEthylene_Prod_Plant][14*z-6,t]) 
				dfTemp1_Ethylene[t+rowoffset,10] = value.(EP[:eEthylene_Prod_Plant][14*z-5,t]) 
				dfTemp1_Ethylene[t+rowoffset,11] = value.(EP[:eEthylene_Prod_Plant][14*z-4,t]) 
				dfTemp1_Ethylene[t+rowoffset,12] = value.(EP[:eEthylene_Prod_Plant][14*z-3,t]) 
				dfTemp1_Ethylene[t+rowoffset,13] = value.(EP[:eEthylene_Prod_Plant][14*z-2,t]) 
				dfTemp1_Ethylene[t+rowoffset,14] = value.(EP[:eEthylene_Prod_Plant][14*z-1,t]) 
				dfTemp1_Ethylene[t+rowoffset,15] = value.(EP[:eEthylene_Prod_Plant][14*z,t]) 
				=#

			    #	dfTemp1_Ethylene[t+rowoffset,2] = value.(EP[:eEthylene_Prod_RES][14*z-13,t]) # value.(EP[:eEthylene_Prod][t,z])
		        #		dfTemp1_Ethylene[t+rowoffset,3] = value.(EP[:eEthylene_Prod_RES][14*z-12,t]) 
		        #		dfTemp1_Ethylene[t+rowoffset,4] = value.(EP[:eEthylene_Prod_RES][14*z-11,t]) 
	            #			dfTemp1_Ethylene[t+rowoffset,5] = value.(EP[:eEthylene_Prod_RES][14*z-10,t]) 
	            #			dfTemp1_Ethylene[t+rowoffset,6] = value.(EP[:eEthylene_Prod_RES][14*z-9,t]) 
	            #			dfTemp1_Ethylene[t+rowoffset,7] = value.(EP[:eEthylene_Prod_RES][14*z-8,t]) 
	            #			dfTemp1_Ethylene[t+rowoffset,8] = value.(EP[:eEthylene_Prod_RES][14*z-7,t]) 
	            #			dfTemp1_Ethylene[t+rowoffset,9] = value.(EP[:eEthylene_Prod_RES][14*z-6,t]) 
	            #			dfTemp1_Ethylene[t+rowoffset,10] = value.(EP[:eEthylene_Prod_RES][14*z-5,t]) 
	            #			dfTemp1_Ethylene[t+rowoffset,11] = value.(EP[:eEthylene_Prod_RES][14*z-4,t]) 
	            #			dfTemp1_Ethylene[t+rowoffset,12] = value.(EP[:eEthylene_Prod_RES][14*z-3,t]) 
	            #			dfTemp1_Ethylene[t+rowoffset,13] = value.(EP[:eEthylene_Prod_RES][14*z-2,t]) 
	            #			dfTemp1_Ethylene[t+rowoffset,14] = value.(EP[:eEthylene_Prod_RES][14*z-1,t]) 
	            #			dfTemp1_Ethylene[t+rowoffset,15] = value.(EP[:eEthylene_Prod_RES][14*z,t]) 
	            #		end

			dfTemp1_Ethane[t+rowoffset,4] = -inputs["Ethane_Demand"][t,z]
			


		end

		if z==1
			dfEthaneBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_Ethane)
		else
			dfEthaneBalance = hcat(dfEthaneBalance, dfTemp1_Ethane)
		end
	end

	for c in 2:size(dfEthaneBalance,2)
		dfEthaneBalance[rowoffset,c]=sum(inputs["omega"].*dfEthaneBalance[(rowoffset+1):size(dfEthaneBalance,1),c])
		
	end

	dfEthaneBalance = DataFrame(dfEthaneBalance, :auto)
	
	CSV.write(string(path,sep,"Ethane_Balance.csv"), dfEthaneBalance, writeheader=false)

end
