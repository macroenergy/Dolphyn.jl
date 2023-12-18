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
	bioenergy_var_cost(EP::Model, inputs::Dict, setup::Dict)

Sets up variables common to all biorefinery resources.

This module defines the biorefinery resource decision variable $x_{r,t}^{\textrm{B,Bio}} \forall r \in \mathcal{R}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing biomass input into the biorefinery resource $r$ at time period $t$, $x_{r,t}^{\textrm{E,Bio}} \forall r \in \mathcal{R}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing power input into the biorefinery resource $r$ at time period $t$ (if any), and $x_{r,t}^{\textrm{H,Bio}} \forall r \in \mathcal{R}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing hydrogen input into the biorefinery resource $r$ at time period $t$ (if any). 

The variables defined in this file named after ```vBiomass_consumed_per_plant_per_time``` covers all variables $x_{r,t}^{\textrm{B,Bio}}$.

The variables defined in this file named after ```vPower_BIO``` covers all variables $x_{r,t}^{\textrm{E,Bio}}$ (if any).

The variables defined in this file named after ```vH2_BIO``` covers all variables $x_{r,t}^{\textrm{H,Bio}}$ (if any).

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable OM) from all biorefinery resources over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{Bio,o}} = \sum_{r \in \mathcal{R}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{r}^{\textrm{Bio,VOM}} \times x_{r,t}^{\textrm{B,Bio}}
\end{equation*}
```
"""
function bioenergy_var_cost(EP::Model, inputs::Dict, setup::Dict)

	println("Biorefinery variable cost module")

    dfbioenergy = inputs["dfbioenergy"]
	BIO_RES_ALL = inputs["BIO_RES_ALL"]

	#Define sets
	T = inputs["T"]     # Number of time steps (hours)

	#####################################################################################################################################
	#Variables
	@variable(EP,vBiomass_consumed_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T] >= 0)

	#Power required by bioenergy plant i (MW)
	@variable(EP,vPower_BIO[i=1:BIO_RES_ALL, t = 1:T] >= 0)

	#Hydrogen required by bioenergy plant i (tonne/h)
	@variable(EP,vH2_BIO[i=1:BIO_RES_ALL, t = 1:T] >= 0)

	#####################################################################################################################################
	#Variable cost per plant per time
	if setup["ParameterScale"] ==1
		@expression(EP, eVar_Cost_BIO_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], inputs["omega"][t] * EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:Var_OM_per_tonne][i]/ModelScalingFactor)
	else
		@expression(EP, eVar_Cost_BIO_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], inputs["omega"][t] * EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:Var_OM_per_tonne][i])
	end

	#Variable cost per plant
	@expression(EP, eVar_Cost_BIO_per_plant[i in 1:BIO_RES_ALL], sum(EP[:eVar_Cost_BIO_per_plant_per_time][i,t] for t in 1:T))

	#Total variable cost
	@expression(EP, eVar_Cost_BIO, sum(EP[:eVar_Cost_BIO_per_plant][i] for i in 1:BIO_RES_ALL))

	EP[:eObj] += EP[:eVar_Cost_BIO]

	#####################################################################################################################################
	#For Bio-H2 to use in LCOH calculations
	#Variable cost per Bio H2 plant per time
	#if setup["Bio_H2_On"] == 1
	#	if setup["ParameterScale"] ==1
	#		@expression(EP, eVar_Cost_BIO_H2_per_plant_per_time[i in BIO_H2, t in 1:T], inputs["omega"][t] * EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:Var_OM_per_tonne][i]/ModelScalingFactor)
	#	else
	#		@expression(EP, eVar_Cost_BIO_H2_per_plant_per_time[i in BIO_H2, t in 1:T], inputs["omega"][t] * EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:Var_OM_per_tonne][i])
	#	end
		
		#Variable cost per Bio H2 plant
	#	@expression(EP, eVar_Cost_BIO_H2_per_plant[i in BIO_H2], sum(EP[:eVar_Cost_BIO_H2_per_plant_per_time][i,t] for t in 1:T))

		#Total variable cost for Bio H2
	#	@expression(EP, eVar_Cost_BIO_H2, sum(EP[:eVar_Cost_BIO_H2_per_plant][i] for i in BIO_H2))
	#end
	
	return EP

end
