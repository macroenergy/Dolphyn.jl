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
	storage_asymmetric(EP::Model, inputs::Dict, Reserves::Int)

Sets up variables and constraints specific to storage resources with asymmetric charge and discharge capacities.

For storage technologies with asymmetric charge and discharge capacities (all $s \in \mathcal{S}^{asym}$), charge rate $x_{s,z,t}^{\textrm{E,CHA}}$, is constrained by the total installed charge capacity $y_{s,z}^{\textrm{E,STO,CHA}}$, as follows:

```math
\begin{equation*}
	0 \leq x_{s,z,t}^{\textrm{E,CHA}} \leq y_{s,z}^{\textrm{E,STO,CHA}} \quad \forall s \in \mathcal{S}^{asym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

If reserves are modeled, the above constraint is replaced by the following:

```math
\begin{equation*}
	0 \leq x_{s,z,t}^{\textrm{E,CHA}} + f_{s,z,t}^{\textrm{E,CHA}} \leq y_{s,z}^{\textrm{E,STO,CHA}} \quad \forall s \in \mathcal{S}^{asym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

where $f_{s,z,t}^{\textrm{E,CHA}}$ is the contribution of storage resources to frequency regulation while charging.
"""
function storage_asymmetric(EP::Model, inputs::Dict, Reserves::Int)
	# Set up additional variables, constraints, and expressions associated with storage resources with asymmetric charge & discharge capacity
	# (e.g. most chemical, thermal, and mechanical storage options with distinct charge & discharge components/processes)
	# STOR = 2 corresponds to storage with distinct power and energy capacity decisions and distinct charge and discharge power capacity decisions/ratings

	print_and_log("Storage Resources with Asmymetric Charge/Discharge Capacity Module")

	dfGen = inputs["dfGen"]

	T = inputs["T"]     # Number of time steps (hours)

	STOR_ASYMMETRIC = inputs["STOR_ASYMMETRIC"]

	### Constraints ###

	# Storage discharge and charge power (and reserve contribution) related constraints for symmetric storage resources:
	if Reserves == 1
		EP = storage_asymmetric_reserves(EP, inputs)
	else
		# Maximum charging rate must be less than charge power rating
		@constraint(EP, [y in STOR_ASYMMETRIC, t in 1:T], EP[:vCHARGE][y,t] <= EP[:eTotalCapCharge][y])
	end

	return EP
end

@doc raw"""
	storage_asymmetric_reserves(EP::Model, inputs::Dict)

Sets up variables and constraints specific to storage resources with asymmetric charge and discharge capacities when reserves are modeled.

If reserves are modeled, two pairs of proxy variables $f_{s,z,t}^{\textrm{E,CHA}}, f_{s,z,t}^{\textrm{E,DIS}}$ and $r_{s,z,t}^{\textrm{E,CHA}}, r_{s,z,t}^{\textrm{E,DIS}}$ are created for storage resources, to denote the contribution of storage resources to regulation or reserves while charging or discharging, respectively. 
The total contribution to regulation and reserves, $f_{s,z,t}^{\textrm{E,STO}}, r_{s,z,t}^{\textrm{E,STO}}$ is then the sum of the proxy variables:

```math
\begin{aligned}
	f_{s,z,t}^{\textrm{E,STO}} &= f_{s,z,t}^{\textrm{E,CHA}} + f_{s,z,t}^{\textrm{E,DIS}} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T} \\
	r_{s,z,t}^{\textrm{E,STO}} &= r_{s,z,t}^{\textrm{E,CHA}} + r_{s,z,t}^{\textrm{E,DIS}} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

The total storage contribution to frequency regulation $f_{s,z,t}^{\textrm{E,STO}}$ and reserves $r_{s,z,t}^{\textrm{E,STO}}$ are each limited specified fraction of installed discharge power capacity $\upsilon^{reg}_{s,z}, \upsilon^{rsv}_{s,z}$), reflecting the maximum ramp rate for the storage resource in whatever time interval defines the requisite response time for the regulation or reserve products (e.g., 5 mins or 15 mins or 30 mins). 
These response times differ by system operator and reserve product, and so the user should define these parameters in a self-consistent way for whatever system context they are modeling.

```math
\begin{aligned}
	f_{s,z,t}^{\textrm{E,STO}} &\leq \upsilon^{reg}_{s,z} \times y_{s,z}^{\textrm{E,STO,POW}} \forall s \in \mathcal{W}, z \in \mathcal{Z}, t \in \mathcal{T} \\
	r_{s,z,t}^{\textrm{E,STO}} &\leq \upsilon^{rsv}_{s,z} \times y_{s,z}^{\textrm{E,STO,POW}} \forall s \in \mathcal{W}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

When charging, reducing the charge rate is contributing to upwards reserve and frequency regulation as it drops net demand. 
As such, the sum of the charge rate plus contribution to regulation and reserves up must be greater than zero. 
Additionally, the discharge rate plus the contribution to regulation must be greater than zero.

```math
\begin{aligned}
	0 \leq x_{s,z,t}^{\textrm{E,CHA}} - f_{s,z,t}^{\textrm{E,CHA}} - r_{s,z,t}^{\textrm{E,CHA}} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T} \\
	0 \leq x_{s,z,t}^{\textrm{E,DIS}} - f_{s,z,t}^{\textrm{E,DIS}} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

Additionally, when reserves are modeled, the maximum charge rate and contribution to regulation while charging can be no greater than the available energy storage capacity, or the difference between the total energy storage capacity $y_{s,z}^{\textrm{E,STO},ENE}$, and the state of charge at the end of the previous time period $U_{s,z,t-1}^{\textrm{E,STO}}$. 
Note that for storage to contribute to reserves down while charging, the storage device must be capable of increasing the charge rate (which increase net load).

```math
\begin{equation*}
	x_{s,z,t}^{\textrm{E,CHA}} + f_{s,z,t}^{\textrm{E,CHA}} \leq y_{s,z}^{\textrm{E,STO,ENE}} - U_{s,z,t-1}^{\textrm{E,STO}} \quad \forall s \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

Finally, the constraints on maximum discharge rate are replaced by the following, to account for capacity contributed to regulation and reserves:

```math
\begin{aligned}
	x_{s,z,t}^{\textrm{E,DIS}} + f_{s,z,t}^{\textrm{E,DIS}} + r_{s,z,t}^{\textrm{E,DIS}} &\leq y_{s,z}^{\textrm{E,STO,POW}} \quad \forall s \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T} \\
	x_{s,z,t}^{\textrm{E,DIS}} + f_{s,z,t}^{\textrm{E,DIS}} + r_{s,z,t}^{\textrm{E,DIS}} &\leq U_{s,z,t-1}^{\textrm{E,STO}} \quad \forall s \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
"""
function storage_asymmetric_reserves(EP::Model, inputs::Dict)

	dfGen = inputs["dfGen"]
	T = inputs["T"]

	STOR_ASYMMETRIC = inputs["STOR_ASYMMETRIC"]

	STOR_ASYM_REG = intersect(STOR_ASYMMETRIC, inputs["REG"]) # Set of asymmetric storage resources with REG reserves
	STOR_ASYM_NO_REG = setdiff(STOR_ASYMMETRIC, STOR_ASYM_REG) # Set of asymmetric storage resources without REG reserves

	if !isempty(STOR_ASYM_REG)
		# Storage units charging can charge faster to provide reserves down and charge slower to provide reserves up
		# Maximum charging rate plus contribution to regulation down must be less than charge power rating
		@constraint(EP, [y in STOR_ASYM_REG, t in 1:T], EP[:vCHARGE][y,t]+EP[:vREG_charge][y,t] <= EP[:eTotalCapCharge][y])
	else
		# Storage units charging can charge faster to provide reserves down and charge slower to provide reserves up
		# Maximum charging rate plus contribution to regulation down must be less than charge power rating
		@constraint(EP, [y in STOR_ASYM_NO_REG, t in 1:T], EP[:vCHARGE][y,t] <= EP[:eTotalCapCharge][y])
	end

	return EP
end
