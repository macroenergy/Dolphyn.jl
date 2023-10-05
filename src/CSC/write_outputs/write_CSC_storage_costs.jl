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
	write_CSC_storage_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the cost for the different sectors of the carbon supply chain (DAC, Compression, Storage, Network Expansion)).
"""
function write_CSC_storage_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfDAC = inputs["dfDAC"]
	dfCO2CaptureComp = inputs["dfCO2CaptureComp"]
	dfCO2Storage = inputs["dfCO2Storage"]
	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)
    S = inputs["S"]     # Number of CO2 Storage Sites
	
	
	if setup["ParameterScale"] == 1
		cCO2Stor = value(EP[:eFixed_Cost_CO2_Storage_total]) * ModelScalingFactor^2
		cCO2Injection= value(EP[:eVar_OM_CO2_Injection_total]) * ModelScalingFactor^2

	else
		cCO2Stor = value(EP[:eFixed_Cost_CO2_Storage_total])
		cCO2Injection= value(EP[:eVar_OM_CO2_Injection_total])
	end

    df_Stor_Cost = DataFrame(Costs = ["cCO2Stor", "cCO2Injection"])
    cTotal_Stor = cCO2Stor + cCO2Injection

	# Computing zonal cost breakdown by cost category
	df_Stor_Cost = DataFrame(Costs = ["cCO2Stor", "cCO2Injection"])
    # Define total costs
    cTotal_Stor = cCO2Stor + cCO2Injection

    # Define total column, i.e. column 2
    df_Stor_Cost[!,Symbol("Total")] = [cCO2Stor, cCO2Injection]

    # Computing zonal cost breakdown by cost category
    for s in 1:S
        tempCCO2Stor = 0
        tempCCO2Injection = 0
        tempCTotal_Stor = 0
        
        for y in dfCO2Storage[dfCO2Storage[!,:Site].==s,:][!,:R_ID]
            tempCCO2Stor = tempCCO2Stor + value.(EP[:eFixed_Cost_CO2_Storage_per_type])[y]
            tempCTotal_Stor = tempCTotal_Stor + value.(EP[:eFixed_Cost_CO2_Storage_per_type])[y]
        end

        for y in dfCO2Storage[dfCO2Storage[!,:Site].==s,:][!,:R_ID]
            tempCCO2Injection = tempCCO2Injection + value.(EP[:eVar_OM_CO2_Injection_per_type])[y]
            tempCTotal_Stor = tempCTotal_Stor + value.(EP[:eVar_OM_CO2_Injection_per_type])[y]
        end


        if setup["ParameterScale"] == 1
            tempCCO2Stor = tempCCO2Stor * (ModelScalingFactor^2)
            tempCCO2Injection = tempCCO2Injection * (ModelScalingFactor^2)
        end

        df_Stor_Cost[!,Symbol("Site$s")] = [tempCCO2Stor, tempCCO2Injection]
    end

    CSV.write(string(path,sep,"CSC_storage_costs.csv"), df_Stor_Cost)

end
