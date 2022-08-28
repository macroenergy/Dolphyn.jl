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
    h2_storage_asymmetric(EP::Model, inputs::Dict)

Sets up variables and constraints specific to hydrogen storage resources with symmetric charge and discharge capacities.

For storage technologies with symmetric charge and discharge capacity (all $s \in \mathcal{S}^{sym}$), charge rate, $x_{s,z,t}^{H,CHA}$, is constrained by the total installed power capacity $y_{s,z}^{H,STO,POW}$. 
Since storage resources generally represent a `cluster' of multiple similar storage devices of the same type/cost in the same zone, DOLPHYN permits storage resources to simultaneously charge and discharge (as some units could be charging while others discharge), 
with the simultaenous sum of charge $x_{s,z,t}^{H,CHA}$, and discharge $x_{s,z,t}^{E,DIS}$, also limited by the total installed power capacity, $y_{s,z}^{H,STO,POW}$. 
These two constraints are as follows:

```math
\begin{equation}
	x_{s,z,t}^{H,CHA} \leq y_{s,z}^{H,STO,POW} \quad \forall s \in \mathcal{S}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation}
"""
function h2_storage_symmetric(EP::Model, inputs::Dict)
    # Set up additional variables, constraints, and expressions associated with hydrogen storage resources with symmetric charge & discharge capacity
    # STOR = 1 corresponds to storage with distinct power and energy capacity decisions but symmetric charge/discharge power ratings

    println("H2 Storage Resources with Symmetric Charge/Discharge Capacity Module")

    T = inputs["T"]

    H2_STOR_SYMMETRIC = inputs["H2_STOR_SYMMETRIC"]

    ### Constraints ###

    # Hydrogen storage discharge and charge power (and reserve contribution) related constraints for symmetric storage resources:
    @constraints(
        EP,
        begin
            # Maximum charging rate must be less than symmetric power rating
            [y in H2_STOR_SYMMETRIC, t in 1:T], EP[:vH2_CHARGE_STOR][y,t] <= EP[:eH2GenTotalCap][y] * inputs["pH2_Max"][y,t]
        end
    )

    return EP
end