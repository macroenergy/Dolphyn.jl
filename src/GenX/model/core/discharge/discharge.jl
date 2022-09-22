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
	discharge(EP::Model, inputs::Dict)

Sets up variables common to all generation resources.

This module defines the following variables:
- Thermal output decision variable $x_{k,z,t}^{\textrm{E,THE}} \forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$. This variable represents energy injected into the grid by thermal resource $k$ in zone $z$ at time period $t$.
- Renewable output decision variable $x_{r,z,t}^{\textrm{E,VRE}} \forall r \in \mathcal{R}, z \in \mathcal{Z}, t \in \mathcal{T}$. This variable represents energy injected into the grid by renewable resource $r$ in zone $z$ at time period $t$.
- Storage output decision variable $x_{s,z,t}^{\textrm{E,DIS}} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$. This variable represents energy injected into the grid by storage resource $s$ in zone $z$ at time period $t$.

The variable defined in this file named after ```vP``` covers all variables $x_{k,z,t}^{\textrm{E,THE}}, x_{r,z,t}^{\textrm{E,VRE}}, x_{s,z,t}^{\textrm{E,DIS}}$.

```math
\begin{equation*}
	x_{g,z,t}^{\textrm{E,GEN}} =
	\begin{cases}
		x_{k,z,t}^{\textrm{E,THE}} \quad if \quad g \in \mathcal{K} \\
		x_{r,z,t}^{\textrm{E,VRE}} \quad if \quad g \in \mathcal{R} \\
		x_{s,z,t}^{\textrm{E,DIS}} \quad if \quad g \in \mathcal{S}
	\end{cases}
	\quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable O&M plus fuel cost) from all generation resources $g \in \mathcal{G}$ (thermal, renewable, storage, DR, flexible demand resources and hydro) over all time periods $t \in \mathcal{T}$:

```math
\begin{equation*}
	\textrm{C}^{\textrm{E,GEN,o}} = \sum_{g \in \mathcal{G}} \sum_{t \in \mathcal{T}} \omega_t \times \left(\textrm{c}_{g}^{\textrm{E,VOM}} + \textrm{c}_{g}^{\textrm{E,FUEL}}\right) \times x_{g,z,t}^{\textrm{E,GEN}}
\end{equation*}
```
"""
function discharge(EP::Model, inputs::Dict)

	println("Discharge Module")

	dfGen = inputs["dfGen"]

	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps
	Z = inputs["Z"]     # Number of zones
	### Variables ###

	# Energy injected into the grid by resource "y" at hour "t"
	@variable(EP, vP[y=1:G,t=1:T] >=0);

	### Expressions ###

	## Objective Function Expressions ##

	# Variable costs of "generation" for resource "y" during hour "t" = variable O&M plus fuel cost
	@expression(EP, eCVar_out[y=1:G,t=1:T], (inputs["omega"][t]*(dfGen[!,:Var_OM_Cost_per_MWh][y]+inputs["C_Fuel_per_MWh"][y,t])*vP[y,t]))
	#@expression(EP, eCVar_out[y=1:G,t=1:T], (round(inputs["omega"][t]*(dfGen[!,:Var_OM_Cost_per_MWh][y]+inputs["C_Fuel_per_MWh"][y,t]), digits=RD)*vP[y,t]))
	# Sum individual resource contributions to variable discharging costs to get total variable discharging costs
	@expression(EP, eTotalCVarOutT[t=1:T], sum(eCVar_out[y,t] for y in 1:G))
	@expression(EP, eTotalCVarOut, sum(eTotalCVarOutT[t] for t in 1:T))

	# Add total variable discharging cost contribution to the objective function
	EP[:eObj] += eTotalCVarOut

	return EP

end
