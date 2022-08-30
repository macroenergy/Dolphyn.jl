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
    non_served_energy(EP::Model, inputs::Dict)

Sets up variables of non served power demand.

This function defines the non-served energy/curtailed demand decision variable $x_{s,z,t}^{E,NSD} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}$, representing the total amount of demand curtailed in demand segment $s$ at time period $t$ in zone $z$. 
The first segment of non-served energy, $s=1$, is used to denote the cost of involuntary demand curtailment (e.g. emergency load shedding or rolling blackouts), specified as the value of $c_{1}^{E,NSD}$.
Additional segments, $s \geq 2$ can be used to specify a segment-wise approximation of a price elastic demand curve, or segments of price-responsive curtailable loads (aka demand response).
Each segment denotes a price/cost at which the segment of demand is willing to curtail consumption, $n_{s}^{E,NSD}$, representing the marginal willingness to pay for electricity of this segment of demand (or opportunity cost incurred when demand is not served) 
and a maximum quantity of demand in this segment, $n_{s}^{E,NSD}$, specified as a share of demand in each zone in each time step, $D_{z, t}^{E}.$ Note that the current implementation assumes demand segments are an equal share of hourly load in all zones.

The variable defined in this file named after ```vNSE``` covers the variable $x_{s,z,t}^{E,NSD}$.

**Cost expressions**

This function defines contributions to the objective function from the cost of non-served energy/curtailed demand from all demand curtailment segments $s \in \mathcal{SEG}$ over all time periods $t \in \mathcal{T}$ and all zones $z \in \mathcal{Z}$:

```math
\begin{equation*}
	C^{E,NSD} = \sum_{s \in \mathcal{SEG}} \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times n_{s}^{E,NSD} \times x_{s,z,t}^{E,NSD}
\end{equation*}
```

**Power balance expressions**

Contributions to the power balance expression from non-served energy/curtailed demand from each demand segment $s \in \mathcal{SEG}$ are also defined as:

```math
\begin{equation*}
	PowerBal_{NSE} = \sum_{s \in \mathcal{SEG}} x_{s,z,t}^{E,NSD} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

**Bounds on curtailable demand**

Demand curtailed in each segment of curtailable demands $s \in \mathcal{S}$ cannot exceed maximum allowable share of demand:

```math
\begin{equation*}
	0 \leq x_{s,z,t}^{E,NSD} \leq (n_{s}^{E,NSD} \times D_{z,t}) \quad \forall s \in \mathcal{SEG}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

Additionally, total demand curtailed in each time step cannot exceed total demand:

```math
\begin{aligned}
	\sum_{s \in \mathcal{SEG}} x_{s,z,t}^{E,NSD} \leq D_{z,t} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
"""
function non_served_energy(EP::Model, inputs::Dict)

	println("Non-served Energy Module")

	dfGen = inputs["dfGen"]

	T = inputs["T"]     # Number of time steps
	Z = inputs["Z"]     # Number of zones
	SEG = inputs["SEG"] # Number of load curtailment segments

	### Variables ###

	# Non-served energy/curtailed demand in the segment "s" at hour "t" in zone "z"
	@variable(EP, vNSE[s=1:SEG,t=1:T,z=1:Z] >= 0);

	### Expressions ###

	## Objective Function Expressions ##

	# Cost of non-served energy/curtailed demand at hour "t" in zone "z"
	@expression(EP, eCNSE[s=1:SEG,t=1:T,z=1:Z], (inputs["omega"][t]*inputs["pC_D_Curtail"][s]*vNSE[s,t,z]))

	# Sum individual demand segment contributions to non-served energy costs to get total non-served energy costs
	# Julia is fastest when summing over one row one column at a time
	@expression(EP, eTotalCNSETS[t=1:T,z=1:Z], sum(eCNSE[s,t,z] for s in 1:SEG))
	@expression(EP, eTotalCNSET[t=1:T], sum(eTotalCNSETS[t,z] for z in 1:Z))
	@expression(EP, eTotalCNSE, sum(eTotalCNSET[t] for t in 1:T))

	# Add total cost contribution of non-served energy/curtailed demand to the objective function
	EP[:eObj] += eTotalCNSE

	## Power Balance Expressions ##
	@expression(EP, ePowerBalanceNse[t=1:T, z=1:Z], sum(vNSE[s,t,z] for s=1:SEG))

	# Add non-served energy/curtailed demand contribution to power balance expression
	EP[:ePowerBalance] += ePowerBalanceNse

	### Constratints ###

	# Demand curtailed in each segment of curtailable demands cannot exceed maximum allowable share of demand
	@constraint(EP, cNSEPerSeg[s=1:SEG, t=1:T, z=1:Z], vNSE[s,t,z] <= inputs["pMax_D_Curtail"][s]*inputs["pD"][t,z])

	# Total demand curtailed in each time step (hourly) cannot exceed total demand
	@constraint(EP, cMaxNSE[t=1:T, z=1:Z], sum(vNSE[s,t,z] for s=1:SEG) <= inputs["pD"][t,z])

	return EP
end
