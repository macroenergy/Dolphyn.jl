
function h2_production_all(EP::Model, inputs::Dict, setup::Dict)

    dfH2Gen = inputs["dfH2Gen"]


    #Define sets
	H2_GEN_NEW_CAP = inputs["H2_GEN_NEW_CAP"] 
	H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"] 
    H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]


    #Capacity of Existing H2 Gen units (tonnes/hr)
    #For generation with unit commitment, this variable refers to the number of units, not capacity. 
	@variable(EP, vH2GenExistingCap[k in H2_RES_ALL] >= 0)
	#Capacity of New H2 Gen units (tonnes/hr)
	#For generation with unit commitment, this variable refers to the number of units, not capacity. 
	@variable(EP, vH2GenNewCap[k in H2_RES_ALL] >= 0)
	#Capacity of Retired H2 Gen units bui(tonnes/hr)
    #For generation with unit commitment, this variable refers to the number of units, not capacity. 
	@variable(EP, vH2GenRetCap[k in H2_RES_ALL] >= 0)
	
	### Expressions ###
	# Cap_Size is set to 1 for all variables when unit UCommit == 0
	# When UCommit > 0, Cap_Size is set to 1 for all variables except those where THERM == 1
	@expression(EP, eH2GenTotalCap[k in 1:H],
		if k in intersect(H2_GEN_NEW_CAP, H2_GEN_RET_CAP) # Resources eligible for new capacity and retirements
			if k in H2_GEN_COMMIT
				dfH2Gen[!,:Existing_Cap_Tonne_Hr][k] + dfH2Gen[!,:Cap_Size][k] * (EP[:vH2GenNewCap][k] - EP[:vH2GenRetCap][k])
			else
				dfH2Gen[!,:Existing_Cap_Tonne_Hr][k] + EP[:vH2GenNewCap][k] - EP[:vH2GenRetCap][k]
			end
		elseif k in setdiff(H2_GEN_NEW_CAP, H2_GEN_RET_CAP) # Resources eligible for only new capacity
			if k in H2_GEN_COMMIT
				dfH2Gen[!,:Existing_Cap_Tonne_Hr][k] + dfH2Gen[!,:Cap_Size][k] * EP[:vH2GenNewCap][k]
			else
				dfH2Gen[!,:Existing_Cap_Tonne_Hr][k] + EP[:vH2GenNewCap][k]
			end
		elseif k in setdiff(H2_GEN_RET_CAP, H2_GEN_NEW_CAP) # Resources eligible for only capacity retirements
			if k in H2_GEN_COMMIT
				dfH2Gen[!,:Existing_Cap_Tonne_Hr][k] - dfH2Gen[!,:Cap_Size][k] * EP[:vH2GenRetCap][k]
			else
				dfH2Gen[!,:Existing_Cap_Tonne_Hr][k] - EP[:vH2GenRetCap][k]
			end
		else 
			# Resources not eligible for new capacity or retirements
			dfH2Gen[!,:Existing_Cap_Tonne_Hr][k] 
		end
	)

	## Objective Function Expressions ##

	# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new capacity, fixed costs are only O&M costs
	@expression(EP, eH2GenCFix[k in 1:H],
		if k in H2_GEN_NEW_CAP # Resources eligible for new capacity
			if k in H2_GEN_COMMIT
				dfH2Gen[!,:Inv_Cost_per_tonnehr][k] * dfH2Gen[!,:Cap_Size][k] * vH2GenNewCap[k] + dfH2Gen[!,:Fixed_OM_Cost_per_tonnehr][k] * eH2GenTotalCap[k]
			else
				dfH2Gen[!,:Inv_Cost_per_tonnehr][k] * vH2GenNewCap[k] + dfH2Gen[!,:Fixed_OM_Cost_per_tonnehr][k] * eH2GenTotalCap[k]
			end
		else
			dfH2Gen[!,:Fixed_OM_Cost_per_tonnehr][k] * eH2GenTotalCap[k]
		end
	)



	# Sum individual resource contributions to fixed costs to get total fixed costs
	@expression(EP, eTotalH2GenCFix, sum(EP[:eH2GenCFix][k] for k in 1:H))

	# Add term to objective function expression
	EP[:eObj] += eTotalH2GenCFix


    return EP


end
