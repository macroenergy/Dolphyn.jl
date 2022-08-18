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
	storage_symmetric(EP::Model, inputs::Dict, Reserves::Int)

Sets up variables and constraints specific to storage resources with symmetric charge and discharge capacities.

For storage technologies with symmetric charge and discharge capacity (all $s \in \mathcal{S}^{sym}$), charge rate, $x_{s,z,t}^{E,CHA}$, is constrained by the total installed power capacity $y_{s,z}^{E,STO,POW}$. 
Since storage resources generally represent a `cluster' of multiple similar storage devices of the same type/cost in the same zone, DOLPHYN permits storage resources to simultaneously charge and discharge (as some units could be charging while others discharge), 
with the simultaenous sum of charge $x_{s,z,t}^{E,CHA}$, and discharge $x_{s,z,t}^{E,DIS}$, also limited by the total installed power capacity, $y_{s,z}^{E,STO,POW}$. 
These two constraints are as follows:

```math
\begin{equation}
	x_{s,z,t}^{E,CHA} \leq y_{s,z}^{E,STO,POW} \quad \forall s \in \mathcal{S}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation}
```

```math
\begin{equation}
	x_{s,z,t}^{E,CHA} + x_{s,z,t}^{E,DIS} \leq y_{s,z}^{E,STO,POW} \quad \forall s \in \mathcal{S}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation}
```
"""
function storage_symmetric(EP::Model, inputs::Dict, Reserves::Int)
	# Set up additional variables, constraints, and expressions associated with storage resources with symmetric charge & discharge capacity
	# (e.g. most electrochemical batteries that use same components for charge & discharge)
	# STOR = 1 corresponds to storage with distinct power and energy capacity decisions but symmetric charge/discharge power ratings

	println("Storage Resources with Symmetric Charge/Discharge Capacity Module")

	dfGen = inputs["dfGen"]

	T = inputs["T"]     # Number of time steps (hours)

	STOR_SYMMETRIC = inputs["STOR_SYMMETRIC"]

	### Constraints ###

	# Storage discharge and charge power (and reserve contribution) related constraints for symmetric storage resources:
	if Reserves == 1
		EP = storage_symmetric_reserves(EP, inputs)
	else
		@constraints(EP, begin
			# Maximum charging rate must be less than symmetric power rating
			[y in STOR_SYMMETRIC, t in 1:T], EP[:vCHARGE][y,t] <= EP[:eTotalCap][y]

			# Max simultaneous charge and discharge cannot be greater than capacity
			[y in STOR_SYMMETRIC, t in 1:T], EP[:vP][y,t]+EP[:vCHARGE][y,t] <= EP[:eTotalCap][y]
		end)
	end

	return EP
end

@doc raw"""
	storage_symmetric_reserves(EP::Model, inputs::Dict)

Sets up variables and constraints specific to storage resources with symmetric charge and discharge capacities when reserves are modeled.

If reserves are modeled, the following two constraints replace those above:

```math
\begin{aligned}
	x_{s,z,t}^{E,CHA} + f_{s,z,t}^{E,CHA} &\leq y_{s,z}^{E,STO,POW} \quad \forall s \in \mathcal{S}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T} \\
	x_{s,z,t}^{E,CHA} + f_{s,z,t}^{E,CHA} + x_{s,z,t}^{E,DIS} + f_{s,z,t}^{E,DIS} + r_{s,z,t}^{E,CHA} \leq y_{s,z}^{E,STO,POW} \quad \forall s \in \mathcal{S}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

where $f_{s,z,t}^{E,CHA}$ is the contribution of storage resources to frequency regulation while charging, $f_{s,z,t}^{E,DIS}$ is the contribution of storage resources to frequency regulation while discharging, and $r_{s,z,t}^{E,DIS}$ is the contribution of storage resources to upward reserves while discharging. 
Note that as storage resources can contribute to regulation and reserves while either charging or discharging, the proxy variables $f_{s,z,t}^{E,CHA}, f_{s,z,t}^{E,DIS}$ and $r_{s,z,t}^{E,CHA}, r_{s,z,t}^{E,DIS}$ are created for storage resources where the total contribution to regulation and reserves, $f_{s,z,t}^{E,STO}, r_{s,z,t}^{E,STO}$ is the sum of the proxy variables.
"""
function storage_symmetric_reserves(EP::Model, inputs::Dict)

	dfGen = inputs["dfGen"]
	T = inputs["T"]

	STOR_SYMMETRIC = inputs["STOR_SYMMETRIC"]

	STOR_SYM_REG_RSV = intersect(STOR_SYMMETRIC, inputs["REG"], inputs["RSV"]) # Set of symmetric storage resources with both REG and RSV reserves

	STOR_SYM_REG = intersect(STOR_SYMMETRIC, inputs["REG"]) # Set of symmetric storage resources with REG reserves
	STOR_SYM_RSV = intersect(STOR_SYMMETRIC, inputs["RSV"]) # Set of symmetric storage resources with RSV reserves

	STOR_SYM_NO_RES = setdiff(STOR_SYMMETRIC, STOR_SYM_REG, STOR_SYM_RSV) # Set of symmetric storage resources with no reserves

	STOR_SYM_REG_ONLY = setdiff(STOR_SYM_REG, STOR_SYM_RSV) # Set of symmetric storage resources only with REG reserves
	STOR_SYM_RSV_ONLY = setdiff(STOR_SYM_RSV, STOR_SYM_REG) # Set of symmetric storage resources only with RSV reserves

	if !isempty(STOR_SYM_REG_RSV)
		# Storage units charging can charge faster to provide reserves down and charge slower to provide reserves up
		@constraints(EP, begin
			# Maximum charging rate plus contribution to regulation down must be less than symmetric power rating
			[y in STOR_SYM_REG_RSV, t in 1:T], EP[:vCHARGE][y,t]+EP[:vREG_charge][y,t] <= EP[:eTotalCap][y]

			# Max simultaneous charge and discharge rates cannot be greater than symmetric charge/discharge capacity
			[y in STOR_SYM_REG_RSV, t in 1:T], EP[:vP][y,t]+EP[:vREG_discharge][y,t]+EP[:vRSV_discharge][y,t]+EP[:vCHARGE][y,t]+EP[:vREG_charge][y,t] <= EP[:eTotalCap][y]
		end)
	end

	if !isempty(STOR_SYM_REG_ONLY)
		# Storage units charging can charge faster to provide reserves down and charge slower to provide reserves up
		@constraints(EP, begin
			# Maximum charging rate plus contribution to regulation down must be less than symmetric power rating
			[y in STOR_SYM_REG_ONLY, t in 1:T], EP[:vCHARGE][y,t]+EP[:vREG_charge][y,t] <= EP[:eTotalCap][y]

			# Max simultaneous charge and discharge rates cannot be greater than symmetric charge/discharge capacity
			[y in STOR_SYM_REG_ONLY, t in 1:T], EP[:vP][y,t]+EP[:vREG_discharge][y,t]+EP[:vCHARGE][y,t]+EP[:vREG_charge][y,t] <= EP[:eTotalCap][y]
		end)
	end

	if !isempty(STOR_SYM_RSV_ONLY)
		# Storage units charging can charge faster to provide reserves down and charge slower to provide reserves up
		@constraints(EP, begin
			# Maximum charging rate must be less than symmetric power rating
			[y in STOR_SYM_RSV_ONLY, t in 1:T], EP[:vCHARGE][y,t] <= EP[:eTotalCap][y]

			# Max simultaneous charge and discharge rates cannot be greater than symmetric charge/discharge capacity
			[y in STOR_SYM_RSV_ONLY, t in 1:T], EP[:vP][y,t]+EP[:vRSV_discharge][y,t]+EP[:vCHARGE][y,t] <= EP[:eTotalCap][y]
		end)
	end

	if !isempty(STOR_SYM_NO_RES)
		@constraints(EP, begin
			# Maximum charging rate must be less than symmetric power rating
			[y in STOR_SYM_NO_RES, t in 1:T], EP[:vCHARGE][y,t] <= EP[:eTotalCap][y]

			# Max simultaneous charge and discharge cannot be greater than capacity
			[y in STOR_SYM_NO_RES, t in 1:T], EP[:vP][y,t]+EP[:vCHARGE][y,t] <= EP[:eTotalCap][y]
		end)
	end

	return EP
end
