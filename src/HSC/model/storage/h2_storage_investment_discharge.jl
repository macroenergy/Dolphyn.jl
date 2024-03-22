function h2_storage_investment_discharge(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("H2 Storage Discharging Investment Module")

    dfH2Gen = inputs["dfH2Gen"]

    # For now, we're only going to apply this to underground H2 storage (STOR = 3)

    H2_STOR_ALL = inputs["H2_STOR_UHS"] # Set of H2 storage resources - all have asymmetric (separate) charge/discharge capacity components

    NEW_CAP_H2_STOR_DISCHARGE = inputs["NEW_CAP_H2_STOR_DISCHARGE"] # Set of asymmetric charge/discharge storage resources eligible for new charge capacity
    RET_CAP_H2_STOR_DISCHARGE = inputs["RET_CAP_H2_STOR_DISCHARGE"] # Set of asymmetric charge/discharge storage resources eligible for charge capacity retirements

    setup["ParameterScale"] == 1 ? SCALING = ModelScalingFactor : SCALING = 1

    ### Variables ###

    ## Storage capacity built and retired for storage resources with independent charge and discharge charge capacities (STOR=2)

    # New installed charge capacity of resource "y"
    @variable(EP, vH2CAPDISCHARGE[y in NEW_CAP_H2_STOR_DISCHARGE] >= 0)

    # Retired charge capacity of resource "y" from existing capacity
    @variable(EP, vH2RETCAPDISCHARGE[y in RET_CAP_H2_STOR_DISCHARGE] >= 0)

    ### Expressions ###
    # Total available charging capacity in tonnes/hour
    @expression(
        EP,
        eTotalH2CapDischarge[y in H2_STOR_ALL],
        if (y in intersect(NEW_CAP_H2_STOR_DISCHARGE, RET_CAP_H2_STOR_DISCHARGE))
            dfH2Gen[!, :Existing_Cap_tonne_p_hr][y] + EP[:vH2CAPDISCHARGE][y] -
            EP[:vH2RETCAPDISCHARGE][y]
        elseif (y in setdiff(NEW_CAP_H2_STOR_DISCHARGE, RET_CAP_H2_STOR_DISCHARGE))
            dfH2Gen[!, :Existing_Cap_tonne_p_hr][y] + EP[:vH2CAPDISCHARGE][y]
        elseif (y in setdiff(RET_CAP_H2_STOR_DISCHARGE, NEW_CAP_H2_STOR_DISCHARGE))
            dfH2Gen[!, :Existing_Cap_tonne_p_hr][y] - EP[:vH2RETCAPDISCHARGE][y]
        else
            dfH2Gen[!, :Existing_Cap_tonne_p_hr][y]
        end
    )

    ## Objective Function Expressions ##

    # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
    # If resource is not eligible for new charge capacity, fixed costs are only O&M costs
    # Sum individual resource contributions to fixed costs to get total fixed costs
    #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
    #  ParameterScale = 0 --> objective function is in $
    @expression(
        EP,
        eCFixH2Discharge[y in H2_STOR_ALL],
        if y in NEW_CAP_H2_STOR_DISCHARGE # Resources eligible for new charge capacity
            1 / SCALING^2 * (
                dfH2Gen[!, :Inv_Cost_p_tonne_p_hr_yr][y] * vH2CAPDISCHARGE[y] 
                + dfH2Gen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][y] * eTotalH2CapDischarge[y]
            )
        else
            1 / SCALING^2 * (
                dfH2Gen[!, :Fixed_OM_Cost_p_tonne_p_hr_yr][y] * eTotalH2CapDischarge[y]
            )
        end
    )

    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixH2Discharge, sum(EP[:eCFixH2Discharge][y] for y in H2_STOR_ALL))

    # Add term to objective function expression
    add_to_expression!(EP[:eObj], eTotalCFixH2Discharge)

    ### Constraints ###

    ## Constraints on retirements and capacity additions
    #Cannot retire more charge capacity than existing charge capacity
    @constraint(
        EP,
        cMaxRetH2Discharge[y in RET_CAP_H2_STOR_DISCHARGE],
        vH2RETCAPDISCHARGE[y] <= dfH2Gen[!, :Existing_Cap_tonne_p_hr][y]
    )

    # Constraints on new built capacity

    # Constraint on maximum charge capacity (if applicable) [set input to -1 if no constraint on maximum charge capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Charge_Cap_MW is >= Max_Charge_Cap_MWh and lead to infeasabilty
    @constraint(
        EP,
        cMaxCapH2Discharge[y in intersect(
            dfH2Gen[!, :Max_Cap_tonne_p_hr] .> 0,
            H2_STOR_ALL,
        )],
        eTotalH2CapDischarge[y] <= dfH2Gen[!, :Max_Cap_tonne_p_hr][y]
    )

    # Constraint on minimum charge capacity (if applicable) [set input to -1 if no constraint on minimum charge capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Charge_Cap_MW is <= Min_Charge_Cap_MWh and lead to infeasabilty
    @constraint(
        EP,
        cMinCapH2Discharge[y in intersect(
            dfH2Gen[!, :Min_Cap_tonne_p_hr] .> 0,
            H2_STOR_ALL,
        )],
        eTotalH2CapDischarge[y] >= dfH2Gen[!, :Min_Cap_tonne_p_hr][y]
    )

    return EP
end
