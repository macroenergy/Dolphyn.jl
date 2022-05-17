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
    co2_outputs(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the production decision variable  representing carbon injected into the network by resource $k$ by at time period $t$.

This module additionally defines contributions to the objective function from variable costs of capture (variable O&M plus fuel cost) from all resources over all time periods.

"""

function co2_outputs(EP::Model, inputs::Dict, setup::Dict)

	println("DAC variable cost module")

    dfCO2Capture = inputs["dfCO2Capture"]
	CO2_RES_ALL = inputs["CO2_RES_ALL"]

	#Define sets
	T = inputs["T"]     # Number of time steps (hours)

	#####################################################################################################################################
	##Variables
	#CO2 captured from carbon capture resource k (tonnes of CO2/hr) in time t
	@variable(EP, vDAC_CO2_Captured[k=1:CO2_RES_ALL, t = 1:T] >= 0 )

	#Power required by carbon capture resource k (MW)
	@variable(EP, vPower_DAC[k=1:CO2_RES_ALL, t = 1:T] >= 0 )

	#####################################################################################################################################
	##Expressions
	if setup["ParameterScale"] == 1
		@expression(EP,eVar_OM_DAC_per_type_per_time[k=1:CO2_RES_ALL, t = 1:T], dfCO2Capture[!,:etaFuel_MMBtu_p_tonne][k] * inputs["fuel_costs"][dfCO2Capture[!,:Fuel][k]][t]/ModelScalingFactor * EP[:vDAC_CO2_Captured][k,t] )
	else
		@expression(EP,eVar_OM_DAC_per_type_per_time[k=1:CO2_RES_ALL, t = 1:T], dfCO2Capture[!,:etaFuel_MMBtu_p_tonne][k] * inputs["fuel_costs"][dfCO2Capture[!,:Fuel][k]][t] * EP[:vDAC_CO2_Captured][k,t] )
	end

	#Total variable cost per resource type
	@expression(EP, eVar_OM_DAC_per_time[t=1:T], sum(EP[:eVar_OM_DAC_per_type_per_time][k,t] for k in 1:CO2_RES_ALL))
	@expression(EP, eVar_OM_DAC, sum(EP[:eVar_OM_DAC_per_time][t] for t in 1:T))

	# Add total variable cost contribution to the objective function
	EP[:eObj] += EP[:eVar_OM_DAC]

	return EP

end
