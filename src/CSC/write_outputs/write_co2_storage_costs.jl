"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
	write_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the costs pertaining to the objective function (fixed, variable O&M etc.).
"""
function write_co2_storage_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfCO2Stor = inputs["dfCO2Stor"]

	SEG = inputs["SEG"]  # Number of lines
	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)

	dfCO2StorageCost = DataFrame(Costs = ["cCO2StorageTotal", "cCO2StorageFix", "cCO2StorageVar"])
	if setup["ParameterScale"]==1 # Convert costs in millions to $
		cCO2StorageVar = value(EP[:eTotalCVarCO2Stor])* (ModelScalingFactor^2)

		cCO2StorageFix = (value(EP[:eTotalCFixCO2Charge]) + value(EP[:eTotalCFixCO2Carbon]))*ModelScalingFactor^2
	else
		cCO2StorageVar = value(EP[:eTotalCVarCO2Stor])

		cCO2StorageFix = value(EP[:eTotalCFixCO2Charge]) + value(EP[:eTotalCFixCO2Carbon])
	end
	 
    cCO2StorageTotal = cCO2StorageVar + cCO2StorageFix

    dfCO2StorageCost[!,Symbol("Total")] = [cCO2StorageTotal, cCO2StorageFix, cCO2StorageVar]


	for z in 1:Z
		tempCStorageTotal = 0
		tempCStorageFix = 0
		tempCStorageVar = 0

		for y in dfCO2Stor[dfCO2Stor[!,:Zone].==z,:][!,:R_ID]
			tempCStorageFix = tempCStorageFix + value.(EP[:eCFixCO2Carbon])[y]
			tempCStorageVar = tempCStorageVar + sum(value.(EP[:eCVarCO2Stor_in])[y,:])
			tempCStorageTotal = tempCStorageTotal + tempCStorageFix + tempCStorageVar
		end

		
		if setup["ParameterScale"] == 1 # Convert costs in millions to $
			tempCStorageFix = tempCStorageFix * (ModelScalingFactor^2)
			tempCStorageVar = tempCStorageVar * (ModelScalingFactor^2)
			tempCStorageTotal = tempCStorageTotal * (ModelScalingFactor^2)
		end

		dfCO2StorageCost[!,Symbol("Zone$z")] = [tempCStorageTotal, tempCStorageFix, tempCStorageVar]
	end
	CSV.write(string(path,sep,"CSC_storage_costs.csv"), dfCO2StorageCost)
end
