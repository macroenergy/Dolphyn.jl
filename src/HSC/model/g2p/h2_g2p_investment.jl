

@doc raw"""
    h2_g2p_investment(EP::Model, inputs::Dict, setup::Dict)

This function defines the expressions and constraints keeping track of total available hydrogen to power generation capacity $y_{k}^{\textrm{H,G2P}}$ as well as constraints on capacity retirements.

The total capacity of hydrogen to power generation is defined as the sum of the existing capacity plus the newly invested capacity minus any retired capacity.

```math
\begin{equation*}
    \begin{split}
    y_{g, z}^{\textrm{H,G2P}} &= y_{g, z}^{\textrm{H,G2P},total} \\ 
    & = y_{g, z}^{\textrm{H,G2P,existing}}+y_{g, z}^{\textrm{H,G2P,new}}-y_{g, z}^{\textrm{H,G2P,retired}}
    \end{split}
    \quad \forall g \in \mathcal{G}, z \in \mathcal{Z}
\end{equation*}
```

**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of generation (fixed OM plus investment costs) from all generation resources $g \in \mathcal{G}$ (thermal, renewable, storage, DR, flexible demand resources and hydro):

```math
\begin{equation*}
    C^{\textrm{H,G2P},c} = \sum_{g \in \mathcal{G}} \sum_{z \in \mathcal{Z}} y_{g, z}^{\textrm{H,G2P,new}}\times \textrm{c}_{g}^{\textrm{E,INV}} + \sum_{g \in \mathcal{G}} y_{g, z}^{\textrm{H,G2P,total}}\times \textrm{c}_{g}^{E,FOM}
\end{equation*}
```
"""
function h2_g2p_investment(EP::Model, inputs::Dict, setup::Dict)

    dfH2G2P = inputs["dfH2G2P"]::DataFrame

    # Define sets
    H2_G2P_NEW_CAP = inputs["H2_G2P_NEW_CAP"] 
    H2_G2P_RET_CAP = inputs["H2_G2P_RET_CAP"] 
    H2_G2P_COMMIT = inputs["H2_G2P_COMMIT"]::Vector{<:Int}

    # NOT SURE ABOUT THIS
    H = inputs["H2_G2P_ALL"]::Int

    # Capacity of New H2 G2P units (MW)
    # For G2P with unit commitment, this variable refers to the number of units, not capacity. 
    @variable(EP, vH2G2PNewCap[k in H2_G2P_NEW_CAP] >= 0)
    # Capacity of Retired H2 G2P units built (MW)
    # For generation with unit commitment, this variable refers to the number of units, not capacity. 
    @variable(EP, vH2G2PRetCap[k in H2_G2P_RET_CAP] >= 0)
    
    ### Expressions ###
    # Cap_Size is set to 1 for all variables when unit UCommit == 0
    # When UCommit > 0, Cap_Size is set to 1 for all variables except those where THERM == 1
    @expression(EP, eH2G2PTotalCap[k in 1:H],
        if k in intersect(H2_G2P_NEW_CAP, H2_G2P_RET_CAP) # Resources eligible for new capacity and retirements
            if k in H2_G2P_COMMIT
                dfH2G2P[!,:Existing_Cap_MW][k] + dfH2G2P[!,:Cap_Size_MW][k] * (EP[:vH2G2PNewCap][k] - EP[:vH2G2PRetCap][k])
            else
                dfH2G2P[!,:Existing_Cap_MW][k] + EP[:vH2G2PNewCap][k] - EP[:vH2G2PRetCap][k]
            end
        elseif k in setdiff(H2_G2P_NEW_CAP, H2_G2P_RET_CAP) # Resources eligible for only new capacity
            if k in H2_G2P_COMMIT
                dfH2G2P[!,:Existing_Cap_MW][k] + dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PNewCap][k]
            else
                dfH2G2P[!,:Existing_Cap_MW][k] + EP[:vH2G2PNewCap][k]
            end
        elseif k in setdiff(H2_G2P_RET_CAP, H2_G2P_NEW_CAP) # Resources eligible for only capacity retirements
            if k in H2_G2P_COMMIT
                dfH2G2P[!,:Existing_Cap_MW][k] - dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PRetCap][k]
            else
                dfH2G2P[!,:Existing_Cap_MW][k] - EP[:vH2G2PRetCap][k]
            end
        else 
            # Resources not eligible for new capacity or retirements
            dfH2G2P[!,:Existing_Cap_MW][k] 
        end
    )

    ## Objective Function Expressions ##
    # Sum individual resource contributions to fixed costs to get total fixed costs
    #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] ==1 
        # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
        # If resource is not eligible for new capacity, fixed costs are only O&M costs
        @expression(EP, eH2G2PCFix[k in 1:H],
            if k in H2_G2P_NEW_CAP # Resources eligible for new capacity
                if k in H2_G2P_COMMIT
                    1/ModelScalingFactor^2*(dfH2G2P[!,:Inv_Cost_p_MW_p_yr][k] * dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PNewCap][k] + dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k])
                else
                    1/ModelScalingFactor^2*(dfH2G2P[!,:Inv_Cost_p_MW_p_yr][k] * EP[:vH2G2PNewCap][k] + dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k])
                end
            else
                (dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k])/ModelScalingFactor^2
            end
        )
    else
        # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
        # If resource is not eligible for new capacity, fixed costs are only O&M costs
        @expression(EP, eH2G2PCFix[k in 1:H],
            if k in H2_G2P_NEW_CAP # Resources eligible for new capacity
                if k in H2_G2P_COMMIT
                    dfH2G2P[!,:Inv_Cost_p_MW_p_yr][k] * dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PNewCap][k] + dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k]
                else
                    dfH2G2P[!,:Inv_Cost_p_MW_p_yr][k] * EP[:vH2G2PNewCap][k] + dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k]
                end
            else
                dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k]
            end
        )

    end

    @expression(EP, eTotalH2G2PCFix, sum(EP[:eH2G2PCFix][k] for k in 1:H))

    # Add term to objective function expression
    add_similar_to_expression!(EP[:eObj], eTotalH2G2PCFix)

    return EP
end
