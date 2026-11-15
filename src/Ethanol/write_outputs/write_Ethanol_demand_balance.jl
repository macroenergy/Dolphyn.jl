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
function write_Ethanol_demand_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	###########################################################################################
	## Ethanol balance for each zone
	dfEthanolBalance = Array{Any}
	rowoffset=3

	for z in 1:Z
		dfTemp1_Ethanol = Array{Any}(nothing, T+rowoffset, 4)

		# dfTemp1_Ethylene[1,1:size(dfTemp1_Ethylene,2)] = ["Purchase", "CSC_Plant", "CSC_CCS_Plant", "ESC_Plant","Ethanol_Plant","Ethanol_CCS_Plant","CO2_MS_MTO","CO2_CTM_OCM","CO2_DFT","CO2_HTeCO_SFT","CO2_eCO_SFT","CO2_eCH4_OCM","CO2_HTeCO_SeC2H4","CO2_eCO_SeC2H4","CO2_DeC2H4","Ethylene_Demand"]
		dfTemp1_Ethanol[1,1:size(dfTemp1_Ethanol,2)] = ["Purchase", "Bio Ethanol","Ethylene Sector","Ethanol Demand"]
		
		dfTemp1_Ethanol[2,1:size(dfTemp1_Ethanol,2)] = repeat([z],size(dfTemp1_Ethanol,2))
		
		
		
		
		for t in 1:T

			dfTemp1_Ethanol[t+rowoffset,1] = 0
			dfTemp1_Ethanol[t+rowoffset,2] = 0
			dfTemp1_Ethanol[t+rowoffset,3] = 0
			dfTemp1_Ethanol[t+rowoffset,4] = 0
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
			
			if setup["ModelEthanolPurchase"] == 1
            	dfTemp1_Ethanol[t+rowoffset,1] = value.(EP[:vConv_Ethanol_Demand][t,z])
			end
		#	eEthylene_Ethanol_Prod_EP[t=1:T]
		#	eEthylene_Ethanol_Prod_GF[t=1:T]
			if setup["ModelEthanol"] == 1
				dfTemp1_Ethanol[t+rowoffset,3] = -value.(EP[:eEthylene_Ethanol_RES][t, z])-value.(EP[:eEthylene_Ethanol_Plant][t, z])
		#		dfTemp1_Ethanol[t+rowoffset,2] = value.(EP[:vConv_Ethanol_Demand][t,z])+value.(EP[:vConv_Ethanol_Demand][t,z])
			end

			if setup["Bio_Ethanol_On"] == 1
				dfTemp1_Ethanol[t+rowoffset,2] = value.(EP[:eBioEthanol_produced_tonne_per_time_per_zone][t,z])
			end

			# eEthylene_Ethanol_RES[t=1:T, z=1:Z]
			# eEthylene_Ethanol_Plant[t=1:T, z=1:Z]
			# dfTemp1_Ethanol[t+rowoffset,2] = value.(EP[:eEthylene_Prod_Plant][2*z-1,t])

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

			dfTemp1_Ethanol[t+rowoffset,4] = -inputs["Ethanol_Demand"][t,z]
			


		end

		if z==1
			dfEthanolBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_Ethanol)
		else
			dfEthanolBalance = hcat(dfEthanolBalance, dfTemp1_Ethanol)
		end
	end

	for c in 2:size(dfEthanolBalance,2)
		dfEthanolBalance[rowoffset,c]=sum(inputs["omega"].*dfEthanolBalance[(rowoffset+1):size(dfEthanolBalance,1),c])
		
	end

	dfEthanolBalance = DataFrame(dfEthanolBalance, :auto)
	
	CSV.write(string(path,sep,"Ethanol_Balance.csv"), dfEthanolBalance, writeheader=false)

end
