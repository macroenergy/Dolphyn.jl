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
biorefinery_var_cost(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the variable costs of biorefineries from all resources over all time periods.

"""

function biorefinery_var_cost(EP::Model, inputs::Dict, setup::Dict)

	println("Biorefinery variable cost module")

    dfbiorefinery = inputs["dfbiorefinery"]
	BIO_RES_ALL = inputs["BIO_RES_ALL"]

	#Define sets
	T = inputs["T"]     # Number of time steps (hours)

	#####################################################################################################################################
	#Variables
	@variable(EP,vBiomass_consumed_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T] >= 0)

	#Power required by biorefinery plant i (MW)
	@variable(EP,vPower_BIO[i=1:BIO_RES_ALL, t = 1:T] >= 0)

	#Hydrogen required by biorefinery plant i (tonne/h)
	@variable(EP,vH2_BIO[i=1:BIO_RES_ALL, t = 1:T] >= 0)

	#####################################################################################################################################
	#Variable cost per plant per time
	if setup["ParameterScale"] ==1
		@expression(EP, eVar_Cost_BIO_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], inputs["omega"][t] * EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbiorefinery[!,:Var_OM_per_tonne][i]/ModelScalingFactor)
	else
		@expression(EP, eVar_Cost_BIO_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], inputs["omega"][t] * EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbiorefinery[!,:Var_OM_per_tonne][i])
	end

	#Variable cost per plant
	@expression(EP, eVar_Cost_BIO_per_plant[i in 1:BIO_RES_ALL], sum(EP[:eVar_Cost_BIO_per_plant_per_time][i,t] for t in 1:T))

	#Total variable cost
	@expression(EP, eVar_Cost_BIO, sum(EP[:eVar_Cost_BIO_per_plant][i] for i in 1:BIO_RES_ALL))

	EP[:eObj] += EP[:eVar_Cost_BIO]

	return EP

end
