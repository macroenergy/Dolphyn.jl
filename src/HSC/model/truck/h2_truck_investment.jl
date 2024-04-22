

@doc raw"""
    h2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

This function includes investment variables, expressions and related constraints for H2 trucks.

**Variables**

## Truck capacity built and retired
```math
\begin{equation*}
    0 \leq v_{CAP,j}^{\textrm{H,TRU}}
\end{equation*}
```

```math
\begin{equation*}
    0 \leq v_{RETCAP,j}^{\textrm{H,TRU}}
\end{equation*}
```

```math
\begin{equation*}
    0 \leq v_{CAP,j}^{\textrm{H,TRU}}
\end{equation*}
```

```math
\begin{equation*}
    0 \leq v_{NEWCAP,j}^{\textrm{H,TRU}}
\end{equation*}
```

**Constraints**

Truck retirements cannot retire more charge capacity than existing charge capacity
```math
\begin{equation*}
    v_{RETCAPNUM,j}^{\textrm{H,TRU}} \leq v_{ExistNum,j}^{\textrm{H,TRU}} \quad \forall j \in \mathbb{J}
\end{equation*}
```
Truck compression energy cannot retire more energy capacity than existing energy capacity
```math
\begin{equation*}
    v_{RETCAPEnergy,j}^{\textrm{H,TRU}} \leq v_{ExistEnergyCap,j}^{\textrm{H,TRU}} \quad \forall j \in \mathbb{J}
\end{equation*}
```

**Expressions**
```math
\begin{equation*}
    C_{\textrm{\textrm{H,TRU}}}^{\textrm{o}}=& \sum_{z \rightarrow z^{\prime} \in \mathbb{B}} \sum_{j \in \mathbb{J}} \sum_{t \in \mathbb{T}} \omega_t \textrm{~L}_{z \rightarrow z^{\prime}} \\
    & \times\left(\textrm{o}_{j}^{\textrm{\textrm{H,TRU}}, \textrm{F}} y_{z \rightarrow z,{ }^{\prime} j, t}^{\textrm{F}}+\textrm{o}_{j}^{\textrm{\textrm{H,TRU}}, \textrm{E}} y_{z \rightarrow z,,^{\prime} j, t}^{\textrm{E}}\right)
\end{equation*}
```
"""
function h2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("H2 Truck Investment Module")

    dfH2Truck = inputs["dfH2Truck"]

	Z = inputs["Z"]::Int # Model zones - assumed to be same for H2 and electricity 

    SCALING = setup["scaling"]::Float64

    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"] # Set of all truck types
    NEW_CAP_TRUCK = inputs["NEW_CAP_TRUCK"] # Set of hydrogen truck types eligible for new capacity
    RET_CAP_TRUCK = inputs["RET_CAP_TRUCK"] # Set of hydrogen truck eligible for capacity retirements

    # NEW_CAP_TRUCK = inputs["NEW_CAP_TRUCK"] # Set of hydrogen truck compression eligible for new energy capacity
    # RET_CAP_TRUCK = inputs["RET_CAP_H2RET_CAP_TRUCKf hydrogen truck compression eligible for energy capacity retirements

    ### Variables ###

    ## Truck capacity built and retired

    # New installed charge capacity of truck type "j"
    @variable(EP, vH2TruckNumber[j in NEW_CAP_TRUCK] >= 0)

    # Retired charge capacity of truck type "j" from existing capacity
    @variable(EP, vH2RetTruckNumber[j in RET_CAP_TRUCK] >= 0)

    # New installed energy capacity of truck type "j" on zone "z"
    @variable(EP, vH2TruckEnergy[z = 1:Z, j in NEW_CAP_TRUCK] >= 0)

    # Retired energy capacity of truck type "j" on zone "z" from existing capacity
    @variable(EP, vH2RetTruckEnergy[z = 1:Z, j in RET_CAP_TRUCK] >= 0)

    # Total available charging capacity in tonnes/hour
    @expression(
        EP,
        eTotalH2TruckNumber[j in H2_TRUCK_TYPES],
        if (j in intersect(NEW_CAP_TRUCK, RET_CAP_TRUCK))
            dfH2Truck[!, :Existing_Number][j] + EP[:vH2TruckNumber][j] -
            EP[:vH2RetTruckNumber][j]
        elseif (j in setdiff(NEW_CAP_TRUCK, RET_CAP_TRUCK))
            dfH2Truck[!, :Existing_Number][j] + EP[:vH2TruckNumber][j]
        elseif (j in setdiff(RET_CAP_TRUCK, NEW_CAP_TRUCK))
            dfH2Truck[!, :Existing_Number][j] - EP[:vH2RetTruckNumber][j]
        else
            dfH2Truck[!, :Existing_Number][j]
        end
    )


    # Total available energy capacity in tonnes
    @expression(
        EP,
        eTotalH2TruckEnergy[z = 1:Z, j in H2_TRUCK_TYPES],
        if (j in intersect(NEW_CAP_TRUCK, RET_CAP_TRUCK))
            dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] + EP[:vH2TruckEnergy][z, j] -
            EP[:vH2RetTruckEnergy][z, j]
        elseif (j in setdiff(NEW_CAP_TRUCK, RET_CAP_TRUCK))
            dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] + EP[:vH2TruckEnergy][z, j]
        elseif (j in setdiff(RET_CAP_TRUCK, NEW_CAP_TRUCK))
            dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j] - EP[:vH2RetTruckEnergy][z, j]
        else
            dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j]
        end
    )

	## Objective Function Expressions ##

	# Charge capacity costs
	# Fixed costs for truck type "j" = annuitized investment cost
	# If truck is not eligible for new charge capacity, fixed costs are zero
	# Sum individual truck type contributions to fixed costs to get total fixed costs
	#  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	#  ParameterScale = 0 --> objective function is in $
    @expression(EP, eCFixH2TruckCharge[j in H2_TRUCK_TYPES],
        if j in NEW_CAP_TRUCK # Truck types eligible for new charge capacity
            (dfH2Truck[!,:Inv_Cost_p_unit_p_yr][j]*vH2TruckNumber[j]) / SCALING^2
        else
            EP[:vZERO]
        end
    )

	# Sum individual resource contributions to fixed costs to get total fixed costs
	@expression(EP, eTotalCFixH2TruckCharge, sum(EP[:eCFixH2TruckCharge][j] for j in H2_TRUCK_TYPES))

	# Add term to objective function expression
	add_similar_to_expression!(EP[:eObj], eTotalCFixH2TruckCharge)

    # Energy capacity costs
	# Fixed costs for truck type "j" on zone "z" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new energy capacity, fixed costs are only O&M costs
	#  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	#  ParameterScale = 0 --> objective function is in $
    @expression(EP, eCFixH2TruckEnergy[z = 1:Z, j in H2_TRUCK_TYPES],
        if j in NEW_CAP_TRUCK # Resources eligible for new capacity
            1/SCALING^2*(dfH2Truck[!,:Inv_Cost_Energy_p_tonne_yr][j]*vH2TruckEnergy[z, j] + dfH2Truck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][j]*eTotalH2TruckEnergy[z, j])
        else
            1/SCALING^2*(dfH2truck[!,:Fixed_OM_Cost_Energy_p_tonne_yr][j]*eTotalH2TruckEnergy[z, j])
        end
    )

    # Sum individual zone and individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixH2TruckEnergy, sum(EP[:eCFixH2TruckEnergy][z, j] for z = 1:Z, j in H2_TRUCK_TYPES))

    # Add term to objective function expression
    add_similar_to_expression!(EP[:eObj], eTotalCFixH2TruckEnergy)


	### Constratints ###

	## Constraints on truck retirements
	#Cannot retire more charge capacity than existing charge capacity
 	@constraint(EP, cMaxRetH2TruckNumber[j in RET_CAP_TRUCK], vH2RetTruckNumber[j] <= dfH2Truck[!,:Existing_Number][j])


  	## Constraints on truck compression energy
		
	# Cannot retire more energy capacity than existing energy capacity
	@constraint(EP, cMaxRetH2TruckEnergy[z = 1:Z, j in RET_CAP_TRUCK], vH2RetTruckEnergy[z,j] <= dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")][j])

	## Constraints on new built truck compression energy capacity
	# Constraint on maximum energy capacity (if applicable) [set input to -1 if no constraint on maximum energy capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is >= Max_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMaxCapH2TruckEnergy[z = 1:Z, j in intersect(dfH2Truck[dfH2Truck.Max_Energy_Cap_tonne.>0,:T_TYPE], H2_TRUCK_TYPES)], eTotalH2TruckEnergy[z, j] <= dfH2Truck[!,:Max_Energy_Cap_tonne][j])

	# Constraint on minimum energy capacity (if applicable) [set input to -1 if no constraint on minimum energy apacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is <= Min_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMinCapH2TruckEnergy[z = 1:Z, j in intersect(dfH2Truck[dfH2Truck.Min_Energy_Cap_tonne.>0,:T_TYPE], H2_TRUCK_TYPES)], eTotalH2TruckEnergy[z, j] >= dfH2Truck[!,:Min_Energy_Cap_tonne][j])

	return EP
end