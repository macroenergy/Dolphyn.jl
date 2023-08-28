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
	maximum_capacity_requirement(EP::Model, inputs::Dict)

The maximum capacity requirement constraint allows for modeling maximum deployment of a certain technology or set of eligible technologies across the eligible model zones and can be used to mimic policies supporting specific technology build out (i.e. capacity deployment targets/mandates for storage, offshore wind, solar etc.).
The default unit of the constraint is in MW. For each requirement $p \in \mathcal{P}^{MinCapReq}$, we model the policy with the following constraint.

```math
\begin{equation*}
	%\sum_{g \in \mathcal{G} } \sum_{z \in \mathcal{Z}} \left(\epsilon_{g,z,p}^{MinCapReq} \times y_{g,z}^{\textrm{E,GEN}} \right) \geq REQ_{p}^{MinCapReq} \forall p \in \mathcal{P}^{MinCapReq}
	\sum_{y \in \mathcal{G} } \sum_{z \in \mathcal{Z}} \left(\epsilon_{y,z,p}^{MaxCapReq} \times x_{y,z}^{\textrm{E,GEN}} \right) \leq REQ_{p}^{MaxCapReq} \forall p \in \mathcal{P}^{MaxCapReq}
\end{equation*}
```

Note that $\epsilon_{g,z,p}^{MinCapReq}$ is the eligiblity of a generator of technology $g$ in zone $z$ of requirement $p$ and will be equal to $1$ for eligible generators and will be zero for ineligible resources.
Note that $\epsilon_{y,z,p}^{MinCapReq}$ is the eligiblity of a generator of technology $y$ in zone $z$ of requirement $p$ and will be equal to $1$ for eligible generators and will be zero for ineligible resources.
The dual value of each minimum capacity constraint can be interpreted as the required payment (e.g. subsidy) per MW per year required to ensure adequate revenue for the qualifying resources.
"""
function maximum_capacity_requirement(EP::Model, inputs::Dict)

	print_and_log("Maximum Capacity Requirement Module")

	dfGen = inputs["dfGen"]
	NumberOfMaxCapReqs = inputs["NumberOfMaxCapReqs"]
	@constraint(EP, cZoneMinCapReq[maxcap = 1:NumberOfMaxCapReqs],
	sum(EP[:eTotalCap][y]
	for y in dfGen[(dfGen[!,Symbol("MaxCapTag_$maxcap")].== 1) ,:][!,:R_ID])
	<= inputs["MaxCapReq"][maxcap])

	return EP
end
