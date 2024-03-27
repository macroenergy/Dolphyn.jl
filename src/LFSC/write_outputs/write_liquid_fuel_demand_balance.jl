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
	write_liquid_fuel_demand_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the liquid fuels balance of resources across different zones with time for each type of fuels.
"""
function write_liquid_fuel_demand_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfSynFuels= inputs["dfSynFuels"]
	
	T = inputs["T"]::Int     # Number of time steps (hours)
	Z = inputs["Z"]::Int     # Number of zones
	## SynFuel diesel balance for each zone
	dfSFDieselBalance = Array{Any}
	rowoffset=3

	if setup["ModelBIO"] == 1
		dfbiorefinery = inputs["dfbiorefinery"]
	end
	
	for z in 1:Z
	   	dfTemp1_Diesel = Array{Any}(nothing, T+rowoffset, 4)
	   	dfTemp1_Diesel[1,1:size(dfTemp1_Diesel,2)] = ["Syn_Fuel_Diesel_Generation", "Bio_Fuel_Diesel_Generation", "Conventional_Fuel_Diesel_Demand", "Diesel_Demand"]
	   	dfTemp1_Diesel[2,1:size(dfTemp1_Diesel,2)] = repeat([z],size(dfTemp1_Diesel,2))
	   	for t in 1:T
	     	dfTemp1_Diesel[t+rowoffset,1]= sum(value.(EP[:vSFProd_Diesel][dfSynFuels[(dfSynFuels[!,:Zone].==z),:][!,:R_ID],t]))

			 dfTemp1_Diesel[t+rowoffset,2]= 0

			if setup["ModelBIO"] == 1 && setup["BIO_Diesel_On"] == 1
				dfTemp1_Diesel[t+rowoffset,2]= sum(value.(EP[:eBiodiesel_produced_per_plant_per_time][dfbiorefinery[(dfbiorefinery[!,:Zone].==z),:][!,:R_ID],t]))
			end

			if setup["AllowConventionalDiesel"] == 1
				dfTemp1_Diesel[t+rowoffset,3] = value.(EP[:vConvLFDieselDemand][t,z])
			else
				dfTemp1_Diesel[t+rowoffset,3] = 0
			end

			dfTemp1_Diesel[t+rowoffset,4] = -inputs["Liquid_Fuels_Diesel_D"][t,z]
	   	end

		if z==1
			dfSFDieselBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_Diesel)
		else
		    dfSFDieselBalance = hcat(dfSFDieselBalance, dfTemp1_Diesel)
		end
	end
	for c in 2:size(dfSFDieselBalance,2)
		dfSFDieselBalance[rowoffset,c]=sum(inputs["omega"].*dfSFDieselBalance[(rowoffset+1):size(dfSFDieselBalance,1),c])
	end
	dfSFDieselBalance = DataFrame(dfSFDieselBalance, :auto)
	CSV.write(string(path,sep,"LF_Diesel_balance.csv"), dfSFDieselBalance, writeheader=false)

	## SynFuel jetfuel balance for each zone
	dfSFJetfuelBalance = Array{Any}
	rowoffset=3

	if setup["ModelBIO"] == 1
		dfbiorefinery = inputs["dfbiorefinery"]
	end
	
	for z in 1:Z
	   	dfTemp1_Jetfuel = Array{Any}(nothing, T+rowoffset, 4)
	   	dfTemp1_Jetfuel[1,1:size(dfTemp1_Jetfuel,2)] = ["Syn_Fuel_Jetfuel_Generation", "Bio_Fuel_Jetfuel_Generation", "Conventional_Fuel_Jetfuel_Demand", "Jetfuel_Demand"]
	   	dfTemp1_Jetfuel[2,1:size(dfTemp1_Jetfuel,2)] = repeat([z],size(dfTemp1_Jetfuel,2))
	   	for t in 1:T
	     	dfTemp1_Jetfuel[t+rowoffset,1]= sum(value.(EP[:vSFProd_Jetfuel][dfSynFuels[(dfSynFuels[!,:Zone].==z),:][!,:R_ID],t]))

			 dfTemp1_Jetfuel[t+rowoffset,2]= 0

			if setup["ModelBIO"] == 1 && setup["BIO_Jetfuel_On"] == 1
				dfTemp1_Jetfuel[t+rowoffset,2]= sum(value.(EP[:eBiojetfuel_produced_per_plant_per_time][dfbiorefinery[(dfbiorefinery[!,:Zone].==z),:][!,:R_ID],t]))
			end

			if setup["AllowConventionalJetfuel"] == 1
				dfTemp1_Jetfuel[t+rowoffset,3] = value.(EP[:vConvLFJetfuelDemand][t,z])
			else
				dfTemp1_Jetfuel[t+rowoffset,3] = 0
			end
			dfTemp1_Jetfuel[t+rowoffset,4] = -inputs["Liquid_Fuels_Jetfuel_D"][t,z]
	   	end

		if z==1
			dfSFJetfuelBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_Jetfuel)
		else
		    dfSFJetfuelBalance = hcat(dfSFJetfuelBalance, dfTemp1_Jetfuel)
		end
	end
	for c in 2:size(dfSFJetfuelBalance,2)
		dfSFJetfuelBalance[rowoffset,c]=sum(inputs["omega"].*dfSFJetfuelBalance[(rowoffset+1):size(dfSFJetfuelBalance,1),c])
	end
	dfSFJetfuelBalance = DataFrame(dfSFJetfuelBalance, :auto)
	CSV.write(string(path,sep,"LF_Jetfuel_balance.csv"), dfSFJetfuelBalance, writeheader=false)


	## SynFuel gasoline balance for each zone
	dfSFGasolineBalance = Array{Any}
	rowoffset=3

	if setup["ModelBIO"] == 1
		dfbiorefinery = inputs["dfbiorefinery"]
	end

	for z in 1:Z
	   	dfTemp1_Gasoline = Array{Any}(nothing, T+rowoffset, 4)
	   	dfTemp1_Gasoline[1,1:size(dfTemp1_Gasoline,2)] = ["Syn_Fuel_Gasoline_Generation", "Bio_Fuel_Gasoline_Generation", "Conventional_Fuel_Gasoline_Demand", "Gasoline_Demand"]
	   	dfTemp1_Gasoline[2,1:size(dfTemp1_Gasoline,2)] = repeat([z],size(dfTemp1_Gasoline,2))
	   	for t in 1:T
	     	dfTemp1_Gasoline[t+rowoffset,1]= sum(value.(EP[:vSFProd_Gasoline][dfSynFuels[(dfSynFuels[!,:Zone].==z),:][!,:R_ID],t]))

			 dfTemp1_Gasoline[t+rowoffset,2]= 0

			if setup["ModelBIO"] == 1 && setup["BIO_Gasoline_On"] == 1
				dfTemp1_Gasoline[t+rowoffset,2]= sum(value.(EP[:eBiogasoline_produced_per_plant_per_time][dfbiorefinery[(dfbiorefinery[!,:Zone].==z),:][!,:R_ID],t]))
			end

			if setup["AllowConventionalJetfuel"] == 1
				dfTemp1_Gasoline[t+rowoffset,3] = value.(EP[:vConvLFGasolineDemand][t,z])
			else
				dfTemp1_Gasoline[t+rowoffset,3] = 0
			end
			dfTemp1_Gasoline[t+rowoffset,4] = -inputs["Liquid_Fuels_Gasoline_D"][t,z]
	   	end

		if z==1
			dfSFGasolineBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_Gasoline)
		else
		    dfSFGasolineBalance = hcat(dfSFGasolineBalance, dfTemp1_Gasoline)
		end
	end
	for c in 2:size(dfSFGasolineBalance,2)
		dfSFGasolineBalance[rowoffset,c]=sum(inputs["omega"].*dfSFGasolineBalance[(rowoffset+1):size(dfSFGasolineBalance,1),c])
	end
	dfSFGasolineBalance = DataFrame(dfSFGasolineBalance, :auto)
	CSV.write(string(path,sep,"LF_Gasoline_balance.csv"), dfSFGasolineBalance, writeheader=false)

end
