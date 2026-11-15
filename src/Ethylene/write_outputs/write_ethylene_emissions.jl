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
	write_ng_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting CO2 emissions of natural gas types across different zones.
"""
function write_ethylene_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Emission balance for each zone
	dfEthyleneEmissionBalance = Array{Any}

	rowoffset=3
	for z in 1:Z #4:8 #1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 15)
	   	# dfTemp1[1,1:size(dfTemp1,2)] = vcat(["Ethylene_Purchase_Emissions", "CSC_Ethylene_Emissions", "CSC_CCS_Ethylene_Emissions"])
		dfTemp1[1,1:size(dfTemp1,2)] = vcat(["Purchase", "TSC", "TSC+CC90", "TSC:H2","Ethanol+NG","Ethanol+H2","MS+MTO","MS+MTO+CC90","MS+MTO+CC90","MS+MTO+CC90","MS+MTO+CC90","TSC+CC90:H2","TSC+CC90:H2","TSC+CC90:H2","TSC+CC90:H2"])
		dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))
		# dfTemp1_Ethylene[1,1:size(dfTemp1_Ethylene,2)] = ["Purchase", "CSC_Plant", "CSC_CCS_Plant", "ESC_Plant","Ethanol_Plant","Ethanol_CCS_Plant","CO2_MS_MTO","CO2_CTM_OCM","CO2_DFT","CO2_HTeCO_SFT","CO2_eCO_SFT","CO2_eCH4_OCM","CO2_HTeCO_SeC2H4","CO2_eCO_SeC2H4","CO2_DeC2H4","Ethylene_Demand"]
		
		for t in 1:T

			dfTemp1[t+rowoffset,1] = 0
			dfTemp1[t+rowoffset,2] = 0
			dfTemp1[t+rowoffset,3] = 0
			dfTemp1[t+rowoffset,4] = 0
			dfTemp1[t+rowoffset,5] = 0
			dfTemp1[t+rowoffset,6] = 0
			dfTemp1[t+rowoffset,7] = 0
			dfTemp1[t+rowoffset,8] = 0
			dfTemp1[t+rowoffset,9] = 0
			dfTemp1[t+rowoffset,10] = 0
			dfTemp1[t+rowoffset,11] = 0
			dfTemp1[t+rowoffset,12] = 0
			dfTemp1[t+rowoffset,13] = 0
			dfTemp1[t+rowoffset,14] = 0
			dfTemp1[t+rowoffset,15] = 0
			if setup["ModelEthylenePurchase"] == 1
            	dfTemp1[t+rowoffset,1] = value.(EP[:eConv_Ethylene_CO2_Emissions][z,t])
			end
			
		

			if setup["ModelEthyleneProduction"] == 1
				# dfTemp1[t+rowoffset,2] = value.(EP[:eEthylene_CO2_Emissions_By_Res][2*z-1,t])
				# dfTemp1[t+rowoffset,3] = value.(EP[:eEthylene_CO2_Emissions_By_Res][2*z,t]) 
				dfTemp1[t+rowoffset,2] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-13,t])
				dfTemp1[t+rowoffset,3] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-12,t]) 
				dfTemp1[t+rowoffset,4] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-11,t]) 
				dfTemp1[t+rowoffset,5] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-10,t]) 
				dfTemp1[t+rowoffset,6] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-9,t])
				dfTemp1[t+rowoffset,7] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-8,t]) 
				dfTemp1[t+rowoffset,8] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-7,t]) 
				dfTemp1[t+rowoffset,9] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-6,t]) 
				dfTemp1[t+rowoffset,10] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-5,t])
				dfTemp1[t+rowoffset,11] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-4,t]) 
				dfTemp1[t+rowoffset,12] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-3,t]) 
				dfTemp1[t+rowoffset,13] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-2,t]) 
				dfTemp1[t+rowoffset,14] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z-1,t]) 
				dfTemp1[t+rowoffset,15] = value.(EP[:eEthylene_CO2_Emissions_By_RES2][14*z,t]) 
				# dfTemp1[t+rowoffset,2] = value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone][z,t])
				# dfTemp1[t+rowoffset,3] = value.(EP[:eEthylene_CO2_Capture_Per_Zone_Per_Time][z,t])
				# dfTemp1[t+rowoffset,4] = value.(EP[:eEthylene_CO2_Emissions_By_Zone][z,t])

			end
			
		end

		if z==1 #4
			dfEthyleneEmissionBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfEthyleneEmissionBalance = hcat(dfEthyleneEmissionBalance, dfTemp1)
		end
	end

	for c in 2:size(dfEthyleneEmissionBalance,2)
		dfEthyleneEmissionBalance[rowoffset,c]=sum(inputs["omega"].*dfEthyleneEmissionBalance[(rowoffset+1):size(dfEthyleneEmissionBalance,1),c])
	end

	dfEthyleneEmissionBalance = DataFrame(dfEthyleneEmissionBalance, :auto)
	CSV.write(string(path,sep,"Ethylene_Emissions_Balance.csv"), dfEthyleneEmissionBalance, writeheader=false)

end