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
	load_maximum_capacity_requirement(path::AbstractString,sep::AbstractString, inputs::Dict, setup::Dict)

Function for reading input parameters related to maximum capacity requirement constraints (e.g. technology specific deployment mandates).
"""
function load_maximum_capacity_requirement(path::AbstractString,sep::AbstractString, inputs::Dict, setup::Dict)
	#MinCapReq = CSV.read(string(path,sep,"Minimum_capacity_requirement.csv"), header=true)
	MaxCapReq = DataFrame(CSV.File(string(path, sep,"Maximum_capacity_requirement.csv"), header=true), copycols=true)
	NumberOfMaxCapReqs = size(collect(skipmissing(MinCapReq[!,:MaxCapReqConstraint])),1)
	
	inputs["NumberOfMaxCapReqs"] = NumberOfMaxCapReqs
	inputs["MaxCapReq"] = MaxCapReq[!,:Max_MW]
	
	if setup["ParameterScale"] == 1
		inputs["MaxCapReq"] = inputs["MaxCapReq"]/ModelScalingFactor # Convert to GW
	end

	print_and_log("Maximum_capacity_requirement.csv Successfully Read!")
	
	return inputs
end
