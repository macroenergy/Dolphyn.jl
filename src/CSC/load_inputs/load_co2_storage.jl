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
	load_co2_storage(path::AbstractString, setup::Dict, inputs::Dict)


"""
function load_co2_storage(path::AbstractString, setup::Dict, inputs::Dict)
	
	# Set indices for internal use
	T = inputs["T"]   # Number of time steps (hours)
	Zones = inputs["Zones"] # List of modeled zones

	# Read in CO2 Storage related inputs
    co2_storage_in = DataFrame(CSV.File(joinpath(path, "CSC_storage.csv"), header=true), copycols=true)

	# Filter resources in modeled zones
	co2_storage_in = filter(row -> (row.Zone in Zones), co2_storage_in)
	
    # Add Resource IDs after reading to prevent user errors
	co2_storage_in[!,:R_ID] = 1:size(collect(skipmissing(co2_storage_in[!,1])),1)

    # Store DataFrame of storage input data for use in model
	inputs["dfCO2Stor"] = co2_storage_in

    # Index of CO2 Storage - can be either commit, no_commit production technologies, demand side, G2P, or storage resources
	inputs["CO2_STOR_ALL"] = co2_storage_in[!,:R_ID]

	# Name of CO2 Storage
	inputs["CO2_STORAGE_NAME"] = collect(skipmissing(co2_storage_in[!,:CO2_Storage]))
	
	# Defining whether CO2 storage is modeled as long-duration (inter-period carbon transfer allowed) or short-duration storage (inter-period carbon transfer disallowed)
	inputs["CO2_STOR_LONG_DURATION"] = co2_storage_in[(co2_storage_in.LDS.==1),:R_ID]
	inputs["CO2_STOR_SHORT_DURATION"] = co2_storage_in[(co2_storage_in.LDS.==0),:R_ID]

	# Set of all storage resources eligible for new carbon capacity
	inputs["NEW_CAP_CO2_STORAGE"] = intersect(co2_storage_in[co2_storage_in.New_Build.==1,:R_ID], co2_storage_in[co2_storage_in.Max_Carbon_Cap_tonne.!=0,:R_ID], inputs["CO2_STOR_ALL"])

	# Set of asymmetric charge/discharge storage resources eligible for new charge capacity, which for CO2 storage refers to compression power requirements
	inputs["NEW_CAP_CO2_CHARGE"] = intersect(co2_storage_in[co2_storage_in.New_Build.==1,:R_ID], co2_storage_in[co2_storage_in.Max_Charge_Cap_tonne_p_hr.!=0,:R_ID], inputs["CO2_STOR_ALL"])

	println("CSC_storage.csv Successfully Read!")

    return inputs

end
