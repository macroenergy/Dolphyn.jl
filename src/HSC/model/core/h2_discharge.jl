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
    h2_discharge(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the production decision variable  representing hydrogen injected into the network by resource $y$ by at time period $t$.

This module additionally defines contributions to the objective function from variable costs of generation (variable O&M plus fuel cost) from all resources over all time periods.

"""

function h2_discharge(EP::Model, inputs::Dict)

	println("H2 Discharge Module")

    dfH2Gen = inputs["dfH2Gen"]

	#Define sets
	H = inputs["H2_RES_ALL"] #Number of Hydrogen gen units
	T = inputs["T"]     # Number of time steps (hours)


	### Variables ###

    #H2 injected to hydrogen grid from hydrogen generation resource k (tonnes of H2/hr) in time t
	@variable(EP, vH2Gen[k=1:H, t = 1:T] >= 0 )

	### Expressions ###

	## Objective Function Expressions ##

    # Variable costs of "generation" for resource "y" during hour "t" = variable O&M plus fuel cost
	@expression(EP, eCH2GenVar_out[k = 1:H,t = 1:T], 
	(inputs["omega"][t] * ((dfH2Gen[!,:Var_OM_Cost_per_tonne][k] + inputs["fuel_costs"][dfH2Gen[!,:Fuel][k]][t] * dfH2Gen[!,:etaGas_MMBtu_per_tonne][k])) * vH2Gen[k,t]))

	@expression(EP, eTotalCH2GenVarOutT[t=1:T], sum(eCH2GenVar_out[k,t] for k in 1:H))
	@expression(EP, eTotalCH2GenVarOut, sum(eTotalCH2GenVarOutT[t] for t in 1:T))
	
	# Add total variable discharging cost contribution to the objective function
	EP[:eObj] += eTotalCH2GenVarOut

	return EP

end