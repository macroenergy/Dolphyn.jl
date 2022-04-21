function co2_storage_all(EP::Model, inputs::Dict, setup::Dict)
    # Setup variables, constraints, and expressions common to all carbon storage resources
    println("Carbon Storage Core Resources Module")

    dfCO2Stor = inputs["dfCO2Stor"]
    CO2_STOR_ALL = inputs["CO2_STOR_ALL"] # Set of all co2 storage resources

    Z = inputs["Z"]     # Number of zones
    T = inputs["T"] # Number of time steps (hours) 

	  
    START_SUBPERIODS = inputs["START_SUBPERIODS"] # Starting subperiod index for each representative period
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] # Index of interior subperiod for each representative period

    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ### Variables ###
	# Storage level of resource "y" at hour "t" [tonne] on zone "z" 
	@variable(EP, vCO2S[y in CO2_STOR_ALL, t=1:T] >= 0);

	# Rate of carbon withdrawn from CSC by resource "y" at hour "t" [tonne/hour] on zone "z"
	@variable(EP, vCO2CHARGE_STOR[y in CO2_STOR_ALL, t=1:T] >= 0);

    # Carbon losses related to storage technologies (increase in effective demand)
	#@expression(EP, eECO2LOSS[y in CO2_STOR_ALL], sum(inputs["omega"][t]*EP[:vCO2CHARGE_STOR][y,t] for t in 1:T) )

    #Variable costs of "charging" for technologies "y" during hour "t" in zone "z"
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] ==1 
        @expression(EP, eCVarCO2Stor_in[y in CO2_STOR_ALL,t=1:T], 
        if (dfCO2Stor[!,:CO2Stor_Charge_MMBtu_p_tonne][y]>0) # Charging consumes fuel - fuel divided by 1000 since fuel cost already scaled in load_fuels_data.jl when ParameterScale =1
            inputs["omega"][t]*dfCO2Stor[!,:Var_OM_Cost_Charge_p_tonne][y]*vCO2CHARGE_STOR[y,t]/ModelScalingFactor^2 + inputs["fuel_costs"][dfCO2Stor[!,:Fuel][y]][t] * dfCO2Stor[!,:CO2Stor_Charge_MMBtu_p_tonne][y]*vCO2CHARGE_STOR[y,t]/ModelScalingFactor
        else
            inputs["omega"][t]*dfCO2Stor[!,:Var_OM_Cost_Charge_p_tonne][y]*vCO2CHARGE_STOR[y,t]/ModelScalingFactor^2
        end
        )
    else
        @expression(EP, eCVarCO2Stor_in[y in CO2_STOR_ALL,t=1:T], 
        if (dfCO2Stor[!,:CO2Stor_Charge_MMBtu_p_tonne][y]>0) # Charging consumes fuel 
            inputs["omega"][t]*dfCO2Stor[!,:Var_OM_Cost_Charge_p_tonne][y]*vCO2CHARGE_STOR[y,t] +inputs["fuel_costs"][dfCO2Stor[!,:Fuel][y]][t] * dfCO2Stor[!,:CO2Stor_Charge_MMBtu_p_tonne][y]
        else
            inputs["omega"][t]*dfCO2Stor[!,:Var_OM_Cost_Charge_p_tonne][y]*vCO2CHARGE_STOR[y,t]
        end      
        )
    end

    # Sum individual resource contributions to variable charging costs to get total variable charging costs
    @expression(EP, eTotalCVarCO2StorInT[t=1:T], sum(eCVarCO2Stor_in[y,t] for y in CO2_STOR_ALL))
    @expression(EP, eTotalCVarCO2Stor, sum(eTotalCVarCO2StorInT[t] for t in 1:T))
    EP[:eObj] += eTotalCVarCO2Stor


    # Term to represent electricity consumption associated with CO2 storage charging and discharging
	@expression(EP, ePowerBalanceCO2Stor[t=1:T, z=1:Z],
    if setup["ParameterScale"] ==1 # If ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
        sum(EP[:vCO2CHARGE_STOR][y,t]*dfCO2Stor[!,:CO2Stor_Charge_MWh_p_tonne][y]/ModelScalingFactor for y in intersect(dfCO2Stor[dfCO2Stor.Zone.==z,:R_ID],CO2_STOR_ALL); init=0.0)
    else
        sum(EP[:vCO2CHARGE_STOR][y,t]*dfCO2Stor[!,:CO2Stor_Charge_MWh_p_tonne][y] for y in intersect(dfCO2Stor[dfCO2Stor.Zone.==z,:R_ID],CO2_STOR_ALL); init=0.0)
    end
    )

    EP[:ePowerBalance] += -ePowerBalanceCO2Stor

    # Adding power consumption by storage
    EP[:eCO2NetpowerConsumptionByAll] += ePowerBalanceCO2Stor
 

   	#CO2 Balance expressions
	@expression(EP, eCO2BalanceStor[t=1:T, z=1:Z],
	sum(EP[:vCO2CHARGE_STOR][k,t] for k in intersect(CO2_STOR_ALL, dfCO2Stor[dfCO2Stor[!,:Zone].==z,:][!,:R_ID])))

    #Activate only when CO2 demand is online
	EP[:eCO2BalanceStorTotal] += eCO2BalanceStor   

    ### End Expressions ###

    ### Constraints ###
	## Storage carbon capacity and state of charge related constraints:

	# Links state of charge in first time step with decisions in last time step of each subperiod
	# We use a modified formulation of this constraint (cSoCBalLongDurationStorageStart) when operations wrapping and long duration storage are being modeled
	
	if setup["OperationWrapping"] ==1 && !isempty(inputs["CO2_STOR_LONG_DURATION"]) # Apply constraints to those storage technologies with short duration only
		@constraint(EP, cCO2SoCBalStart[t in START_SUBPERIODS, y in CO2_STOR_SHORT_DURATION], EP[:vCO2S][y,t] ==
			EP[:vCO2S][y,t+hours_per_subperiod-1] + (dfCO2Stor[!,:CO2Stor_eff_charge][y]*EP[:vCO2CHARGE_STOR][y,t]))
            #-(dfCO2Stor[!,:CO2Stor_self_discharge_rate_p_hour][y]*EP[:vCO2S][y,t+hours_per_subperiod-1]))

	else # Apply constraints to all storage technologies
		@constraint(EP, cCO2SoCBalStart[t in START_SUBPERIODS, y in CO2_STOR_ALL], EP[:vCO2S][y,t] ==
			EP[:vCO2S][y,t+hours_per_subperiod-1] + (dfCO2Stor[!,:CO2Stor_eff_charge][y]*EP[:vCO2CHARGE_STOR][y,t]))
            #-(dfCO2Stor[!,:CO2Stor_self_discharge_rate_p_hour][y]*EP[:vCO2S][y,t+hours_per_subperiod-1]))
	end
	
	@constraints(EP, begin

   		# Max and min storage inventory levels as proportion installed storage carbon capacity
		[y in CO2_STOR_ALL, t in 1:T], EP[:eTotalCO2CapCarbon][y]*dfCO2Stor[!,:CO2Stor_max_level][y] >= EP[:vCO2S][y,t]
		[y in CO2_STOR_ALL, t in 1:T], EP[:eTotalCO2CapCarbon][y]*dfCO2Stor[!,:CO2Stor_min_level][y] <= EP[:vCO2S][y,t]

        # Maximum charging rate constrained by charging capacity
        [y in CO2_STOR_ALL,t in 1:T], EP[:vCO2CHARGE_STOR][y,t] <= EP[:eTotalCO2CapCharge][y]

		# Carbon stored for the next hour
		cCO2SoCBalInterior[t in INTERIOR_SUBPERIODS, y in CO2_STOR_ALL], EP[:vCO2S][y,t] ==
			EP[:vCO2S][y,t-1] + (dfCO2Stor[!,:CO2Stor_eff_charge][y]*EP[:vCO2CHARGE_STOR][y,t])
            #-(dfCO2Stor[!,:CO2Stor_self_discharge_rate_p_hour][y]*EP[:vCO2S][y,t-1])
	end)

    


    # Dev note: include later on additional parameters and constraints to limit rate of charging and discharging
    # Right now we leave it unconstrained
    # # CO2 storage charge and discharge can not exceed injection capacity
    # @constraints(
    #     EP,
    #     begin
    #         [s in STOR_ALL, t = 1:T], vCO2StorCha[s, t] <= vCO2StorRate[s]
    #         [s in STOR_ALL, t = 1:T], vCO2StorCha[s, t] <= dfCO2Stor[s, :InjectionRate_tonne_per_hour]
    #     end
    # )


    ### End Constraints ###
    return EP
end
