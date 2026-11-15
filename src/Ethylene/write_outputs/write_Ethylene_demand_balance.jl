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
function write_Ethylene_demand_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	dfEthylene_plants = inputs["dfEthylene_plants"]

	###########################################################################################
	## Ethylene balance for each zone
	dfEthyleneBalance = Array{Any}
	rowoffset=3

	for z in 1:Z #4:8 #1:Z
		dfTemp1_Ethylene = Array{Any}(nothing, T+rowoffset, 20)
		dfTemp1_Ethylene[1,1:size(dfTemp1_Ethylene,2)] = ["Purchase", "TSC", "TSC+CC90", "TSC:H2","Bio-eth+CC88:NG","Bio-eth+CC88:H2","MS+MTO","MS+MTO+CC90","TSC+CC90:H2","TSC+H2in","TSC+H2in:CH4","ESC","Existing Capacities","Ret-TSC+H2in:CH4","Ret-TSC","Ret-TSC+CC90","Ret-TSC+CC90:H2","Ret-TSC+H2in","Ret-ESC","Ethylene Demand"]
		
		dfTemp1_Ethylene[2,1:size(dfTemp1_Ethylene,2)] = repeat([z],size(dfTemp1_Ethylene,2))
		
		
		for t in 1:T
			for dum1 in 1:20
            	dfTemp1_Ethylene[t+rowoffset,dum1] = 0
        	end
			
			if setup["ModelEthylenePurchase"] == 1
            	dfTemp1_Ethylene[t+rowoffset,1] = value.(EP[:vConv_Ethylene_Demand][t,z])
			end

			if setup["ModelEthyleneProduction"] == 1
				
				dfTemp1_Ethylene[t+rowoffset,2] = value.(EP[:eEthylene_Prod_RES][14*z-13,t]) 
				dfTemp1_Ethylene[t+rowoffset,3] = value.(EP[:eEthylene_Prod_RES][14*z-12,t]) 
				dfTemp1_Ethylene[t+rowoffset,4] = value.(EP[:eEthylene_Prod_RES][14*z-11,t]) 
				dfTemp1_Ethylene[t+rowoffset,5] = value.(EP[:eEthylene_Prod_RES][14*z-10,t]) 
				dfTemp1_Ethylene[t+rowoffset,6] = value.(EP[:eEthylene_Prod_RES][14*z-9,t]) 
				dfTemp1_Ethylene[t+rowoffset,7] = value.(EP[:eEthylene_Prod_RES][14*z-8,t]) 
				dfTemp1_Ethylene[t+rowoffset,8] = value.(EP[:eEthylene_Prod_RES][14*z-7,t])+value.(EP[:eEthylene_Prod_RES][14*z-6,t])+value.(EP[:eEthylene_Prod_RES][14*z-5,t])+value.(EP[:eEthylene_Prod_RES][14*z-4,t])   
				dfTemp1_Ethylene[t+rowoffset,9] = value.(EP[:eEthylene_Prod_RES][14*z-3,t]) 
				dfTemp1_Ethylene[t+rowoffset,10] = value.(EP[:eEthylene_Prod_RES][14*z-2,t])
				dfTemp1_Ethylene[t+rowoffset,11] = value.(EP[:eEthylene_Prod_RES][14*z-1,t]) 
				dfTemp1_Ethylene[t+rowoffset,12] = value.(EP[:eEthylene_Prod_RES][14*z,t])

			end

			if setup["ModelEthylenePlants"] == 1
				zone_plant_ids = dfEthylene_plants[dfEthylene_plants.Plant_Zone .== z, :R_ID]

				if isempty(zone_plant_ids)
   					dfTemp1_Ethylene[t+rowoffset,13] = 0
				else
    				dfTemp1_Ethylene[t+rowoffset,13] = sum(value.(EP[:eEthylene_Prod_Plant][y,t]) for y in zone_plant_ids)
				end
			end

			if setup["ModelEthyleneRetrofitting"] == 1
				if z >=4 && z<=8
					dfTemp1_Ethylene[t+rowoffset,14] = value.(EP[:eEthylene_Prod_RetrofitRES][6*z-23,t])
					dfTemp1_Ethylene[t+rowoffset,15] = value.(EP[:eEthylene_Prod_RetrofitRES][6*z-22,t])
					dfTemp1_Ethylene[t+rowoffset,16] = value.(EP[:eEthylene_Prod_RetrofitRES][6*z-21,t])
					dfTemp1_Ethylene[t+rowoffset,17] = value.(EP[:eEthylene_Prod_RetrofitRES][6*z-20,t])
					dfTemp1_Ethylene[t+rowoffset,18] = value.(EP[:eEthylene_Prod_RetrofitRES][6*z-19,t])
					dfTemp1_Ethylene[t+rowoffset,19] = value.(EP[:eEthylene_Prod_RetrofitRES][6*z-18,t])
				end
			end

			#=

			if setup["ModelEthyleneRetrofitting"] == 1
				dfEthylene_retrofit = inputs["dfEthylene_retrofit"]
				zone_Retrofit_ids = dfEthylene_retrofit[dfEthylene_retrofit.Retrofit_Zone .== z, :R_ID]

				if isempty(zone_Retrofit_ids)
   					dfTemp1_Ethylene[t+rowoffset,14] = 0
				else
    				dfTemp1_Ethylene[t+rowoffset,14] = sum(value.(EP[:eEthylene_Prod_RetrofitRES][y,t]) for y in zone_Retrofit_ids)
				end
			end
			=#


			dfTemp1_Ethylene[t+rowoffset,20] = -inputs["Ethylene_Demand"][t,z]
			


		end

		if z==1 #4
			dfEthyleneBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_Ethylene)
		else
			dfEthyleneBalance = hcat(dfEthyleneBalance, dfTemp1_Ethylene)
		end
	end

	for c in 2:size(dfEthyleneBalance,2)
		dfEthyleneBalance[rowoffset,c]=sum(inputs["omega"].*dfEthyleneBalance[(rowoffset+1):size(dfEthyleneBalance,1),c])
		
	end

	dfEthyleneBalance = DataFrame(dfEthyleneBalance, :auto)
	
	CSV.write(string(path,sep,"Ethylene_Balance.csv"), dfEthyleneBalance, writeheader=false)

end
