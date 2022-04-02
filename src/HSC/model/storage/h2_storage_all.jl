"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
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

    Sets up variables and constraints common to all storage resources. See ```storage()``` in ```storage.jl``` for description of constraints.
**Storage with symmetric charge and discharge capacity**

For storage technologies with symmetric charge and discharge capacity (all $o \in \mathcal{O}^{sym}$), charge rate, $\Pi_{o,z,t}$, is constrained by the total installed power capacity, $\Omega_{o,z}$. Since storage resources generally represent a `cluster' of multiple similar storage devices of the same type/cost in the same zone, GenX permits storage resources to simultaneously charge and discharge (as some units could be charging while others discharge), with the simultaenous sum of charge, $\Pi_{o,z,t}$, and discharge, $\Theta_{o,z,t}$, also limited by the total installed power capacity, $\Delta^{total}_{o,z}$. These two constraints are as follows:

```math
\begin{aligned}
	&  \Pi_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Pi_{o,z,t} + \Theta_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

These constraints are created with the function ```storage_symmetric()``` in ```storage_symmetric.jl```.

If reserves are modeled, the following two constraints replace those above:

```math
\begin{aligned}
&  \Pi_{o,z,t} + f^{charge}_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}\\
&  \Pi_{o,z,t} + f^{charge}_{o,z,t} + \Theta_{o,z,t} + f^{discharge}_{o,z,t} + r^{discharge}_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T} \\
\end{aligned}
```

where $f^{charge}_{o,z,t}$ is the contribution of storage resources to frequency regulation while charging, $f^{discharge}_{o,z,t}$ is the contribution of storage resources to frequency regulation while discharging, and $r^{discharge}_{o,z,t}$ is the contribution of storage resources to upward reserves while discharging. Note that as storage resources can contribute to regulation and reserves while either charging or discharging, the proxy variables $f^{charge}_{o,z,t}, f^{discharge}_{o,z,t}$ and $r^{charge}_{o,z,t}, r^{discharge}_{o,z,t}$ are created for storage resources where the total contribution to regulation and reserves, $f_{o,z,t}, r_{o,z,t}$ is the sum of the proxy variables.

These constraints are created with the function ```storage_symmetric_reserves()``` in ```storage_symmetric.jl```.

**Storage with asymmetric charge and discharge capacity**

For storage technologies with asymmetric charge and discharge capacities (all $o \in \mathcal{O}^{asym}$), charge rate, $\Pi_{o,z,t}$, is constrained by the total installed charge capacity, $\Delta^{total, charge}_{o,z}$, as follows:

```math
\begin{aligned}
	&  \Pi_{o,z,t} \leq \Delta^{total, charge}_{o,z} & \quad \forall o \in \mathcal{O}^{asym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

These constraints are created with the function ```storage_asymmetric()``` in ```storage_asymmetric.jl```.

If reserves are modeled, the above constraint is replaced by the following:

```math
\begin{aligned}
	&  \Pi_{o,z,t} + f^{charge}_{o,z,t} \leq \Delta^{total, charge}_{o,z} & \quad \forall o \in \mathcal{O}^{asym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

where $f^{+}_{y=o,z,t}$ is the contribution of storage resources to frequency regulation while charging.

These constraints are created with the function ```storage_asymmetric_reserves()``` in ```storage_asymmetric.jl```.

**All storage resources**

The following constraints apply to all storage resources, $o \in \mathcal{O}$, regardless of whether the charge/discharge capacities are symmetric or asymmetric.

The following two constraints track the state of charge of the storage resources at the end of each time period, relating the volume of energy stored at the end of the time period, $\Gamma_{o,z,t}$, to the state of charge at the end of the prior time period, $\Gamma_{o,z,t-1}$, the charge and discharge decisions in the current time period, $\Pi_{o,z,t}, \Theta_{o,z,t}$, and the self discharge rate for the storage resource (if any), $\eta_{o,z}^{loss}$.  The first of these two constraints enforces storage inventory balance for interior time steps $(t \in \mathcal{T}^{interior})$, while the second enforces storage balance constraint for the initial time step $(t \in \mathcal{T}^{start})$.

```math
\begin{aligned}
	&  \Gamma_{o,z,t} =\Gamma_{o,z,t-1} - \frac{1}{\eta_{o,z}^{discharge}}\Theta_{o,z,t} + \eta_{o,z}^{charge}\Pi_{o,z,t} - \eta_{o,z}^{loss}\Gamma_{o,z,t-1}  \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}^{interior}\\
	&  \Gamma_{o,z,t} =\Gamma_{o,z,t+\tau^{period}-1} - \frac{1}{\eta_{o,z}^{discharge}}\Theta_{o,z,t} + \eta_{o,z}^{charge}\Pi_{o,z,t} - \eta_{o,z}^{loss}\Gamma_{o,z,t+\tau^{period}-1}  \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}^{start}
\end{aligned}
```

When modeling the entire year as a single chronological period with total number of time steps of $\tau^{period}$, storage inventory in the first time step is linked to storage inventory at the last time step of the period representing the year. Alternatively, when modeling the entire year with multiple representative periods, this constraint relates storage inventory in the first timestep of the representative period with the inventory at the last time step of the representative period, where each representative period is made of $\tau^{period}$ time steps. In this implementation, energy exchange between representative periods is not permitted. When modeling representative time periods, GenX enables modeling of long duration energy storage which tracks state of charge between representative periods enable energy to be moved throughout the year. If ```LongDurationStorage=1``` and ```OperationWrapping=1```, this function calls ```long_duration_storage()``` in ```long_duration_storage.jl``` to enable this feature.

The next constraint limits the volume of energy stored at any time, $\Gamma_{o,z,t}$, to be less than the installed energy storage capacity, $\Delta^{total, energy}_{o,z}$. Finally, the maximum discharge rate for storage resources, $\Pi_{o,z,t}$, is constrained to be less than the discharge power capacity, $\Omega_{o,z,t}$ or the state of charge at the end of the last period, $\Gamma_{o,z,t-1}$, whichever is lessor.

```math
\begin{aligned}
	&  \Gamma_{o,z,t} \leq \Delta^{total, energy}_{o,z} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Theta_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Theta_{o,z,t} \leq \Gamma_{o,z,t-1} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

The above constraints are established in ```storage_all()``` in ```storage_all.jl```.

If reserves are modeled, two pairs of proxy variables $f^{charge}_{o,z,t}, f^{discharge}_{o,z,t}$ and $r^{charge}_{o,z,t}, r^{discharge}_{o,z,t}$ are created for storage resources, to denote the contribution of storage resources to regulation or reserves while charging or discharging, respectively. The total contribution to regulation and reserves, $f_{o,z,t}, r_{o,z,t}$ is then the sum of the proxy variables:

```math
\begin{aligned}
	&  f_{o,z,t} = f^{charge}_{o,z,t} + f^{dicharge}_{o,z,t} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  r_{o,z,t} = r^{charge}_{o,z,t} + r^{dicharge}_{o,z,t} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

The total storage contribution to frequency regulation ($f_{o,z,t}$) and reserves ($r_{o,z,t}$) are each limited specified fraction of installed discharge power capacity ($\upsilon^{reg}_{y,z}, \upsilon^{rsv}_{y,z}$), reflecting the maximum ramp rate for the storage resource in whatever time interval defines the requisite response time for the regulation or reserve products (e.g., 5 mins or 15 mins or 30 mins). These response times differ by system operator and reserve product, and so the user should define these parameters in a self-consistent way for whatever system context they are modeling.

```math
\begin{aligned}
	f_{y,z,t} \leq \upsilon^{reg}_{y,z} \times \Delta^{total}_{y,z}
	\hspace{4 cm}  \forall y \in \mathcal{W}, z \in \mathcal{Z}, t \in \mathcal{T} \\
	r_{y,z, t} \leq \upsilon^{rsv}_{y,z}\times \Delta^{total}_{y,z}
	\hspace{4 cm}  \forall y \in \mathcal{W}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

When charging, reducing the charge rate is contributing to upwards reserve and frequency regulation as it drops net demand. As such, the sum of the charge rate plus contribution to regulation and reserves up must be greater than zero. Additionally, the discharge rate plus the contribution to regulation must be greater than zero.

```math
\begin{aligned}
	&  \Pi_{o,z,t} - f^{charge}_{o,z,t} - r^{charge}_{o,z,t} \geq 0 & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Theta_{o,z,t} - f^{discharge}_{o,z,t} \geq 0 & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

Additionally, when reserves are modeled, the maximum charge rate and contribution to regulation while charging can be no greater than the available energy storage capacity, or the difference between the total energy storage capacity, $\Delta^{total, energy}_{o,z}$, and the state of charge at the end of the previous time period, $\Gamma_{o,z,t-1}$. Note that for storage to contribute to reserves down while charging, the storage device must be capable of increasing the charge rate (which increase net load).

```math
\begin{aligned}
	&  \Pi_{o,z,t} + f^{charge}_{o,z,t} \leq \Delta^{energy, total}_{o,z} - \Gamma_{o,z,t-1} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

Finally, the constraints on maximum discharge rate are replaced by the following, to account for capacity contributed to regulation and reserves:

```math
\begin{aligned}
	&  \Theta_{o,z,t} + f^{discharge}_{o,z,t} + r^{discharge}_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Theta_{o,z,t} + f^{discharge}_{o,z,t} + r^{discharge}_{o,z,t} \leq \Gamma_{o,z,t-1} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

The above reserve related constraints are established by ```storage_all_reserves()``` in ```storage_all.jl```
"""
function h2_storage_all(EP::Model, inputs::Dict, setup::Dict)
    # Setup variables, constraints, and expressions common to all hydrogen storage resources
    println("Hydrogen Storage Core Resources Module")

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
	@expression(EP, eEH2LOSS[y in H2_STOR_ALL], sum(inputs["omega"][t]*EP[:vH2CHARGE_STOR][y,t] for t in 1:T) - sum(inputs["omega"][t]*EP[:vH2Gen][y,t] for t in 1:T))

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
        sum(EP[:vH2CHARGE_STOR][y,t]*dfH2Gen[!,:H2Stor_Charge_MWh_p_tonne][y]/ModelScalingFactor for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL))
    else
        sum(EP[:vH2CHARGE_STOR][y,t]*dfH2Gen[!,:H2Stor_Charge_MWh_p_tonne][y] for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL))
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
