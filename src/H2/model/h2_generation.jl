function h2_generation_commit(EP::Model, inputs::Dict, setup::Dict)

	#Rename H2Gen dataframe
	dfH2Gen = inputs["dfH2Gen"]
	UCommit = setup["UCommit"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	H = inputs["H"]		#NUmber of hydrogen generation units 
	
	H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
	H2_GEN_NO_COMMIT = inputs["H2_GEN_NO_COMMIT"]
	H2_GEN_NEW_CAP = inputs["H2_GEN_NEW_CAP"] 
	H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"] 
	
	#Define start subperiods and interior subperiods
	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod


	# commitment state variable
	@variable(EP, vH2GenCOMMIT[k in H2_GEN_COMMIT, t=1:T] >= 0)
	# Start up variable
	@variable(EP, vH2GenStart[k in H2_GEN_COMMIT, t=1:T] >= 0)
	# Shutdown Variable
	@variable(EP, vH2GenShut[k in H2_GEN_COMMIT, t=1:T] >= 0)

	### Constratints ###
	## Declaration of integer/binary variables
	if UCommit == 1 # Integer UC constraints
		for k in H2_GEN_COMMIT
			set_integer.(vH2GenCOMMIT[k,:])
			set_integer.(vH2GenStart[k,:])
			set_integer.(vH2GenShut[k,:])
			if k in H2_GEN_RET_CAP
				set_integer(EP[:vH2GenRetCap][k])
			end
			if k in H2_GEN_NEW_CAP 
				set_integer(EP[:vH2GenNewCap][k])
			end
		end
	end #END unit commitment configuration

	###Expressions###

	#Objective function expressions
	# Startup costs of "generation" for resource "y" during hour "t"
	@expression(EP, eH2GenCStart[k in H2_GEN_COMMIT, t=1:T],(inputs["omega"][t]*inputs["C_H2_Start"][k]*vH2GenStart[k,t]))

	# Julia is fastest when summing over one row one column at a time
	@expression(EP, eTotalH2GenCStartT[t=1:T], sum(eH2GenCStart[k,t] for k in H2_GEN_COMMIT))
	@expression(EP, eTotalH2GenCStart, sum(eTotalH2GenCStartT[t] for t=1:T))

	EP[:eObj] += eTotalH2GenCStart

	#H2 Balance expressions
	@expression(EP, eH2GenCommit[t=1:T, z=1:Z],
	sum(EP[:vH2Gen][k,t] for k in intersect(H2_GEN_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] += eH2GenCommit

	#Power Consumption H2 Generation balance
	#Add more comments to make this more descriptive
	@expression(EP, ePowerBalanceH2GenCommit[t=1:T, z=1:Z],
	sum(EP[:vP2G][k,t] for k in intersect(H2_GEN_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]))) 

	EP[:ePowerBalance] += ePowerBalanceH2GenCommit

	### Capacitated limits on unit commitment decision variables (Constraints #1-3)
	@constraints(EP, begin
		[k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenCOMMIT][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size][k]
		[k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenStart][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size][k]
		[k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenShut][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size][k]
	end)

	# Commitment state constraint linking startup and shutdown decisions (Constraint #4)
	@constraints(EP, begin
	# For Start Hours, links first time step with last time step in subperiod
	[k in H2_GEN_COMMIT, t in START_SUBPERIODS], EP[:vH2GenCOMMIT][k,t] == EP[:vH2GenCOMMIT][k,(t+hours_per_subperiod-1)] + EP[:vH2GenStart][k,t] - EP[:vH2GenShut][k,t]
	# For all other hours, links commitment state in hour t with commitment state in prior hour + sum of start up and shut down in current hour
	[k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2GenCOMMIT][k,t] == EP[:vH2GenCOMMIT][k,t-1] + EP[:vH2GenStart][k,t] - EP[:vH2GenShut][k,t]
	end)


	### Maximum ramp up and down between consecutive hours (Constraints #5-6)

	## For Start Hours
	# Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
	# rampup constraints
	@constraint(EP,[k in H2_GEN_COMMIT, t in START_SUBPERIODS],
	EP[:vH2Gen][k,t]-EP[:vH2Gen][k,(t+hours_per_subperiod-1)] <= dfH2Gen[!,:Ramp_Up_Percentage][k] * dfH2Gen[!,:Cap_Size][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
	+ min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:Min_Cap_Tonne_Hr][k],dfH2Gen[!,:Ramp_Up_Percentage][k]))*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenStart][k,t]
	- dfH2Gen[!,:Min_Cap_Tonne_Hr][k] * dfH2Gen[!,:Cap_Size][k] * EP[:vH2GenShut][k,t])

	# rampdown constraints
	@constraint(EP,[k in H2_GEN_COMMIT, t in START_SUBPERIODS],
	EP[:vH2Gen][k,(t+hours_per_subperiod-1)]-EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k]*dfH2Gen[!,:Cap_Size][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
	- dfH2Gen[!,:Min_Cap_Tonne_Hr][k]*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenStart][k,t]
	+ min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:Min_Cap_Tonne_Hr][k],dfH2Gen[!,:Ramp_Down_Percentage][k]))*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenShut][k,t])

	## For Interior Hours
	# rampup constraints
	@constraint(EP,[k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS],
		EP[:vH2Gen][k,t]-EP[:vH2Gen][k,t-1] <= dfH2Gen[!,:Ramp_Up_Percentage][k]*dfH2Gen[!,:Cap_Size][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
			+ min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:Min_Cap_Tonne_Hr][k],dfH2Gen[!,:Ramp_Up_Percentage][k]))*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenStart][k,t]
			-dfH2Gen[!,:Min_Cap_Tonne_Hr][k]*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenShut][k,t])

	# rampdown constraints
	@constraint(EP,[k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS],
	EP[:vH2Gen][k,t-1]-EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k]*dfH2Gen[!,:Cap_Size][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
	-dfH2Gen[!,:Min_Cap_Tonne_Hr][k]*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenStart][k,t]
	+min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:Min_Cap_Tonne_Hr][k],dfH2Gen[!,:Ramp_Down_Percentage][k]))*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenShut][k,t])

	@constraints(EP, begin
	# Minimum stable power generated per technology "k" at hour "t" > Min power
	[k in H2_GEN_COMMIT, t=1:T], EP[:vH2Gen][k,t] >= dfH2Gen[!,:Cap_Size][k] * EP[:vH2GenCOMMIT][k,t]
	# Maximum power generated per technology "k" at hour "t" < Max power
	[k in H2_GEN_COMMIT, t=1:T], EP[:vH2Gen][k,t] <= dfH2Gen[!,:Cap_Size][k] * EP[:vH2GenCOMMIT][k,t] * inputs["pH2_Max"][k,t]
	end)
	return EP

end


function h2_generation_no_commit(EP::Model, inputs::Dict)

	#Rename H2Gen dataframe
	dfH2Gen = inputs["dfH2Gen"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	H = inputs["H2_GEN"]		#NUmber of hydrogen generation units 
	
	H2_GEN_NO_COMMIT = inputs["H2_GEN_NO_COMMIT"]
	
	#Define start subperiods and interior subperiods
	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

	###Expressions###

	#H2 Balance expressions
	@expression(EP, eH2GenNoCommit[t=1:T, z=1:Z],
	sum(EP[:vH2Gen][k,t] for k in intersect(H2_GEN_NO_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] += eH2GenNoCommit

	#Power Consumption H2 Generation balance
	#Add more comments to make this more descriptive
	@expression(EP, ePowerBalanceH2GenNoCommit[t=1:T, z=1:Z],
	sum(EP[:vP2G][k,t] for k in intersect(H2_GEN_NO_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]))) 

	EP[:ePowerBalance] += ePowerBalanceH2GenNoCommit
	
	###Constraints###
	@constraints(EP, begin
		#Power Balance
		[k in H2_GEN_NO_COMMIT, t = 1:T], EP[:vP2G][k,t] == EP[:vH2Gen][k,t] * dfH2Gen[!,:etaP2G_MWh_per_tonne][k]
		#Gas Balance
		[k in H2_GEN_NO_COMMIT, t = 1:T], EP[:vGas][k,t] == EP[:vH2Gen][k,t] * dfH2Gen[!,:etaGas_MMBtu_per_tonne][k]
		#Output must not exceed units capacity 
		[k in H2_GEN_NO_COMMIT, t = 1:T], EP[:vH2Gen][k,t] <= EP[:eH2GenTotalCap][k] * inputs["pH2_Max"][k,t]
	end)
	
	@constraints(EP, begin
	# Maximum power generated per technology "k" at hour "t"
	[k in H2_GEN_NO_COMMIT, t=1:T], EP[:vH2Gen][k,t] <= EP[:eH2GenTotalCap][k]
	end)

	#Ramping cosntraints 
	@constraints(EP, begin

		## Maximum ramp up between consecutive hours
		# Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
		# NOTE: We should make wrap-around a configurable option
		[k in H2_GEN_NO_COMMIT, t in START_SUBPERIODS], EP[:vH2Gen][k,t]-EP[:vH2Gen][k,(t + hours_per_subperiod-1)] <= dfH2Gen[!,:Ramp_Up_Percentage][k] * EP[:eH2GenTotalCap][k]

		# Interior Hours
		[k in H2_GEN_NO_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2Gen][k,t]-EP[:vH2Gen][k,t-1] <= dfH2Gen[!,:Ramp_Up_Percentage][k]*EP[:eH2GenTotalCap][k]

		## Maximum ramp down between consecutive hours
		# Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
		[k in H2_GEN_NO_COMMIT, t in START_SUBPERIODS], EP[:vH2Gen][k,(t+hours_per_subperiod-1)] - EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k] * EP[:eH2GenTotalCap][k]

		# Interior Hours
		[k in H2_GEN_NO_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2Gen][k,t-1] - EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k] * EP[:eH2GenTotalCap][k]
	
	end)

	return EP

end


@doc raw"""
	h2_generation(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

The h2 generation module creates decision variables, expressions, and constraints related to hydrogen generation infrastructure
"""
function h2_generation(EP::Model, inputs::Dict, setup::Dict)

	dfH2Gen = inputs["dfH2Gen"]

	#Define sets
	H2_GEN_NO_COMMIT = inputs["H2_GEN_NO_COMMIT"]
	H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
	H2_GEN_ALL = inputs["H2_GEN_ALL"]
	H2_GEN_NEW_CAP = inputs["H2_GEN_NEW_CAP"] 
	H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"] 

	H = inputs["H2_GEN"] #Number of Hydrogen gen units
	T = inputs["T"]     # Number of time steps (hours)

	####Variables####
	#Define variables needed across both commit and no commit sets

	#H2 generation from hydrogen generation resource k (tonnes of H2/hr)
	@variable(EP, vH2Gen[k in H2_GEN_ALL, t = 1:T] >= 0 )
    #Power required by hydrogen generation resource k to make hydrogen (MW)
	@variable(EP, vP2G[k in H2_GEN_ALL, t = 1:T] >= 0 )
	#Gas required by hydrogen generation resource k to make hydrogen (MMBtu/hr)
    @variable(EP, vGas[k in H2_GEN_ALL, t = 1:T] >= 0 )
	#Capacity of Existing H2 Gen units (tonnes/hr)
	@variable(EP, vH2GenExistingCap[k in H2_GEN_ALL] >= 0)
	#Capacity of New H2 Gen units (tonnes/hr)
	#For generation with unit commitment, this variable refers to the number of units, not capacity. 
	@variable(EP, vH2GenNewCap[k in H2_GEN_ALL] >= 0)
	#Capacity of Retired H2 Gen units bui(tonnes/hr)
	@variable(EP, vH2GenRetCap[k in H2_GEN_ALL] >= 0)
	
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

	# Variable costs of "generation" for resource "y" during hour "t" = variable O&M plus fuel cost
	@expression(EP, eCH2GenVar_out[k = 1:H,t = 1:T], 
	(inputs["omega"][t] * ((dfH2Gen[!,:Var_OM_Cost_per_tonne][k] + inputs["fuel_costs"][dfH2Gen[!,:Fuel][k]][t]) * dfH2Gen[!,:etaGas_MMBtu_per_tonne][k]) * vH2Gen[k,t]))

	@expression(EP, eTotalCH2GenVarOutT[t=1:T], sum(eCH2GenVar_out[k,t] for k in 1:H))
	@expression(EP, eTotalCH2GenVarOut, sum(eTotalCH2GenVarOutT[t] for t in 1:T))
	
	# Add total variable discharging cost contribution to the objective function
	EP[:eObj] += eTotalCH2GenVarOut

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
	@constraint(EP, cH2GenMinCap[k in intersect(dfH2Gen[dfH2Gen.Min_Cap_Tonne_Hr.>0,:R_ID], 1:H)], eH2GenTotalCap[k] >= dfH2Gen[!,:Min_Cap_Tonne_Hr][k])

	if !isempty(H2_GEN_COMMIT)
		EP = h2_generation_commit(EP::Model, inputs::Dict, setup::Dict)
	end

	if !isempty(H2_GEN_NO_COMMIT)
		EP = h2_generation_no_commit(EP::Model, inputs::Dict)
	end

	return EP

end

