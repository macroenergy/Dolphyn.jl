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

function write_h2_balance_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	# # Dual of storage level (state of charge) balance of each resource in each time step
	dfH2BalanceDual = DataFrame(Zone = 1:Z)
	# Define an empty array
	x1 = Array{Float64}(undef, Z, T)
	dual_values =Array{Float64}(undef, Z, T)

	# Loop over W separately hours_per_subperiod
	for z in 1:Z
		for t in 1:T
			x1[z,t] = dual.(EP[:cH2Balance])[t,z] #Use this for getting dual values and put in the extracted codes from PJM
		end
	end

	# Incorporating effect of time step weights (When OperationWrapping=1) and Parameter scaling (ParameterScale=1) on dual variables
	if setup["ParameterScale"]==1
		x1 = x1 * ModelScalingFactor
	end

	dual_values .= x1 ./inputs["omega"]

	dfH2BalanceDual=hcat(dfH2BalanceDual, DataFrame(dual_values, :auto))
	rename!(dfH2BalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

	CSV.write(string(path,sep,"HSC_h2_balance_dual.csv"), dftranspose(dfH2BalanceDual, false), writeheader=false)

end
