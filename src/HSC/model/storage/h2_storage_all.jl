function h2_storage_all(EP::Model, inputs::Dict, setup::Dict)
    # Setup variables, constraints, and expressions common to all hydrogen storage resources
    println("H2 Storage Core Resources Module")

    dfH2Gen = inputs["dfH2Gen"]
    H2_STOR_ALL = inputs["H2_STOR_ALL"] # Set of all h2 storage resources

    Z = inputs["Z"]     # Number of zones
    T = inputs["T"] # Number of time steps (hours) 

	  
    START_SUBPERIODS = inputs["START_SUBPERIODS"] # Starting subperiod index for each representative period
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] # Index of interior subperiod for each representative period

    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ### Variables ###
	# Storage level of resource "y" at hour "t" [tonne] on zone "z" 
	@variable(EP, vH2S[y in H2_STOR_ALL, t=1:T] >= 0);

	# Rate of energy withdrawn from HSC by resource "y" at hour "t" [tonne/hour] on zone "z"
	@variable(EP, vH2CHARGE_STOR[y in H2_STOR_ALL, t=1:T] >= 0);

    # No need to define temporal discharge variable since it is already defined in h2_outputs.jl as vH2Gen[k,t]


    # Energy losses related to storage technologies (increase in effective demand)
	#@expression(EP, eEH2LOSS[y in H2_STOR_ALL], sum(inputs["omega"][t]*EP[:vH2CHARGE_STOR][y,t] for t in 1:T) - sum(inputs["omega"][t]*EP[:vH2Gen][y,t] for t in 1:T))

    #Variable costs of "charging" for technologies "y" during hour "t" in zone "z"
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] ==1 
        @expression(EP, eCVarH2Stor_in[y in H2_STOR_ALL,t=1:T], 
        if (dfH2Gen[!,:H2Stor_Charge_MMBtu_p_tonne][y]>0) # Charging consumes fuel - fuel divided by 1000 since fuel cost already scaled in load_fuels_data.jl when ParameterScale =1
            inputs["omega"][t]*dfH2Gen[!,:Var_OM_Cost_Charge_p_tonne][y]*vH2CHARGE_STOR[y,t]/ModelScalingFactor^2 + inputs["fuel_costs"][dfH2Gen[!,:Fuel][k]][t] * dfH2Gen[!,:H2Stor_Charge_MMBtu_p_tonne][k]*vH2CHARGE_STOR[y,t]/ModelScalingFactor
        else
            inputs["omega"][t]*dfH2Gen[!,:Var_OM_Cost_Charge_p_tonne][y]*vH2CHARGE_STOR[y,t]/ModelScalingFactor^2
        end
        )
    else
        @expression(EP, eCVarH2Stor_in[y in H2_STOR_ALL,t=1:T], 
        if (dfH2Gen[!,:H2Stor_Charge_MMBtu_p_tonne][y]>0) # Charging consumes fuel 
            inputs["omega"][t]*dfH2Gen[!,:Var_OM_Cost_Charge_p_tonne][y]*vH2CHARGE_STOR[y,t] +inputs["fuel_costs"][dfH2Gen[!,:Fuel][k]][t] * dfH2Gen[!,:H2Stor_Charge_MMBtu_p_tonne][k]
        else
            inputs["omega"][t]*dfH2Gen[!,:Var_OM_Cost_Charge_p_tonne][y]*vH2CHARGE_STOR[y,t]
        end      
        )
    end

    # Sum individual resource contributions to variable charging costs to get total variable charging costs
    @expression(EP, eTotalCVarH2StorInT[t=1:T], sum(eCVarH2Stor_in[y,t] for y in H2_STOR_ALL))
    @expression(EP, eTotalCVarH2StorIn, sum(eTotalCVarH2StorInT[t] for t in 1:T))
    EP[:eObj] += eTotalCVarH2StorIn


    # Term to represent electricity consumption associated with H2 storage charging and discharging
	@expression(EP, ePowerBalanceH2Stor[t=1:T, z=1:Z],
    if setup["ParameterScale"] ==1 # If ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
        sum(EP[:vH2CHARGE_STOR][y,t]*dfH2Gen[!,:H2Stor_Charge_MWh_p_tonne][y] for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL); init=0.0)/ModelScalingFactor
    else
        sum(EP[:vH2CHARGE_STOR][y,t]*dfH2Gen[!,:H2Stor_Charge_MWh_p_tonne][y] for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL); init=0.0)
    end
    )

    EP[:ePowerBalance] += -ePowerBalanceH2Stor

    # Adding power consumption by storage
    EP[:eH2NetpowerConsumptionByAll] += ePowerBalanceH2Stor
 

   	#H2 Balance expressions
	@expression(EP, eH2BalanceStor[t=1:T, z=1:Z],
	sum(EP[:vH2Gen][k,t] -EP[:vH2CHARGE_STOR][k,t] for k in intersect(H2_STOR_ALL, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] += eH2BalanceStor   

    
    ### End Expressions ###

    ### Constraints ###
	## Storage energy capacity and state of charge related constraints:

	# Links state of charge in first time step with decisions in last time step of each subperiod
	# We use a modified formulation of this constraint (cSoCBalLongDurationStorageStart) when operations wrapping and long duration storage are being modeled
	
	if setup["OperationWrapping"] ==1 && !isempty(inputs["H2_STOR_LONG_DURATION"]) # Apply constraints to those storage technologies with short duration only
		@constraint(EP, cH2SoCBalStart[t in START_SUBPERIODS, y in H2_STOR_SHORT_DURATION], EP[:vH2S][y,t] ==
			EP[:vH2S][y,t+hours_per_subperiod-1]-(1/dfH2Gen[!,:H2Stor_eff_discharge][y]*EP[:vH2Gen][y,t])
			+(dfH2Gen[!,:H2Stor_eff_charge][y]*EP[:vH2CHARGE_STOR][y,t])-(dfH2Gen[!,:H2Stor_self_discharge_rate_p_hour][y]*EP[:vH2S][y,t+hours_per_subperiod-1]))
	else # Apply constraints to all storage technologies
		@constraint(EP, cH2SoCBalStart[t in START_SUBPERIODS, y in H2_STOR_ALL], EP[:vH2S][y,t] ==
			EP[:vH2S][y,t+hours_per_subperiod-1]-(1/dfH2Gen[!,:H2Stor_eff_discharge][y]*EP[:vH2Gen][y,t])
			+(dfH2Gen[!,:H2Stor_eff_charge][y]*EP[:vH2CHARGE_STOR][y,t])-(dfH2Gen[!,:H2Stor_self_discharge_rate_p_hour][y]*EP[:vH2S][y,t+hours_per_subperiod-1]))
	end
	
	@constraints(EP, begin

   		# Max and min storage inventory levels as proportion installed storage energy capacity
		[y in H2_STOR_ALL, t in 1:T], EP[:eTotalH2CapEnergy][y]*dfH2Gen[!,:H2Stor_max_level][y] >= EP[:vH2S][y,t]
		[y in H2_STOR_ALL, t in 1:T], EP[:eTotalH2CapEnergy][y]*dfH2Gen[!,:H2Stor_min_level][y] <= EP[:vH2S][y,t]

		# Maximum energy stored must be less than energy capacity - incorporate in earlier constraint
		#[y in H2_STOR_ALL, t in 1:T], EP[:vH2S][y,t] <= EP[:eTotalH2CapEnergy][y]

        # Maximum charging rate constrained by charging capacity
        [y in H2_STOR_ALL,t in 1:T], EP[:vH2CHARGE_STOR][y,t] <= EP[:eTotalH2CapCharge][y]

        # Constraint on maximum discharging rate imposed if storage discharging capital cost >0
        [y in intersect(H2_STOR_ALL,dfH2Gen[!,:Inv_Cost_p_tonne_p_hr_yr].>0), t in 1:T], EP[:vH2Gen][y,t] <= EP[:eH2GenTotalCap][y]

		# energy stored for the next hour
		cH2SoCBalInterior[t in INTERIOR_SUBPERIODS, y in H2_STOR_ALL], EP[:vH2S][y,t] ==
			EP[:vH2S][y,t-1]-(1/dfH2Gen[!,:H2Stor_eff_discharge][y]*EP[:vH2Gen][y,t])+(dfH2Gen[!,:H2Stor_eff_charge][y]*EP[:vH2CHARGE_STOR][y,t])-(dfH2Gen[!,:H2Stor_self_discharge_rate_p_hour][y]*EP[:vH2S][y,t-1])
	end)

    


    # Dev note: include later on additional parameters and constraints to limit rate of charging and discharging
    # Right now we leave it unconstrained
    # # H2 storage charge and discharge can not exceed injection and withdraw capacity
    # @constraints(
    #     EP,
    #     begin
    #         [s in STOR_ALL, t = 1:T], vH2StorCha[s, t] <= vH2StorRate[s]
    #         [s in STOR_ALL, t = 1:T], vH2StorCha[s, t] <= dfH2Gen[s, :InjectionRate_tonne_per_hour]
    #         [s in STOR_ALL, t = 1:T], vH2StorDis[s, t] <= dfH2Gen[s, :WithdrawalRate_tonne_per_hour]
    #     end
    # )


    ### End Constraints ###
    return EP
end
