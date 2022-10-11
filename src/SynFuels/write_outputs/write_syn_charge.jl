"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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
	write_h2_charge(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

Function for writing the h2 storage charging energy values of the different storage technologies.
"""
function write_syn_charge(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

	dfSynGen = inputs["dfSynGen"]

	H = inputs["SYN_RES_ALL"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	# Power withdrawn to charge each resource in each time step
	dfCharge = DataFrame(Resource = inputs["SYN_RESOURCES_NAME"], Zone = dfSynGen[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))
	charge = zeros(H,T)
	for i in 1:H
        if i in inputs["SYN_STOR_ALL"]
            charge[i,:] = value.(EP[:vSyn_CHARGE_STOR])[i,:]
        elseif i in inputs["SYN_FLEX"]
            charge[i,:] = value.(EP[:vSyn_CHARGE_FLEX])[i,:]
        end

		dfCharge[!,:AnnualSum][i] = sum(inputs["omega"].* charge[i,:])
	end
	dfCharge = hcat(dfCharge, DataFrame(charge, :auto))
	auxNew_Names=[Symbol("Resource");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
	rename!(dfCharge,auxNew_Names)
	total = DataFrame(["Total" 0 sum(dfCharge[!,:AnnualSum]) fill(0.0, (1,T))], :auto)
	for t in 1:T
		if v"1.3" <= VERSION < v"1.4"
			total[!,t+3] .= sum(dfCharge[!,Symbol("t$t")][union(inputs["SYN_STOR_ALL"],inputs["SYN_FLEX"])])
		elseif v"1.4" <= VERSION < v"1.8"
			total[:,t+3] .= sum(dfCharge[:,Symbol("t$t")][union(inputs["SYN_STOR_ALL"],inputs["SYN_FLEX"])])
		end
	end
	rename!(total,auxNew_Names)
	dfCharge = vcat(dfCharge, total)

	CSV.write(joinpath(path, "Syn_fuels_charge.csv"), dftranspose(dfCharge, false), writeheader=false)

	return dfCharge
end
