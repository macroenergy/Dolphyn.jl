@doc raw"""
	h2_generation(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

The h2 generation module creates decision variables, expressions, and constraints related to hydrogen generation infrastructure
- Investment and FOM cost expression, VOM cost expression, minimum and maximum capacity limits
"""
function h2_production_all(EP::Model, inputs::Dict, setup::Dict)

	dfH2Gen = inputs["dfH2Gen"]

	#Define sets
	H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
	H2_PROD = inputs["H2_PROD"]

	H = inputs["H2_GEN"] #Number of Hydrogen gen units
	T = inputs["T"]     # Number of time steps (hours)

	####Variables####
	#Define variables needed across both commit and no commit sets

#	#H2 generation from hydrogen generation resource k (tonnes of H2/hr)
#	@variable(EP, vH2Gen[k in H2_GEN_ALL, t = 1:T] >= 0 )
    #Power required by hydrogen generation resource k to make hydrogen (MW)
	@variable(EP, vP2G[k in H2_PROD, t = 1:T] >= 0 )
	#Gas required by hydrogen generation resource k to make hydrogen (MMBtu/hr)
    @variable(EP, vGas[k in H2_PROD, t = 1:T] >= 0 )


	### Constratints ###

	## Constraints on retirements and capacity additions
	# Cannot retire more capacity than existing capacity
	@constraint(EP, cH2GenMaxRetNoCommit[k in setdiff(H2_GEN_RET_CAP, H2_GEN_COMMIT)], vH2GenRetCap[k] <= dfH2Gen[!,:Existing_Cap_Tonne_Hr][k])
	@constraint(EP, cH2GenMaxRetCommit[k in intersect(H2_GEN_RET_CAP, H2_GEN_COMMIT)], dfH2Gen[!,:Cap_Size][k] * vH2GenRetCap[k] <= dfH2Gen[!,:Existing_Cap_Tonne_Hr][k])

	## Constraints on new built capacity
	# Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
	@constraint(EP, cH2GenMaxCap[k in intersect(dfH2Gen[dfH2Gen.Max_Cap_Tonne_Hr.>0,:R_ID], 1:H)], eH2GenTotalCap[k] <= dfH2Gen[!,:Max_Cap_Tonne_Hr][k])

	# Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is <= Min_Cap_MW and lead to infeasabilty
	@constraint(EP, cH2GenMinCap[k in intersect(dfH2Gen[dfH2Gen.Min_Cap_Tonne_Hr.>0,:R_ID], 1:H)], eH2GenTotalCap[k] >= dfH2Gen[!,:Min_H2Gen][k])

	return EP

end