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
	load_h2_g2p_variability(setup::Dict, path::AbstractString, sep::AbstractString, inputs_genvar::Dict)

Function for reading input parameters related to hourly maximum capacity factors for all hydrogen to power plants.
"""
function load_h2_g2p_variability(setup::Dict, path::AbstractString, sep::AbstractString, inputs_genvar::Dict)

	# Hourly capacity factors
	#data_directory = chop(replace(path, pwd() => ""), head = 1, tail = 0)
	data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory,"Load_data.csv")) && isfile(joinpath(data_directory,"Generators_variability.csv")) && isfile(joinpath(data_directory,"Fuels_data.csv")) && isfile(joinpath(data_directory,"HSC_load_data.csv")) && isfile(joinpath(data_directory,"HSC_generators_variability.csv")) && isfile(joinpath(data_directory,"HSC_g2p_variability.csv")) # Use Time Domain Reduced data for GenX
		gen_var = DataFrame(CSV.File(string(joinpath(data_directory,"HSC_g2p_variability.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		gen_var = DataFrame(CSV.File(string(path,sep,"HSC_g2p_variability.csv"), header=true), copycols=true)
	end

	# Reorder DataFrame to R_ID order (order provided in Generators_data.csv)
	select!(gen_var, [:Time_Index; Symbol.(inputs_genvar["H2_G2P_NAME"]) ])

	# Maximum power output and variability of each energy resource
	inputs_genvar["pH2_g2p_Max"] = transpose(Matrix{Float64}(gen_var[1:inputs_genvar["T"],2:(inputs_genvar["H2_G2P_ALL"]+1)]))

	println("HSC_g2p_variability.csv Successfully Read!")

	return inputs_genvar
end
