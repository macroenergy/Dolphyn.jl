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
	write_synfuel_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting input and output balance of synthetic fuels resources across different zones with time.
"""
function write_synfuel_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfSynFuels= inputs["dfSynFuels"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	NSFByProd = inputs["NSFByProd"]

	## SynFuel balance for each zone
	dfSFBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 6 + NSFByProd)
		byprodHead = "ByProd_Out_" .* string.(collect(1:NSFByProd))
	   	dfTemp1[1,1:size(dfTemp1,2)] = vcat(["CO2_In","Power_In", "H2_In","Syn_Fuel_Diesel_Out","Syn_Fuel_Jetfuel_Out","Syn_Gasoline_Out"], byprodHead)
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

	   	for t in 1:T
			if setup["ParameterScale"] ==1
				dfTemp1[t+rowoffset,1]=value.(EP[:eSynFuelCO2Cons_Per_Time_Per_Zone][t,z])*ModelScalingFactor #Convert kton CO2 to tonne CO2
				dfTemp1[t+rowoffset,2]=value.(EP[:ePowerBalanceSynFuelRes][t,z])*ModelScalingFactor #Convert GW to MW
			else
				dfTemp1[t+rowoffset,1]=value.(EP[:eSynFuelCO2Cons_Per_Time_Per_Zone][t,z])
				dfTemp1[t+rowoffset,2]=value.(EP[:ePowerBalanceSynFuelRes][t,z])
			end

			dfTemp1[t+rowoffset,3]=value.(EP[:eSynFuelH2Cons][t,z])
			dfTemp1[t+rowoffset,4]= sum(value.(EP[:vSFProd_Diesel][dfSynFuels[(dfSynFuels[!,:Zone].==z),:][!,:R_ID],t]))
			dfTemp1[t+rowoffset,5]= sum(value.(EP[:vSFProd_Jetfuel][dfSynFuels[(dfSynFuels[!,:Zone].==z),:][!,:R_ID],t]))
			dfTemp1[t+rowoffset,6]= sum(value.(EP[:vSFProd_Gasoline][dfSynFuels[(dfSynFuels[!,:Zone].==z),:][!,:R_ID],t]))

			for b in 1:NSFByProd
				dfTemp1[t+rowoffset, 6 + b] = sum(value.(EP[:vSFByProd][dfSynFuels[(dfSynFuels[!,:Zone].==z),:][!,:R_ID],b,t]))
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
	CSV.write(string(path,sep,"Syn_Fuel_balance.csv"), dfSFBalance, writeheader=false)
end
