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
	h2_production_no_commit(EP::Model, inputs::Dict,setup::Dict)

The h2_generation module creates decision variables, expressions, and constraints related to various hydrogen generation technologies (electrolyzers, natural gas reforming etc.) without unit commitment constraints

**Ramping limits**

Hydrogen resources not subject to unit commitment ($y \in H \setminus UC$) adhere instead to the following ramping limits on hourly changes in power output:

```math
\begin{aligned}
	\Theta_{y,z,t-1} - \Theta_{y,z,t} \leq \kappa_{y,z}^{down} \Delta^{\text{total}}_{y,z} \hspace{1cm} \forall y \in \mathcal{H \setminus UC}, \forall z \in \mathcal{Z}, \forall t \in \mathcal{T}
\end{aligned}
```

```math
\begin{aligned}
	\Theta_{y,z,t} - \Theta_{y,z,t-1} \leq \kappa_{y,z}^{up} \Delta^{\text{total}}_{y,z} \hspace{1cm} \forall y \in \mathcal{H \setminus UC}, \forall z \in \mathcal{Z}, \forall t \in \mathcal{T}
\end{aligned}
```
(See Constraints 1-2 in the code)

This set of time-coupling constraints wrap around to ensure the hydrogen output in the first time step of each year (or each representative period), $t \in \mathcal{T}^{start}$, is within the eligible ramp of the power output in the final time step of the year (or each representative period), $t+\tau^{period}-1$.

**Minimum and maximum hydrogen output**

When not modeling regulation and reserves, hydrogen units not subject to unit commitment decisions are bound by the following limits on maximum and minimum power output:

```math
\begin{aligned}
	\Theta_{y,z,t} \geq \rho^{min}_{y,z} \times \Delta^{total}_{y,z}
	\hspace{1cm} \forall y \in \mathcal{H \setminus UC}, \forall z \in \mathcal{Z}, \forall t \in \mathcal{T}
\end{aligned}
```

```math
\begin{aligned}
	\Theta_{y,z,t} \leq \rho^{max}_{y,z,t} \times \Delta^{total}_{y,z}
	\hspace{1cm} \forall y \in \mathcal{H \setminus UC}, \forall z \in \mathcal{Z}, \forall t \in \mathcal{T}
\end{aligned}
```
"""
function h2_production_no_commit(EP::Model, inputs::Dict,setup::Dict)

	println("H2 Production (No Unit Commitment) Module")
	
	#Rename H2Gen dataframe
	dfH2Gen = inputs["dfH2Gen"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	H = inputs["H2_GEN"]		#NUmber of hydrogen generation units 
	
	H2_GEN_NO_COMMIT = inputs["H2_GEN_NO_COMMIT"]
	
	#Define start subperiods and interior subperiods
	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

	###Expressions###

	#H2 Balance expressions
	@expression(EP, eH2GenNoCommit[t=1:T, z=1:Z],
	sum(EP[:vH2Gen][k,t] for k in intersect(H2_GEN_NO_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] += eH2GenNoCommit

	#Power Consumption for H2 Generation
	#Power Consumption for H2 Generation
	if setup["ParameterScale"] ==1 # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
		@expression(EP, ePowerBalanceH2GenNoCommit[t=1:T, z=1:Z],
		sum(EP[:vP2G][k,t]/ModelScalingFactor for k in intersect(H2_GEN_NO_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]))) 

	else # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of H2 related power consumption
		@expression(EP, ePowerBalanceH2GenNoCommit[t=1:T, z=1:Z],
		sum(EP[:vP2G][k,t] for k in intersect(H2_GEN_NO_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]))) 
	end

	EP[:ePowerBalance] += -ePowerBalanceH2GenNoCommit


	##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
	EP[:eH2NetpowerConsumptionByAll] += ePowerBalanceH2GenNoCommit


	###Constraints###
	# Power and natural gas consumption associated with H2 generation in each time step
	@constraints(EP, begin
		#Power Balance
		[k in H2_GEN_NO_COMMIT, t = 1:T], EP[:vP2G][k,t] == EP[:vH2Gen][k,t] * dfH2Gen[!,:etaP2G_MWh_p_tonne][k]
	end)
	
	@constraints(EP, begin
	# Maximum power generated per technology "k" at hour "t"
	[k in H2_GEN_NO_COMMIT, t=1:T], EP[:vH2Gen][k,t] <= EP[:eH2GenTotalCap][k]* inputs["pH2_Max"][k,t]
	end)

	#Ramping cosntraints 
	@constraints(EP, begin

		## Maximum ramp up between consecutive hours
		# Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
		# NOTE: We should make wrap-around a configurable option
		[k in H2_GEN_NO_COMMIT, t in START_SUBPERIODS], EP[:vH2Gen][k,t]-EP[:vH2Gen][k,(t + hours_per_subperiod-1)] <= dfH2Gen[!,:Ramp_Up_Percentage][k] * EP[:eH2GenTotalCap][k]

		# Interior Hours
		[k in H2_GEN_NO_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2Gen][k,t]-EP[:vH2Gen][k,t-1] <= dfH2Gen[!,:Ramp_Up_Percentage][k]*EP[:eH2GenTotalCap][k]

		## Maximum ramp down between consecutive hours
		# Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
		[k in H2_GEN_NO_COMMIT, t in START_SUBPERIODS], EP[:vH2Gen][k,(t+hours_per_subperiod-1)] - EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k] * EP[:eH2GenTotalCap][k]

		# Interior Hours
		[k in H2_GEN_NO_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2Gen][k,t-1] - EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k] * EP[:eH2GenTotalCap][k]
	
	end)

	return EP

end




