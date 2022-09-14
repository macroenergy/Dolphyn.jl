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
	h2_production_all(EP::Model, inputs::Dict, setup::Dict)

The h2 generation module creates decision variables, expressions, and constraints related to hydrogen generation infrastructure

This module uses the following 'helper' functions in separate files: ```h2_generation_commit()``` for resources subject to unit commitment decisions and constraints (if any) and ```h2_generation_no_commit()``` for resources not subject to unit commitment (if any).
- Investment and FOM cost expression, VOM cost expression, minimum and maximum capacity limits

**Constraints**
The outputs of each type of H2 generation facilities have to be kept within their lower and upper bounds. q
```math
\begin{aligned}
	\overline{\mathrm{R}}_{k, z}^{\mathrm{GEN}} \mathrm{M}_{k, z}^{\mathrm{GEN}} n_{k, z, t} \geq h_{k, z, t}^{\mathrm{GEN}} \geq \underline{\mathrm{R}}_{k, z}^{\mathrm{GEN}} \mathbf{M}_{k, z}^{\mathrm{GEN}} n_{k, z, t} \\
	\forall k \in \mathbb{K}, z \in \mathbb{Z}, t \in \mathbb{T}
\end{aligned}
```

The number of online units has to be less than the available number of generation units.
```math
\begin{aligned}
	n_{k, z, t} \leq N_{k, z} \quad \forall k \in \mathbb{K}, z \in \mathbb{Z}, t \in \mathbb{T}
\end{aligned}
```

There are limits on the period of time between when a unit starts up and when it can be shut-down again, and vice versa
```math
\begin{aligned}
	n_{k, z, t} \geq \sum_{\tau=t-\tau_{k, z}^{\mathrm{UP}}}^{t} n_{k, z, t}^{\mathrm{UP}} \quad \forall k \in \mathbb{K}, z \in \mathbb{Z}, t \in \mathbb{T}
	N_{k, z}-n_{k, z, t} \geq \sum_{\tau=t-\tau_{k, z}^{\mathrm{DOWN}}}^{t} n_{k, z, t}^{\mathrm{DOWN}} \quad \forall k \in \mathbb{K}, z \in \mathbb{Z}, t \in \mathbb{T}
\end{aligned}
```

**Expressions**
The numbers of units starting up and shutting down are modeled as:
```math
\begin{aligned}
	n_{k, z, t}-n_{k, z, t-1}=n_{k, z, t}^{\mathrm{UP}}-n_{k, z, t}^{\mathrm{DOWN}} \quad \forall k \in \mathbb{K}, z \in \mathbb{Z}, t \in \mathbb{T}
\end{aligned}
```
"""
function h2_production_all(EP::Model, inputs::Dict, setup::Dict)

	println("H2 Production Core Module")
	
	dfH2Gen = inputs["dfH2Gen"]

	#Define sets
	H2_GEN_NO_COMMIT= inputs["H2_GEN_NO_COMMIT"]
	H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
	H2_GEN = inputs["H2_GEN"]
	H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"]
	H =inputs["H2_RES_ALL"]

	T = inputs["T"]     # Number of time steps (hours)

	####Variables####
	#Define variables needed across both commit and no commit sets

    #Power required by hydrogen generation resource k to make hydrogen (MW)
	@variable(EP, vP2G[k in H2_GEN, t = 1:T] >= 0 )

	### Constratints ###

	## Constraints on retirements and capacity additions
	# Cannot retire more capacity than existing capacity
	@constraint(EP, cH2GenMaxRetNoCommit[k in setdiff(H2_GEN_RET_CAP, H2_GEN_NO_COMMIT)], EP[:vH2GenRetCap][k] <= dfH2Gen[!,:Existing_Cap_tonne_p_hr][k])
	@constraint(EP, cH2GenMaxRetCommit[k in intersect(H2_GEN_RET_CAP, H2_GEN_COMMIT)], dfH2Gen[!,:Cap_Size_tonne_p_hr][k] * EP[:vH2GenRetCap][k] <= dfH2Gen[!,:Existing_Cap_tonne_p_hr][k])

	## Constraints on new built capacity
	# Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
	@constraint(EP, cH2GenMaxCap[k in intersect(dfH2Gen[dfH2Gen.Max_Cap_tonne_p_hr.>0,:R_ID], 1:H)],EP[:eH2GenTotalCap][k] <= dfH2Gen[!,:Max_Cap_tonne_p_hr][k])

	# Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is <= Min_Cap_MW and lead to infeasabilty
	@constraint(EP, cH2GenMinCap[k in intersect(dfH2Gen[dfH2Gen.Min_Cap_tonne_p_hr.>0,:R_ID], 1:H)], EP[:eH2GenTotalCap][k] >= dfH2Gen[!,:Min_Cap_tonne_p_hr][k])

	return EP

end