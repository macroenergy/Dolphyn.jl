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
    load_co2_capture_DAC(setup::Dict, path::AbstractString, sep::AbstractString, inputs_gen::Dict)

Function for reading input parameters related to DAC resources in the carbon supply chain.
"""
function load_co2_capture_DAC(setup::Dict, path::AbstractString, sep::AbstractString, inputs_capture::Dict)

	#Read in CO2 capture related inputs
    co2_dac = DataFrame(CSV.File(string(path,sep,"CSC_capture.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	co2_dac[!,:R_ID] = 1:size(collect(skipmissing(co2_dac[!,1])),1)

    # Store DataFrame of capture units/resources input data for use in model
	inputs_capture["dfDAC"] = co2_dac

    # Index of DAC resources - can be either commit, no_commit capture technologies, demand side, G2P, or storage resources
	inputs_capture["DAC_RES_ALL"] = size(collect(skipmissing(co2_dac[!,:R_ID])),1)

	# Name of DAC resources
	inputs_capture["DAC_RESOURCES_NAME"] = collect(skipmissing(co2_dac[!,:CO2_Resource][1:inputs_capture["DAC_RES_ALL"]]))

	# Set of DAC resources
	inputs_capture["CO2_CAPTURE_DAC"] = co2_dac[!,:R_ID]

	println("CSC_capture.csv Successfully Read!")

    return inputs_capture

end

