"""
GenX: An Configurable Capacity Expansion Model
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
	load_generators_variability(path::AbstractString, setup::Dict, inputs::Dict)

Function for reading input parameters related to hourly maximum capacity factors for all generators (plus storage and flexible demand resources)
"""
function load_h2_g2p_variability(path::AbstractString, setup::Dict, inputs::Dict)

	# Hourly capacity factors
	if setup["TimeDomainReduction"] == 1
		gen_var = DataFrame(CSV.File(joinpath(path, "HSC_g2p_variability.csv"), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		gen_var = DataFrame(CSV.File(joinpath(path, "HSC_g2p_variability.csv"), header=true), copycols=true)
	end

	# Reorder DataFrame to R_ID order (order provided in Generators_data.csv)
	select!(gen_var, [:Time_Index; Symbol.(inputs["H2_G2P_NAME"]) ])

	# Maximum power output and variability of each energy resource
	inputs["pH2_g2p_Max"] = transpose(Matrix{Float64}(gen_var[1:inputs["T"],2:(inputs["H2_G2P_ALL"]+1)]))

	println("HSC_g2p_variability.csv Successfully Read!")

	return inputs
end
