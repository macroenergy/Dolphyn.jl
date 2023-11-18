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
    write_co2_capture_outflow_balance_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

This file is responsible for writing the duals of the equality constraint related to the capture flow balance that is computed at 
the zonal level    
"""
function write_co2_capture_outflow_balance_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones

    # # Dual of storage level (state of charge) balance of each resource in each time step
    dfCO2BalanceDual = DataFrame(Zone = 1:Z)
    # Define an empty array
    x1 = Array{Float64}(undef, Z, T)
    dual_values =Array{Float64}(undef, Z, T)

    # Loop over W separately hours_per_subperiod
    for z in 1:Z
        for t in 1:T
            x1[z,t] = dual.(EP[:cCapturedCO2Balance])[t,z] #Use this for getting dual values and put in the extracted codes from PJM
        end
    end

    # Incorporating effect of time step weights (When OperationWrapping=1) and Parameter scaling (ParameterScale=1) on dual variables
    for z in 1:Z
        if setup["ParameterScale"]==1
            dual_values[z,:] = x1[z,:]./inputs["omega"] *ModelScalingFactor
        else
            dual_values[z,:] = x1[z,:]./inputs["omega"]
        end
    end


	dfCO2BalanceDual=hcat(dfCO2BalanceDual, DataFrame(dual_values, :auto))
    rename!(dfCO2BalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

	CSV.write(string(path,sep,"CSC_co2_capture_outflow_balance_dual.csv"), dftranspose(dfCO2BalanceDual, false), writeheader=false)

end
