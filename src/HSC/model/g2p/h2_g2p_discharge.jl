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
	h2_g2p_discharge(EP::Model, inputs::Dict, setup::Dict)

This module defines the production decision variable representing power form hydrogen injected into the network by resource $y$ by at time period $t$.

This module additionally defines contributions to the objective function from variable costs of generation (variable O&M plus fuel cost) from all resources over all time periods.

```math
\begin{aligned}
	Obj_{Var\_g2p} =
	\sum_{h \in \mathcal{H}} \sum_{t \in \mathcal{T}}\omega_{t}\times(\pi^{VOM}_{h} \times \theta_{h,z,t})
\end{aligned}
```
"""
function h2_g2p_discharge(EP::Model, inputs::Dict, setup::Dict)

	println("H2 g2p demand module")

    dfH2G2P = inputs["dfH2G2P"]

	# Define sets
	H = inputs["H2_G2P_ALL"] #Number of Hydrogen gen units
	T = inputs["T"]     # Number of time steps (hours)

	### Variables ###

    #Electricity Discharge from hydrogen G2P resource k (MWh) in time t
	@variable(EP, vPG2P[k=1:H, t = 1:T] >= 0)

	### Expressions ###

	## Objective Function Expressions ##

    # Variable costs of "generation" for resource "y" during hour "t" = variable O&M plus fuel cost

	#  ParameterScale = 1 --> objective function is in million $ . 
	## In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	## Fue cost already scaled by 1000 in load_fuels_data.jl sheet, so  need to scale variable OM cost component by million and fuel cost component by 1000 here.
	#  ParameterScale = 0 --> objective function is in $

	if setup["ParameterScale"] ==1
		@expression(EP, eCH2G2PVar_out[k = 1:H,t = 1:T], 
		inputs["omega"][t] * (dfH2G2P[!,:Var_OM_Cost_p_MWh][k]/ModelScalingFactor^2) * vPG2P[k,t])
	else
		@expression(EP, eCH2G2PVar_out[k = 1:H,t = 1:T], 
		inputs["omega"][t] * dfH2G2P[!,:Var_OM_Cost_p_MWh][k] * vPG2P[k,t])
	end

	@expression(EP, eTotalCH2G2PVarOutT[t=1:T], sum(eCH2G2PVar_out[k,t] for k in 1:H))
	@expression(EP, eTotalCH2G2PVarOut, sum(eTotalCH2G2PVarOutT[t] for t in 1:T))
	
	# Add total variable discharging cost contribution to the objective function
	EP[:eObj] += eTotalCH2G2PVarOut

	return EP

end
