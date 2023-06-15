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
	load_generators_variability(setup::Dict, path::AbstractString, sep::AbstractString, inputs_capturevar::Dict)

Function for reading input parameters related to hourly maximum capacity factors for all generators (plus storage and flexible demand resources)
"""
function load_co2_capture_variability(setup::Dict, path::AbstractString, sep::AbstractString, inputs_capturevar::Dict)

	# Hourly capacity factors
	#data_directory = chop(replace(path, pwd() => ""), head = 1, tail = 0)
	data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory,"Load_data.csv")) && isfile(joinpath(data_directory,"Generators_variability.csv")) && isfile(joinpath(data_directory,"Fuels_data.csv")) && isfile(joinpath(data_directory,"HSC_load_data.csv")) && isfile(joinpath(data_directory,"HSC_generators_variability.csv")) && isfile(joinpath(data_directory,"CSC_capture_variability.csv")) # Use Time Domain Reduced data for GenX
		capture_var = DataFrame(CSV.File(string(joinpath(data_directory,"CSC_capture_variability.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		capture_var = DataFrame(CSV.File(string(path,sep,"CSC_capture_variability.csv"), header=true), copycols=true)
	end

	# Reorder DataFrame to R_ID order (order provided in Generators_data.csv)
	select!(capture_var, [:Time_Index; Symbol.(inputs_capturevar["CO2_RESOURCES_NAME"]) ])

	# Maximum capture output and variability of each carbon capture resource
	inputs_capturevar["CO2_Capture_Max_Output"] = transpose(Matrix{Float64}(capture_var[1:inputs_capturevar["T"],2:(inputs_capturevar["CO2_RES_ALL"]+1)]))

	println("CSC_capture_variability.csv Successfully Read!")

	return inputs_capturevar
end
