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


function load_co2_capture_compression(setup::Dict, path::AbstractString, sep::AbstractString, inputs_co2_capture_comp::Dict)

	#Read in CO2 capture related inputs
    co2_capture_comp = DataFrame(CSV.File(string(path,sep,"CSC_capture_compression.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	co2_capture_comp[!,:R_ID] = 1:size(collect(skipmissing(co2_capture_comp[!,1])),1)

    # Store DataFrame of capture units/resources input data for use in model
	inputs_co2_capture_comp["dfCO2CaptureComp"] = co2_capture_comp

    # Index of CO2 resources
	inputs_co2_capture_comp["CO2_CAPTURE_COMP_ALL"] = size(collect(skipmissing(co2_capture_comp[!,:R_ID])),1)

	# Name of CO2 capture resources
	inputs_co2_capture_comp["CO2_CAPTURE_COMP_NAME"] = collect(skipmissing(co2_capture_comp[!,:CO2_Capture_Compression][1:inputs_co2_capture_comp["CO2_CAPTURE_COMP_ALL"]]))
	
	# Resource identifiers by zone (just zones in resource order + resource and zone concatenated)
	co2_zones = collect(skipmissing(co2_capture_comp[!,:Zone][1:inputs_co2_capture_comp["CO2_CAPTURE_COMP_ALL"]]))
	inputs_co2_capture_comp["CO2_C_C_ZONES"] = co2_zones
	inputs_co2_capture_comp["CO2_CAPTURE_COMP_ZONES"] = inputs_co2_capture_comp["CO2_CAPTURE_COMP_NAME"] .* "_z" .* string.(co2_zones)

	# Set of CO2 resources not eligible for unit committment
	inputs_co2_capture_comp["CO2_CAPTURE_COMP"] = co2_capture_comp[!,:R_ID]

	println("CSC_capture_compression.csv Successfully Read!")

    return inputs_co2_capture_comp

end

