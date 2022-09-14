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
	h2_g2p_all(EP::Model, inputs::Dict, setup::Dict)

The hydrogen to power module creates decision variables, expressions, and constraints related to hydrogen generation infrastructure
- Investment and FOM cost expression, VOM cost expression, minimum and maximum capacity limits

One cannot retire more capacity than existing capacity.
```math
\begin{aligned}
&\Delta_{y,z} \leq \overline{\Delta_{y,z}}
	\hspace{4 cm}  \forall y \in \mathcal{G}, z \in \mathcal{Z}
\end{aligned}
```

For resources where $\overline{\Omega_{y,z}}$ and $\underline{\Omega_{y,z}}$ is defined, then we impose constraints on minimum and maximum power capacity.
```math
\begin{aligned}
& \Delta^{total}_{y,z} \leq \overline{\Omega}_{y,z}
	\hspace{4 cm}  \forall y \in \mathcal{G}, z \in \mathcal{Z} \\
& \Delta^{total}_{y,z}  \geq \underline{\Omega}_{y,z}
	\hspace{4 cm}  \forall y \in \mathcal{G}, z \in \mathcal{Z}
\end{aligned}
```
"""
function h2_g2p_all(EP::Model, inputs::Dict, setup::Dict)

	dfH2G2P = inputs["dfH2G2P"]

	#Define sets
	H2_G2P_NO_COMMIT= inputs["H2_G2P_NO_COMMIT"]
	H2_G2P_COMMIT = inputs["H2_G2P_COMMIT"]
	H2_G2P = inputs["H2_G2P"]
	H2_G2P_RET_CAP = inputs["H2_G2P_RET_CAP"]
	H =inputs["H2_G2P_ALL"]

	T = inputs["T"]     # Number of time steps (hours)

	####Variables####
	#Define variables needed across both commit and no commit sets

    #H2 required by G2P resource k to make hydrogen (Tonne/Hr)
	@variable(EP, vH2G2P[k in H2_G2P, t = 1:T] >= 0 )

	### Constratints ###

	## Constraints on retirements and capacity additions
	# Cannot retire more capacity than existing capacity
	@constraint(EP, cH2G2PMaxRetNoCommit[k in setdiff(H2_G2P_RET_CAP, H2_G2P_NO_COMMIT)], EP[:vH2G2PRetCap][k] <= dfH2G2P[!,:Existing_Cap_MW][k])
	@constraint(EP, cH2G2PMaxRetCommit[k in intersect(H2_G2P_RET_CAP, H2_G2P_COMMIT)], dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PRetCap][k] <= dfH2G2P[!,:Existing_Cap_MW][k])

	## Constraints on new built capacity
	# Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
	@constraint(EP, cH2G2PMaxCap[k in intersect(dfH2G2P[dfH2G2P.Max_Cap_MW.>0,:R_ID], 1:H)],EP[:eH2G2PTotalCap][k] <= dfH2G2P[!,:Max_Cap_MW][k])

	# Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is <= Min_Cap_MW and lead to infeasabilty
	@constraint(EP, cH2G2PMinCap[k in intersect(dfH2G2P[dfH2G2P.Min_Cap_MW.>0,:R_ID], 1:H)], EP[:eH2G2PTotalCap][k] >= dfH2G2P[!,:Min_Cap_MW][k])

	return EP

end