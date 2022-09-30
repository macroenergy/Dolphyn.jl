"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021, Massachusetts Institute of Technology and Peking University
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	h2_generation(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

The h2 generation module creates decision variables, expressions, and constraints related to hydrogen generation infrastructure
- Investment and FOM cost expression, VOM cost expression, minimum and maximum capacity limits
"""
function h2_production_all(EP::Model, inputs::Dict, setup::Dict)

	println("H2 Production Core Module")

	dfH2Gen = inputs["dfH2Gen"]

	#Define sets
	H2_GEN_NO_COMMIT= inputs["H2_GEN_NO_COMMIT"]
	H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
	H2_GEN = inputs["H2_GEN"]
	H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"]
	H =inputs["H2_RES_ALL"]

	T = inputs["T"]     # Number of time steps (hours)

	####Variables####
	#Define variables needed across both commit and no commit sets

    #Power required by hydrogen generation resource k to make hydrogen (MW)
	@variable(EP, vP2G[k in H2_GEN, t = 1:T] >= 0)

	### Constratints ###

	## Constraints on retirements and capacity additions
	# Cannot retire more capacity than existing capacity
	@constraint(EP, cH2GenMaxRetNoCommit[k in setdiff(H2_GEN_RET_CAP, H2_GEN_NO_COMMIT)], EP[:vH2GenRetCap][k] <= dfH2Gen[!,:Existing_Cap_tonne_p_hr][k])
	@constraint(EP, cH2GenMaxRetCommit[k in intersect(H2_GEN_RET_CAP, H2_GEN_COMMIT)], dfH2Gen[!,:Cap_Size_tonne_p_hr][k] * EP[:vH2GenRetCap][k] <= dfH2Gen[!,:Existing_Cap_tonne_p_hr][k])

	## Constraints on new built capacity
	# Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
	@constraint(EP, cH2GenMaxCap[k in intersect(dfH2Gen[dfH2Gen.Max_Cap_tonne_p_hr.>0,:R_ID], 1:H)],EP[:eH2GenTotalCap][k] <= dfH2Gen[!,:Max_Cap_tonne_p_hr][k])

	# Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is <= Min_Cap_MW and lead to infeasabilty
	@constraint(EP, cH2GenMinCap[k in intersect(dfH2Gen[dfH2Gen.Min_Cap_tonne_p_hr.>0,:R_ID], 1:H)], EP[:eH2GenTotalCap][k] >= dfH2Gen[!,:Min_Cap_tonne_p_hr][k])

	return EP

end
