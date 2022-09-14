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
    h2_storage_all(EP::Model, inputs::Dict, setup::Dict)

Sets up variables and constraints common to all hydrogen storage resources. See ```h2_storage()``` in ```h2_storage.jl``` for description of constraints.
**Hydrogen storage devices with symmetric charge and discharge capacity**

For hydrogen storage technologies with symmetric charge and discharge capacity (all $o \in \mathcal{O}^{sym}$), charge rate, $\Pi_{o,z,t}$, is constrained by the total installed power capacity, $\Omega_{o,z}$. Since storage resources generally represent a `cluster' of multiple similar storage devices of the same type/cost in the same zone, DOLPHYN permits hydrogen storage resources to simultaneously charge and discharge (as some units could be charging while others discharge), with the simultaenous sum of charge, $\Pi_{o,z,t}$, and discharge, $\Theta_{o,z,t}$, also limited by the total installed charge capacity, $\Delta^{total}_{o,z}$. These two constraints are as follows:

```math
\begin{aligned}
	&  \Pi_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Pi_{o,z,t} + \Theta_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

These constraints are created with the function ```h2_storage_symmetric()``` in ```h2_storage_symmetric.jl```.

**All hydrogen storage resources**

The following constraints apply to all hydrogen storage resources, $o \in \mathcal{O}$, regardless of whether the charge/discharge capacities are symmetric or asymmetric.

The following two constraints track the state of charge of the storage resources at the end of each time period, relating the volume of hydrogen stored at the end of the time period, $\Gamma_{o,z,t}$, to the state of charge at the end of the prior time period, $\Gamma_{o,z,t-1}$, the charge and discharge decisions in the current time period, $\Pi_{o,z,t}, \Theta_{o,z,t}$, and the self discharge rate for the storage resource (if any), $\eta_{o,z}^{loss}$. The first of these two constraints enforces hydrogen storage inventory balance for interior time steps $(t \in \mathcal{T}^{interior})$, while the second enforces hydrogen storage balance constraint for the initial time step $(t \in \mathcal{T}^{start})$.

```math
\begin{aligned}
	&  \Gamma_{o,z,t} =\Gamma_{o,z,t-1} - \frac{1}{\eta_{o,z}^{discharge}}\Theta_{o,z,t} + \eta_{o,z}^{charge}\Pi_{o,z,t} - \eta_{o,z}^{loss}\Gamma_{o,z,t-1}  \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}^{interior}\\
	&  \Gamma_{o,z,t} =\Gamma_{o,z,t+\tau^{period}-1} - \frac{1}{\eta_{o,z}^{discharge}}\Theta_{o,z,t} + \eta_{o,z}^{charge}\Pi_{o,z,t} - \eta_{o,z}^{loss}\Gamma_{o,z,t+\tau^{period}-1}  \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}^{start}
\end{aligned}
```

When modeling the entire year as a single chronological period with total number of time steps of $\tau^{period}$, hydrogen storage inventory in the first time step is linked to hydrogen storage inventory at the last time step of the period representing the year. Alternatively, when modeling the entire year with multiple representative periods, this constraint relates hydrogen storage inventory in the first timestep of the representative period with the inventory at the last time step of the representative period, where each representative period is made of $\tau^{period}$ time steps. In this implementation, energy exchange between representative periods is not permitted. When modeling representative time periods, DOLPHYN enables modeling of long duration energy storage which tracks state of charge between representative periods enable energy to be moved throughout the year. If ```LongDurationStorage=1``` and ```OperationWrapping=1```, this function calls ```h2_long_duration_storage()``` in ```h2_long_duration_storage.jl``` to enable this feature.

The next constraint limits the volume of energy stored at any time, $\Gamma_{o,z,t}$, to be less than the installed energy storage capacity, $\Delta^{total, energy}_{o,z}$. Finally, the maximum discharge rate for storage resources, $\Pi_{o,z,t}$, is constrained to be less than the discharge power capacity, $\Omega_{o,z,t}$ or the state of charge at the end of the last period, $\Gamma_{o,z,t-1}$, whichever is lessor.

```math
\begin{aligned}
	&  \Gamma_{o,z,t} \leq \Delta^{total, energy}_{o,z} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Theta_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Theta_{o,z,t} \leq \Gamma_{o,z,t-1} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
The next constraint limits the rate of charging to the installed storage capacity.
```math
\begin{aligned}
	&  \Pi_{o,z,t} \leq \Delta^{total, charge}_{o,z} & \quad \forall o \in \mathcal{O}^{asym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

The above constraints are established in ```h2_storage_all()``` in ```h2_storage_all.jl```.
"""
function h2_storage_all(EP::Model, inputs::Dict, setup::Dict)
    # Setup variables, constraints, and expressions common to all hydrogen storage resources
    println("H2 Storage Core Resources Module")

    dfH2Gen = inputs["dfH2Gen"]
    H2_STOR_ALL = inputs["H2_STOR_ALL"] # Set of all h2 storage resources

    Z = inputs["Z"]     # Number of zones
    T = inputs["T"] # Number of time steps (hours) 
	  
    START_SUBPERIODS = inputs["START_SUBPERIODS"] # Starting subperiod index for each representative period
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] # Index of interior subperiod for each representative period
    H2_STOR_SHORT_DURATION = inputs["H2_STOR_SHORT_DURATION"] # Set of H2 storage modeled as short-duration (no energy carryover from one rep. week to the next)
    H2_STOR_LONG_DURATION = inputs["H2_STOR_LONG_DURATION"] # Set of H2 storage modeled as long-duration (energy carry over allowed)

    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ### Variables ###
	# Storage level of resource "y" at hour "t" [tonne] on zone "z" 
	@variable(EP, vH2S[y in H2_STOR_ALL, t=1:T] >= 0)

	# Rate of energy withdrawn from HSC by resource "y" at hour "t" [tonne/hour] on zone "z"
	@variable(EP, vH2_CHARGE_STOR[y in H2_STOR_ALL, t=1:T] >= 0)

    # Energy losses related to storage technologies (increase in effective demand)
	#@expression(EP, eEH2LOSS[y in H2_STOR_ALL], sum(inputs["omega"][t]*EP[:vH2_CHARGE_STOR][y,t] for t in 1:T) - sum(inputs["omega"][t]*EP[:vH2Gen][y,t] for t in 1:T))

    #Variable costs of "charging" for technologies "y" during hour "t" in zone "z"
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] ==1 
        @expression(EP, eCVarH2Stor_in[y in H2_STOR_ALL,t=1:T], 
        if (dfH2Gen[!,:H2Stor_Charge_MMBtu_p_tonne][y]>0) # Charging consumes fuel - fuel divided by 1000 since fuel cost already scaled in load_fuels_data.jl when ParameterScale =1
            inputs["omega"][t]*dfH2Gen[!,:Var_OM_Cost_Charge_p_tonne][y]*vH2_CHARGE_STOR[y,t]/ModelScalingFactor^2 + inputs["fuel_costs"][dfH2Gen[!,:Fuel][k]][t] * dfH2Gen[!,:H2Stor_Charge_MMBtu_p_tonne][k]*vH2_CHARGE_STOR[y,t]/ModelScalingFactor
        else
            inputs["omega"][t]*dfH2Gen[!,:Var_OM_Cost_Charge_p_tonne][y]*vH2_CHARGE_STOR[y,t]/ModelScalingFactor^2
        end
        )
    else
        @expression(EP, eCVarH2Stor_in[y in H2_STOR_ALL,t=1:T], 
        if (dfH2Gen[!,:H2Stor_Charge_MMBtu_p_tonne][y]>0) # Charging consumes fuel 
            inputs["omega"][t]*dfH2Gen[!,:Var_OM_Cost_Charge_p_tonne][y]*vH2_CHARGE_STOR[y,t] +inputs["fuel_costs"][dfH2Gen[!,:Fuel][k]][t] * dfH2Gen[!,:H2Stor_Charge_MMBtu_p_tonne][k]
        else
            inputs["omega"][t]*dfH2Gen[!,:Var_OM_Cost_Charge_p_tonne][y]*vH2_CHARGE_STOR[y,t]
        end      
        )
    end

    # Sum individual resource contributions to variable charging costs to get total variable charging costs
    @expression(EP, eTotalCVarH2StorInT[t=1:T], sum(eCVarH2Stor_in[y,t] for y in H2_STOR_ALL))
    @expression(EP, eTotalCVarH2StorIn, sum(eTotalCVarH2StorInT[t] for t in 1:T))
    EP[:eObj] += eTotalCVarH2StorIn


    # Term to represent electricity consumption associated with H2 storage charging and discharging
	@expression(EP, ePowerBalanceH2Stor[t=1:T, z=1:Z],
    if setup["ParameterScale"] == 1 # If ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
        sum(EP[:vH2_CHARGE_STOR][y,t]*dfH2Gen[!,:H2Stor_Charge_MWh_p_tonne][y]/ModelScalingFactor for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL); init=0.0)
    else
        sum(EP[:vH2_CHARGE_STOR][y,t]*dfH2Gen[!,:H2Stor_Charge_MWh_p_tonne][y] for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL); init=0.0)
    end
    )

    EP[:ePowerBalance] += -ePowerBalanceH2Stor

    # Adding power consumption by storage
    EP[:eH2NetpowerConsumptionByAll] += ePowerBalanceH2Stor
 
   	# H2 Balance expressions
	@expression(EP, eH2BalanceStor[t=1:T, z=1:Z],
	sum(EP[:vH2Gen][y,t] - EP[:vH2_CHARGE_STOR][y,t] for y in intersect(H2_STOR_ALL, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] += eH2BalanceStor   

    ### End Expressions ###

    ### Constraints ###
	## Storage energy capacity and state of charge related constraints:

	# Links state of charge in first time step with decisions in last time step of each subperiod
	# We use a modified formulation of this constraint (cSoCBalLongDurationStorageStart) when operations wrapping and long duration storage are being modeled
	
	if setup["OperationWrapping"] == 1 && !isempty(H2_STOR_LONG_DURATION)  && !isempty(H2_STOR_SHORT_DURATION) # Apply constraints to those storage technologies with short duration only (if non-empty)
		@constraint(EP, cH2SoCBalStart[t in START_SUBPERIODS, y in H2_STOR_SHORT_DURATION], EP[:vH2S][y,t] ==
			EP[:vH2S][y,t+hours_per_subperiod-1]-(1/dfH2Gen[!,:H2Stor_eff_discharge][y]*EP[:vH2Gen][y,t])
			+(dfH2Gen[!,:H2Stor_eff_charge][y]*EP[:vH2_CHARGE_STOR][y,t])-(dfH2Gen[!,:H2Stor_self_discharge_rate_p_hour][y]*EP[:vH2S][y,t+hours_per_subperiod-1]))
	else # Apply constraints to all storage technologies
		@constraint(EP, cH2SoCBalStart[t in START_SUBPERIODS, y in H2_STOR_ALL], EP[:vH2S][y,t] ==
			EP[:vH2S][y,t+hours_per_subperiod-1]-(1/dfH2Gen[!,:H2Stor_eff_discharge][y]*EP[:vH2Gen][y,t])
			+(dfH2Gen[!,:H2Stor_eff_charge][y]*EP[:vH2_CHARGE_STOR][y,t])-(dfH2Gen[!,:H2Stor_self_discharge_rate_p_hour][y]*EP[:vH2S][y,t+hours_per_subperiod-1]))
    end
	
	@constraints(EP, begin

		[y in H2_STOR_ALL, t in 1:T], EP[:eH2TotalCapEnergy][y]*dfH2Gen[!,:H2Stor_max_level][y] >= EP[:vH2S][y,t]
		[y in H2_STOR_ALL, t in 1:T], EP[:eH2TotalCapEnergy][y]*dfH2Gen[!,:H2Stor_min_level][y] <= EP[:vH2S][y,t]

        # Constraint on maximum discharging rate imposed if storage discharging capital cost >0
        # [y in intersect(H2_STOR_ALL,dfH2Gen[!,:Inv_Cost_p_tonne_p_hr_yr].>0), t in 1:T], EP[:vH2Gen][y,t] <= EP[:eH2TotalCapEnergy][y]
        # [y in H2_STOR_ALL, t in 1:T], EP[:vH2Gen][y,t] <= EP[:eH2GenTotalCap][y] * inputs["pH2_Max"][y,t]
        
		# energy stored for the next hour
		cH2SoCBalInterior[t in INTERIOR_SUBPERIODS, y in H2_STOR_ALL], EP[:vH2S][y,t] ==
			EP[:vH2S][y,t-1]-(1/dfH2Gen[!,:H2Stor_eff_discharge][y]*EP[:vH2Gen][y,t])+(dfH2Gen[!,:H2Stor_eff_charge][y]*EP[:vH2_CHARGE_STOR][y,t])-(dfH2Gen[!,:H2Stor_self_discharge_rate_p_hour][y]*EP[:vH2S][y,t-1])
	end)


    # Hydrogen storage discharge and charge power (and reserve contribution) related constraints for symmetric storage resources:
    # Maximum charging rate must be less than charge power rating
    @constraint(EP,
        [y in H2_STOR_ALL, t in 1:T],
        EP[:vH2_CHARGE_STOR][y, t] <= EP[:eTotalH2CapCharge][y]
    )

    ### End Constraints ###
    return EP
end
