"""
GenX: An Configurable Capacity Expansion Model
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
	storage_all(EP::Model, inputs::Dict, Reserves::Int, OperationWrapping::Int)

Sets up variables and constraints common to all storage resources.

**Storage discharge and inventory level decision variables**

This module defines the storage energy inventory level variable $U_{s,z,t}^{E,STO} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing energy stored in the storage device $s$ in zone $z$ at time period $t$.

This module defines the power charge decision variable $x_{s,z,t}^{E,CHA}$\forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing charged power into the storage device $s$ in zone $z$ at time period $t$.

The variable defined in this file named after ```vS``` covers $U_{s,z,t}^{E,STO}$.

The variable defined in this file named after ```vCHARGE``` covers $x_{s,z,t}^{E,CHA}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs (variable O&M plus fuel cost) of charging action of storage devices $s \in \mathcal{S}$ over all time periods $t \in \mathcal{T}$:

```math
\begin{equation}
	C^{E,STO,o} = \sum_{s \in \mathcal{S} \sum_{z \in \mathcal{Z} \sum_{t \in \mathcal{T}\Omega_t \times c_{s,z,t}^{E,STO,o} \times x_{s,z,t}^{E,CHA}
\end{equation}
```

**Power balance expressions**

Contributions to the power balance expression from storage charging and discharging action from storage devices $s \in \mathcal{S}$ are also defined as:

```math
\begin{eqution}
	PowerBal_{STO} = \sum_{s \in \mathcal{S}} \left)x_{s,z,t}^{E,DIS} - x_{s,z,t}^{E,CHA}\right)
\end{eqution}
```

**Storage inventory level track constraints**

The following constraints apply to all storage resources, $s \in \mathcal{S}$, regardless of whether the charge/discharge capacities are symmetric or asymmetric.

The following two constraints track the state of charge of the storage resources at the end of each time period, relating the volume of energy stored at the end of the time period, $U_{s,z,t}^{E,STO}$, to the state of charge at the end of the prior time period, $U_{s,z,t-1}^{E,STO}$, the charge and discharge decisions in the current time period, $x_{s,z,t}^{E,CHA}, x_{s,z,t}^{E,DIS}$, and the self discharge rate for the storage resource (if any), $\eta_{s,z}^{loss}$. 
The first of these two constraints enforces storage inventory balance for interior time steps $(t \in \mathcal{T}^{interior})$, while the second enforces storage balance constraint for the initial time step $(t \in \mathcal{T}^{start})$.

```math
\begin{aligned}
	U_{s,z,t}^{E,STO} &= U_{s,z,t-1}^{E,STO} - \frac{1}{\eta_{s,z}^{E,STO}}x_{s,z,t}^{E,DIS} + \eta_{s,z}^{E,STO}x_{s,z,t}^{E,STO} - \eta_{s,z}^{loss}U_{s,z,t-1} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}^{interior} \\
	U_{s,z,t}^{E,STO} &= U_{s,z,t+\tau^{period}-1}^{E,STO} - \frac{1}{\eta_{s,z}^{E,STO}}x_{s,z,t}^{E,DIS} + \eta_{s,z}^{E,STO}x_{s,z,t}^{E,CHA} - \eta_{s,z}^{loss}U_{s,z,t+\tau^{period}-1} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}^{start}
\end{aligned}
```

When modeling the entire year as a single chronological period with total number of time steps of $\tau^{period}$, storage inventory in the first time step is linked to storage inventory at the last time step of the period representing the year. 
Alternatively, when modeling the entire year with multiple representative periods, this constraint relates storage inventory in the first timestep of the representative period with the inventory at the last time step of the representative period, where each representative period is made of $\tau^{period}$ time steps. 
In this implementation, energy exchange between representative periods is not permitted. When modeling representative time periods, DOLPHYN enables modeling of long duration energy storage which tracks state of charge between representative periods enable energy to be moved throughout the year. 
If ```LongDurationStorage=1``` and ```OperationWrapping=1```, this function calls ```long_duration_storage()``` in ```long_duration_storage.jl``` to enable this feature.

**Bounds on storage power and energy capacity**

The storage power capacity sets lower and upper bounds on the storage energy capacity due to charging or discharging duration.

```math
\begin{aligned}
	y_{s,z}^{E,STO,POW} \times \tau_{s,z}^{MinDuration} &\leq y_{s,z}^{E,STO,ENE} \\
	y_{s,z}^{E,STO,POW} \times \tau_{s,z}^{MaxDuration} &\geq y_{s,z}^{E,STO,ENE}
\end{aligned}
```

It limits the volume of energy $U_{s,z,t}^{E,STO}$ at any time $t$ to be less than the installed energy storage capacity $y_{s,z}^{E,STO,ENE}$.

```math
\begin{equation}
	0 \leq U_{s,z,t}^{E,STO} \leq y_{s,z}^{E,STO,ENE} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation}
```

It also limits the discharge power $x_{s,z,t}^{E,DIS}$ at any time to be less than the installed power capacity $y_{s,z}^{E,STO,POW}$.
Finally, the maximum discharge rate for storage resources, $x_{s,z,t}^{E,STO}$, is constrained to be less than the discharge power capacity, $y_{s,z}^{E,STO,POW}$ or the state of charge at the end of the last period, $U{s,z,t-1}^{E,STO}$, whichever is less.

```math
\begin{aligned}
	0 &\leq x_{s,z,t}^{E,DIS} \leq y_{s,z}^{E,STO,POW} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T} \\
	0 &\leq x_{s,z,t}^{E,DIS} \leq U_{s,z,t-1}^{E,STO}*\eta_{s,z}^{E,DIS} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}^{interior} \\
	0 &\leq x_{s,z,t}^{E,DIS} \leq U_{s,z,t+\tau^{period}-1}^{E,STO}*\eta_{s,z}^{E,DIS} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}^{start}
\end{aligned}
```
"""
function storage_all(EP::Model, inputs::Dict, Reserves::Int, OperationWrapping::Int)
	# Setup variables, constraints, and expressions common to all storage resources
	println("Storage Core Resources Module")

	dfGen = inputs["dfGen"]

	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	STOR_ALL = inputs["STOR_ALL"]
	STOR_SHORT_DURATION = inputs["STOR_SHORT_DURATION"]

	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]

	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

	### Variables ###

	# Storage level of resource "y" at hour "t" [MWh] on zone "z" - unbounded
	@variable(EP, vS[y in STOR_ALL, t=1:T] >= 0)

	# Energy withdrawn from grid by resource "y" at hour "t" [MWh] on zone "z"
	@variable(EP, vCHARGE[y in STOR_ALL, t=1:T] >= 0)

	### Expressions ###

	#! Yuheng Zhang: could loss of energy storage system be modeled in the form of efficiency of maintaining?
	# Energy losses related to technologies (increase in effective demand)
	@expression(EP, eELOSS[y in STOR_ALL], sum(inputs["omega"][t]*EP[:vCHARGE][y,t] for t in 1:T) - sum(inputs["omega"][t]*EP[:vP][y,t] for t in 1:T))

	## Objective Function Expressions ##

	# Variable costs of "charging" for technologies "y" during hour "t" in zone "z"
	@expression(EP, eCVar_in[y in STOR_ALL,t=1:T], inputs["omega"][t]*dfGen[!,:Var_OM_Cost_per_MWh_In][y]*vCHARGE[y,t])

	# Sum individual resource contributions to variable charging costs to get total variable charging costs
	@expression(EP, eTotalCVarInT[t=1:T], sum(eCVar_in[y,t] for y in STOR_ALL))
	@expression(EP, eTotalCVarIn, sum(eTotalCVarInT[t] for t in 1:T))
	EP[:eObj] += eTotalCVarIn

	## Power Balance Expressions ##

	# Term to represent net dispatch from storage in any period
	@expression(EP, ePowerBalanceStor[t=1:T, z=1:Z],
		sum(EP[:vP][y,t]-EP[:vCHARGE][y,t] for y in intersect(dfGen[dfGen.Zone.==z,:R_ID],STOR_ALL))
	)

	EP[:ePowerBalance] += ePowerBalanceStor

	### Constraints ###

	## Storage energy capacity and state of charge related constraints:

	# Links state of charge in first time step with decisions in last time step of each subperiod
	# We use a modified formulation of this constraint (cSoCBalLongDurationStorageStart) when operations wrapping and long duration storage are being modeled
	
	if OperationWrapping ==1 && !isempty(inputs["STOR_LONG_DURATION"])
		@constraint(EP, cSoCBalStart[t in START_SUBPERIODS, y in STOR_SHORT_DURATION], EP[:vS][y,t] ==
			EP[:vS][y,t+hours_per_subperiod-1]-(1/dfGen[!,:Eff_Down][y]*EP[:vP][y,t])
			+(dfGen[!,:Eff_Up][y]*EP[:vCHARGE][y,t])-(dfGen[!,:Self_Disch][y]*EP[:vS][y,t+hours_per_subperiod-1]))
	else
		@constraint(EP, cSoCBalStart[t in START_SUBPERIODS, y in STOR_ALL], EP[:vS][y,t] ==
			EP[:vS][y,t+hours_per_subperiod-1]-(1/dfGen[!,:Eff_Down][y]*EP[:vP][y,t])
			+(dfGen[!,:Eff_Up][y]*EP[:vCHARGE][y,t])-(dfGen[!,:Self_Disch][y]*EP[:vS][y,t+hours_per_subperiod-1]))
	end
	
	# Energy stored for the next hour
	@constraint(EP, 
		cSoCBalInterior[t in INTERIOR_SUBPERIODS, y in STOR_ALL],
		EP[:vS][y,t] == EP[:vS][y,t-1]-(1/dfGen[!,:Eff_Down][y]*EP[:vP][y,t])+(dfGen[!,:Eff_Up][y]*EP[:vCHARGE][y,t])-(dfGen[!,:Self_Disch][y]*EP[:vS][y,t-1])
	)

	# Max and min constraints on energy storage capacity built (as proportion to discharge power capacity)
	@constraints(EP, begin
		[y in STOR_ALL], EP[:eTotalCapEnergy][y] >= dfGen[!,:Min_Duration][y] * EP[:eTotalCap][y]
		[y in STOR_ALL], EP[:eTotalCapEnergy][y] <= dfGen[!,:Max_Duration][y] * EP[:eTotalCap][y]
	end)


	# Maximum energy stored must be less than energy capacity
	@constraint(EP,
		cSocBound[y in STOR_ALL, t in 1:T], 
		EP[:vS][y,t] <= EP[:eTotalCapEnergy][y]
	)

	# Storage discharge and charge power (and reserve contribution) related constraints:
	if Reserves == 1
		EP = storage_all_reserves(EP, inputs)
	else
		# Note: maximum charge rate is also constrained by maximum charge power capacity, but as this differs by storage type,
		# this constraint is set in functions below for each storage type

		# Maximum discharging rate must be less than power rating OR available stored energy in the prior period, whichever is less
		# wrapping from end of sample period to start of sample period for energy capacity constraint
		@constraints(EP, begin
			[y in STOR_ALL, t=1:T], EP[:vP][y,t] <= EP[:eTotalCap][y]
			[y in STOR_ALL, t in INTERIOR_SUBPERIODS], EP[:vP][y,t] <= EP[:vS][y,t-1]*dfGen[!,:Eff_Down][y]
			[y in STOR_ALL, t in START_SUBPERIODS], EP[:vP][y,t] <= EP[:vS][y,t+hours_per_subperiod-1]*dfGen[!,:Eff_Down][y]
		end)
	end
	# From co2 Policy module
	@expression(EP, eELOSSByZone[z=1:Z],
		sum(EP[:eELOSS][y] for y in intersect(inputs["STOR_ALL"], dfGen[dfGen[!,:Zone].==z,:R_ID]))
	)
	return EP
end

@doc raw"""
	storage_all_reserves(EP::Model, inputs::Dict)

"""
function storage_all_reserves(EP::Model, inputs::Dict)

	dfGen = inputs["dfGen"]
	T = inputs["T"]

	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"]

	STOR_ALL = inputs["STOR_ALL"]

	STOR_REG_RSV = intersect(STOR_ALL, inputs["REG"], inputs["RSV"]) # Set of storage resources with both REG and RSV reserves

	STOR_REG = intersect(STOR_ALL, inputs["REG"]) # Set of storage resources with REG reserves
	STOR_RSV = intersect(STOR_ALL, inputs["RSV"]) # Set of storage resources with RSV reserves

	STOR_NO_RES = setdiff(STOR_ALL, STOR_REG, STOR_RSV) # Set of storage resources with no reserves

	STOR_REG_ONLY = setdiff(STOR_REG, STOR_RSV) # Set of storage resources only with REG reserves
	STOR_RSV_ONLY = setdiff(STOR_RSV, STOR_REG) # Set of storage resources only with RSV reserves

	if !isempty(STOR_REG_RSV)
		# Storage units charging can charge faster to provide reserves down and charge slower to provide reserves up
		@constraints(EP, begin
			# Maximum storage contribution to reserves is a specified fraction of installed discharge power capacity
			[y in STOR_REG_RSV, t=1:T], EP[:vREG][y,t] <= dfGen[!,:Reg_Max][y]*EP[:eTotalCap][y]
			[y in STOR_REG_RSV, t=1:T], EP[:vRSV][y,t] <= dfGen[!,:Rsv_Max][y]*EP[:eTotalCap][y]

			# Actual contribution to regulation and reserves is sum of auxilary variables for portions contributed during charging and discharging
			[y in STOR_REG_RSV, t=1:T], EP[:vREG][y,t] == EP[:vREG_charge][y,t]+EP[:vREG_discharge][y,t]
			[y in STOR_REG_RSV, t=1:T], EP[:vRSV][y,t] == EP[:vRSV_charge][y,t]+EP[:vRSV_discharge][y,t]

			# Maximum charging rate plus contribution to reserves up must be greater than zero
			# Note: when charging, reducing charge rate is contributing to upwards reserve & regulation as it drops net demand
			[y in STOR_REG_RSV, t=1:T], EP[:vCHARGE][y,t]-EP[:vREG_charge][y,t]-EP[:vRSV_charge][y,t] >= 0

			# Maximum discharging rate and contribution to reserves down must be greater than zero
			# Note: when discharging, reducing discharge rate is contributing to downwards regulation as it drops net supply
			[y in STOR_REG_RSV, t=1:T], EP[:vP][y,t]-EP[:vREG_discharge][y,t] >= 0

			# Maximum charging rate plus contribution to regulation down must be less than available storage capacity
			## Made change to let the model run and not have key error issue for time -Sam (04/20/2021)
			[y in STOR_REG_RSV, t in START_SUBPERIODS], EP[:vCHARGE][y,t]+EP[:vREG_charge][y,t] <= EP[:eTotalCapEnergy][y]-EP[:vS][y,t+hours_per_subperiod-1]
			[y in STOR_REG_RSV, t in INTERIOR_SUBPERIODS], EP[:vCHARGE][y,t]+EP[:vREG_charge][y,t] <= EP[:eTotalCapEnergy][y]-EP[:vS][y,t-1]
			# Note: maximum charge rate is also constrained by maximum charge power capacity, but as this differs by storage type,
			# this constraint is set in functions below for each storage type

			# Maximum discharging rate and contribution to reserves up must be less than power rating OR available stored energy in prior period, whichever is less
			# wrapping from end of sample period to start of sample period for energy capacity constraint
			[y in STOR_REG_RSV, t=1:T], EP[:vP][y,t]+EP[:vREG_discharge][y,t]+EP[:vRSV_discharge][y,t] <= EP[:eTotalCap][y]
			[y in STOR_REG_RSV, t in INTERIOR_SUBPERIODS], EP[:vP][y,t]+EP[:vREG_discharge][y,t]+EP[:vRSV_discharge][y,t] <= EP[:vS][y,t-1]
			[y in STOR_REG_RSV, t in START_SUBPERIODS], EP[:vP][y,t]+EP[:vREG_discharge][y,t]+EP[:vRSV_discharge][y,t] <= EP[:vS][y,t+hours_per_subperiod-1]
		end)
	end
	if !isempty(STOR_REG_ONLY)
		# Storage units charging can charge faster to provide reserves down and charge slower to provide reserves up
		@constraints(EP, begin
			# Maximum storage contribution to reserves is a specified fraction of installed capacity
			[y in STOR_REG_ONLY, t=1:T], EP[:vREG][y,t] <= dfGen[!,:Reg_Max][y]*EP[:eTotalCap][y]

			# Actual contribution to regulation and reserves is sum of auxilary variables for portions contributed during charging and discharging
			[y in STOR_REG_ONLY, t=1:T], EP[:vREG][y,t] == EP[:vREG_charge][y,t]+EP[:vREG_discharge][y,t]

			# Maximum charging rate plus contribution to reserves up must be greater than zero
			# Note: when charging, reducing charge rate is contributing to upwards reserve & regulation as it drops net demand
			[y in STOR_REG_ONLY, t=1:T], EP[:vCHARGE][y,t]-EP[:vREG_charge][y,t] >= 0

			# Maximum discharging rate and contribution to reserves down must be greater than zero
			# Note: when discharging, reducing discharge rate is contributing to downwards regulation as it drops net supply
			[y in STOR_REG_ONLY, t=1:T], EP[:vP][y,t] - EP[:vREG_discharge][y,t] >= 0

			# Maximum charging rate plus contribution to regulation down must be less than available storage capacity
			[y in STOR_REG_ONLY, t in START_SUBPERIODS], EP[:vCHARGE][y,t]+EP[:vREG_charge][y,t] <= EP[:eTotalCapEnergy][y]-EP[:vS][y,t+hours_per_subperiod-1]
			[y in STOR_REG_ONLY, t in INTERIOR_SUBPERIODS], EP[:vCHARGE][y,t]+EP[:vREG_charge][y,t] <= EP[:eTotalCapEnergy][y]-EP[:vS][y,t-1]
			# Note: maximum charge rate is also constrained by maximum charge power capacity, but as this differs by storage type,
			# this constraint is set in functions below for each storage type

			# Maximum discharging rate and contribution to reserves up must be less than power rating OR available stored energy in prior period, whichever is less
			# wrapping from end of sample period to start of sample period for energy capacity constraint
			[y in STOR_REG_ONLY, t=1:T], EP[:vP][y,t] + EP[:vREG_discharge][y,t] <= EP[:eTotalCap][y]
			[y in STOR_REG_ONLY, t in INTERIOR_SUBPERIODS], EP[:vP][y,t]+EP[:vREG_discharge][y,t] <= EP[:vS][y,t-1]
			[y in STOR_REG_ONLY, t in START_SUBPERIODS], EP[:vP][y,t]+EP[:vREG_discharge][y,t]<= EP[:vS][y,t+hours_per_subperiod-1]
		end)
	end
	if !isempty(STOR_RSV_ONLY)
		# Storage units charging can charge faster to provide reserves down and charge slower to provide reserves up
		@constraints(EP, begin
			# Maximum storage contribution to reserves is a specified fraction of installed capacity
			[y in STOR_RSV_ONLY, t=1:T], EP[:vRSV][y,t] <= dfGen[!,:Rsv_Max][y]*EP[:eTotalCap][y]

			# Actual contribution to regulation and reserves is sum of auxilary variables for portions contributed during charging and discharging
			[y in STOR_RSV_ONLY, t=1:T], EP[:vRSV][y,t] == EP[:vRSV_charge][y,t]+EP[:vRSV_discharge][y,t]

			# Maximum charging rate plus contribution to reserves up must be greater than zero
			# Note: when charging, reducing charge rate is contributing to upwards reserve & regulation as it drops net demand
			[y in STOR_RSV_ONLY, t=1:T], EP[:vCHARGE][y,t]-EP[:vRSV_charge][y,t] >= 0

			# Note: maximum charge rate is also constrained by maximum charge power capacity, but as this differs by storage type,
			# this constraint is set in functions below for each storage type

			# Maximum discharging rate and contribution to reserves up must be less than power rating OR available stored energy in prior period, whichever is less
			# wrapping from end of sample period to start of sample period for energy capacity constraint
			[y in STOR_RSV_ONLY, t=1:T], EP[:vP][y,t]+EP[:vRSV_discharge][y,t] <= EP[:eTotalCap][y]
			[y in STOR_RSV_ONLY, t in INTERIOR_SUBPERIODS], EP[:vP][y,t]+EP[:vRSV_discharge][y,t] <= EP[:vS][y,t-1]
			[y in STOR_RSV_ONLY, t in START_SUBPERIODS], EP[:vP][y,t]+EP[:vRSV_discharge][y,t] <= EP[:vS][y,t+hours_per_subperiod-1]
		end)
	end
	if !isempty(STOR_NO_RES)
		# Maximum discharging rate must be less than power rating OR available stored energy in prior period, whichever is less
		# wrapping from end of sample period to start of sample period for energy capacity constraint
		@constraints(EP, begin
			[y in STOR_NO_RES, t=1:T], EP[:vP][y,t] <= EP[:eTotalCap][y]
			[y in STOR_NO_RES, t in INTERIOR_SUBPERIODS], EP[:vP][y,t] <= EP[:vS][y,t-1]
			[y in STOR_NO_RES, t in START_SUBPERIODS], EP[:vP][y,t] <= EP[:vS][y,t+hours_per_subperiod-1]
		end)
	end
	return EP
end
