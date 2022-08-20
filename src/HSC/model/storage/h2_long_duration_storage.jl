"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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
	h2_long_duration_storage(EP::Model, inputs::Dict)
	
Sets up variables and constraints common to all long duration hydrogen storage resources.

This function creates variables and constraints enabling modeling of long duration hydrogen storage resources when modeling representative time periods.

**Long duration hydrogen storage initial inventory and change decision variables**

This module defines the initial storage hydrogen inventory level variable $U_{s,z,t}^{H,STO} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T_{p}^{start}}$, representing initial hydrogen stored in the storage device $s$ in zone $z$ at all starting time period $t$ of modeled periods.

This module defines the change of storage hydrogen inventory level during each representative period $\Delta U_{s,z,m}^{H,STO} \forall s \in \mathcal{S}, z \in \mathcal{Z}, m \in \mathcal{M}$, representing the change of storage hydrogen inventory level of the storage device $s$ in zone $z$ during each representative period $m$.

The variable defined in this file named after ```vH2SOCw``` covers $U_{s,z,t}^{H,STO} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T_{p}^{start}}$.

The variable defined in this file named after ```vdH2SOC``` covers $\Delta U_{s,z,m}^{H,STO} \forall s \in \mathcal{S}, z \in \mathcal{Z}, m \in \mathcal{M}$.

**Storage inventory balance at beginning of each representative period**

The constraints in this section are used to approximate the behavior of long-duration hydrogen storage technologies when approximating annual grid operations by modeling operations over representative periods. 
Previously, the state of charge balance for storage (as defined in ```storage_all()```) assumed that state of charge at the beginning and end of each representative period has to be the same. 
In other words, the amount of hydrogen built up or consumed by storage technology $s$ in zone $z$ over the representative period $m$, $\Delta U_{s,z,m}^{H,STO} = 0$. 
This assumption implicitly excludes the possibility of transferring hydrogen from one representative period to the other which could be cost-optimal when the capital cost of hydrogen storage capacity is relatively small. 
To model long-duration hydrogen storage using representative periods, we replace the state of charge equation, such that the first term on the right hand side accounts for change in hydrogen storage inventory associated with representative period $m$ ($\Delta U_{s,z,m}^{H,STO}$), which could be positive (net accumulation) or negative (net reduction).

```math
\begin{equation}
	U_{s,z,(m-1)\times\tau^{period}+1}^{H,STO} = \left(1-\eta_{s,z}^{H,STO,loss}\right) \times \left(U_{s,z,m\times \tau^{period}} - \Delta U_{s,z,m}\right) - \frac{1}{\eta_{s,z}^{H,STO,DIS}}x_{s,z,(m-1)\times \tau^{period}+1}^{H,STO} + \eta_{s,z}^{H,STO,CHA}x_{s,z,(m-1)\times \tau^{period}+1}^{H,STO} \quad \forall s \in \mathcal{S}^{LDES}, z \in \mathcal{Z}, m \in \mathcal{M}
\end{equation}
```

By definition $\mathcal{T}^{start}=\{\left(m-1\right) \times \tau^{period}+1 | m \in \mathcal{M}\}$, which implies that this constraint is defined for all values of $t \in T^{start}$.

**Hydrogen storage inventory change input periods**

We need additional variables and constraints to approximate hydrogen exchange between representative periods, while accounting for their chronological occurence in the original input time series data and the possibility that two representative periods may not be adjacent to each other (see Figure below). 
To implement this, we introduce a new variable $U_{s,z,n}$ that models inventory of storage technology $s \in \mathcal{S}$ in zone $z$ in each input period $n \in \mathcal{N}$. 
Additionally we define a function mapping, $f: n \rightarrow m$, that uniquely maps each input period $n$ to its corresponding representative period $m$. This mapping is available as an output of the process used to identify representative periods (E.g. k-means clustering [Mallapragada et al., 2018](https://www.sciencedirect.com/science/article/pii/S0360544218315238?casa_token=I-6GVNMtAVIAAAAA:G8LFXFqXxRGrXHtrzmiIGm02BusIUmm83zKh8xf1BXY81-dTnA9p2YI1NnGuzlYBXsxK12by)).

![Modeling inter-period hydrogen exchange via long-duration storage when using representative period temporal resolution to approximate annual grid operations](assets/LDES_approach.png)
*Figure. Modeling inter-period hydrogen exchange via long-duration storage when using representative period temporal resolution to approximate annual grid operations*

The following two equations define the hydrogen storage inventory at the beginning of each input period $n+1$ as the sum of storage inventory at begining of previous input period $n$ plus change in storage inventory for that period. 
The latter is approximated by the change in storage inventory in the corresponding representative period, identified per the mapping $f(n)$. 
The second constraint relates the storage level of the last input period, $|N|$, with the storage level at the beginning of the first input period. 
Finally, if the input period is also a representative period, then a third constraint enforces that initial storage level estimated by the intra-period storage balance constraint should equal the initial storage level estimated from the inter-period storage balance constraints. 
Note that $|N|$ refers to the last modeled period.

```math
\begin{equation}
	U_{s,z,n+1}^{H,STO} = U_{s,z,n}^{H,STO} + \Delta U_{s,z,f(n)} \quad \forall s \in \mathcal{S}^{LDES}, z \in \mathcal{Z}, n \in \mathcal{N}\setminus\{|N|\}
\end{equation}
```

```math
\begin{equation}
	U_{s,z,1}^{H,STO} = U_{s,z,|N|}^{H,STO} + \Delta U_{s,z,f(|N|)}^{H,STO} \quad \forall s \in \mathcal{S}^{LDES}, z \in \mathcal{Z}, n = |N|
\end{equation}
```

```math
\begin{equation}
	U_{s,z,n}^{H,STO} = U_{s,z,f(n) \times \tau^{period}}^{H,STO} - \Delta U_{s,z,m}^{H,STO} \quad \forall s \in \mathcal{S}^{LDES}, z \in \mathcal{Z}, n \in \mathcal{N}^{rep},
\end{equation}
```

Finally, the next constraint enforces that the initial storage level for each input period $n$ must be less than the installed energy capacity limit. 
This constraint ensures that installed energy storage capacity is consistent with the state of charge during both the operational time periods $t$ during each sample period $m$ as well as at the start of each chronologically ordered input period $n$ in the full annual time series.

```math
\begin{equation}
    U_{s,z,n}^{H,STO} \leq y_{s,z}^{H,STO,ENE} \quad \forall s \in \mathcal{S}^{LDES}, z \in \mathcal{Z}, n \in \mathcal{N}
\end{equation}
```
"""
function h2_long_duration_storage(EP::Model, inputs::Dict)

	println("Hydrogen Long Duration Storage Module")

	dfH2Gen = inputs["dfH2Gen"]

	REP_PERIOD = inputs["REP_PERIOD"]     # Number of representative periods

	H2_STOR_LONG_DURATION = inputs["H2_STOR_LONG_DURATION"]
	START_SUBPERIODS = inputs["START_SUBPERIODS"]

	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

	dfPeriodMap = inputs["Period_Map"] # Dataframe that maps modeled periods to representative periods
	NPeriods = size(inputs["Period_Map"])[1] # Number of modeled periods

	MODELED_PERIODS_INDEX = 1:NPeriods
	REP_PERIODS_INDEX = MODELED_PERIODS_INDEX[dfPeriodMap[!,:Rep_Period] .== MODELED_PERIODS_INDEX]

	### Variables ###

	# Variables to define inter-period energy transferred between modeled periods

	# State of charge of H2 storage at beginning of each modeled period n
	@variable(EP, vH2SOCw[y in STOR_LONG_DURATION, n in MODELED_PERIODS_INDEX] >= 0)

	# Build up in storage inventory over each representative period w
	# Build up inventory can be positive or negative
	@variable(EP, vdH2SOC[y in STOR_LONG_DURATION, w=1:REP_PERIOD])

	### Constraints ###

	# Links last time step with first time step, ensuring position in hour 1 is within eligible change from final hour position
	# Modified initial state of storage for long-duration storage - initialize wth value carried over from last period
	# Alternative to cSoCBalStart constraint which is included when not modeling operations wrapping and long duration storage
	# Note: tw_min = hours_per_subperiod*(w-1)+1; tw_max = hours_per_subperiod*w
	@constraint(EP, cH2SoCBalLongDurationStorageStart[w=1:REP_PERIOD, y in H2_STOR_LONG_DURATION],
				    EP[:vH2S][y,hours_per_subperiod*(w-1)+1] == (1-dfH2Gen[!,:H2Stor_self_discharge_rate_p_hour][y])*(EP[:vH2S][y,hours_per_subperiod*w]-vdH2SOC[y,w])-(1/dfH2Gen[!,:H2Stor_eff_discharge][y]*EP[:vH2Gen][y,hours_per_subperiod*(w-1)+1])+(dfH2Gen[!,:H2Stor_eff_charge][y]*EP[:vH2_CHARGE_STOR][y,hours_per_subperiod*(w-1)+1]))

	# Storage at beginning of period w = storage at beginning of period w-1 + storage built up in period w (after n representative periods)
	## Multiply storage build up term from prior period with corresponding weight
	@constraint(EP, cH2SoCBalLongDurationStorageInterior[y in H2_STOR_LONG_DURATION, r in MODELED_PERIODS_INDEX[1:(end-1)]],
					vH2SOCw[y,r+1] == vH2SOCw[y,r] + vdH2SOC[y,dfPeriodMap[!,:Rep_Period_Index][r]])

	## Last period is linked to first period
	@constraint(EP, cH2SoCBalLongDurationStorageEnd[y in H2_STOR_LONG_DURATION, r in MODELED_PERIODS_INDEX[end]],
					vH2SOCw[y,1] == vH2SOCw[y,r] + vdH2SOC[y,dfPeriodMap[!,:Rep_Period_Index][r]])

	# Storage at beginning of each modeled period cannot exceed installed energy capacity
	@constraint(EP, cH2SoCBalLongDurationStorageUpper[y in H2_STOR_LONG_DURATION, r in MODELED_PERIODS_INDEX],
					vH2SOCw[y,r] <= EP[:eH2GenTotalCap][y])

	# Initial storage level for representative periods must also adhere to sub-period storage inventory balance
	# Initial storage = Final storage - change in storage inventory across representative period
	@constraint(EP, cH2SoCBalLongDurationStorageSub[y in H2_STOR_LONG_DURATION, r in REP_PERIODS_INDEX],
					vH2SOCw[y,r] == EP[:vH2S][y,hours_per_subperiod*dfPeriodMap[!,:Rep_Period_Index][r]] - vdH2SOC[y,dfPeriodMap[!,:Rep_Period_Index][r]])

	return EP
end
