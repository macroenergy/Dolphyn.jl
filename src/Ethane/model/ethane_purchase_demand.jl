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

    conventional_ng_demand(EP::Model, inputs::Dict, setup::Dict)

This module defines the conventional natural gas purchase decision variables $x_{z,t}^{\textrm{NG,Conv}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$ representing conventional natural gas purchased in zone $z$ at time period $t$.

The variables defined in this file named after ```vConv_NG_Demand``` cover variable $x_{z,t}^{NG,Conv}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of conventional natural gas purchase over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{NG,Conv,o}} = \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{z}^{\textrm{NG,Conv,VOM}} \times x_{z,t}^{\textrm{NG,Conv}}
\end{equation*}
```
"""
function ethane_purchase_demand(EP::Model, inputs::Dict, setup::Dict)

    println(" -- Ethane purchase Module")

	#Define sets
    Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)
    Conventional_ethane_co2_per_tonne = inputs["ethane_co2_per_tonne"]
    

    #If do conventional as regional hourly variable [t]
    @variable(EP, vConv_Ethane_Demand[t = 1:T, z = 1:Z] >= 0 )

    #Ethylene Balance
    EP[:eEthaneBalance] += vConv_Ethane_Demand
    
 
    @expression(EP, eTotalConv_Ethane_VarOut_Z[z = 1:Z], sum((inputs["omega"][t] * inputs["Ethane_Prices"][t,z] * vConv_Ethane_Demand[t,z]) for t in 1:T))

    @expression(EP, eTotalConv_Ethane_VarOut, sum(EP[:eTotalConv_Ethane_VarOut_Z][z] for z in 1:Z))

    @expression(EP,eConv_ethane_CO2_Emissions[z=1:Z,t=1:T], Conventional_ethane_co2_per_tonne * EP[:vConv_Ethane_Demand][t,z])

    #Add to objective function
    EP[:eObj] += eTotalConv_Ethane_VarOut

	    
    
    return EP

end
