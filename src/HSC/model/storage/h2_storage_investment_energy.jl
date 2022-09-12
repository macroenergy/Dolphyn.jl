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
	h2_storage_investment_energy(EP::Model, inputs::Dict, setup::Dict)

This module defines the decision variables representing energy components of hydrogen storage technologies.

The total capacity of each resource is defined as the sum of the existing capacity plus the newly invested capacity minus any retired capacity.

```math
\begin{aligned}
& \Delta^{total,energy}_{y,z} =(\overline{\Delta^{energy}_{y,z}}+\Omega^{energy}_{y,z}-\Delta^{energy}_{y,z}) \forall y \in \mathcal{O}, z \in \mathcal{Z}
\end{aligned}
```

One cannot retire more capacity than existing capacity.

```math
\begin{aligned}
&\Delta^{energy}_{y,z} \leq \overline{\Delta^{energy}_{y,z}}
		\hspace{4 cm}  \forall y \in \mathcal{O}, z \in \mathcal{Z}
\end{aligned}
```

For resources where $\overline{\Omega_{y,z}^{energy}}$ and $\underline{\Omega_{y,z}^{energy}}$ is defined, then we impose constraints on minimum and maximum power capacity.

```math
\begin{aligned}
& \Delta^{total,energy}_{y,z} \leq \overline{\Omega}^{energy}_{y,z}
	\hspace{4 cm}  \forall y \in \mathcal{O}, z \in \mathcal{Z} \\
& \Delta^{total,energy}_{y,z}  \geq \underline{\Omega}^{energy}_{y,z}
	\hspace{4 cm}  \forall y \in \mathcal{O}, z \in \mathcal{Z}
\end{aligned}
```

In addition, this function adds investment and fixed O\&M related costs related to charge capacity to the objective function:

```math
\begin{aligned}
& 	\sum_{y \in \mathcal{O} } \sum_{z \in \mathcal{Z}}
	\left( (\pi^{INVEST,energy}_{y,z} \times    \Omega^{energy}_{y,z})
	+ (\pi^{FOM,energy}_{y,z} \times  \Delta^{total,energy}_{y,z})\right)
\end{aligned}
```
"""
function h2_storage_investment_energy(EP::Model, inputs::Dict, setup::Dict)

    println("H2 Storage Energy Investment Module")

    dfH2Gen = inputs["dfH2Gen"]

    H2_STOR_ALL = inputs["H2_STOR_ALL"] # Set of all hydrogen storage resources

    NEW_CAP_H2_ENERGY = inputs["NEW_CAP_H2_ENERGY"] # set of storage resource eligible for new energy capacity investment
    RET_CAP_H2_ENERGY = inputs["RET_CAP_H2_ENERGY"] # set of storage resource eligible for energy capacity retirements

    # New installed energy capacity of resource "y"
    @variable(EP, vH2CAPENERGY[y in NEW_CAP_H2_ENERGY] >= 0)

    # Retired energy capacity of resource "y" from existing capacity
    @variable(EP, vH2RETCAPENERGY[y in RET_CAP_H2_ENERGY] >= 0)

    # Total available energy capacity in tonnes
    @expression(
        EP,
        eH2TotalCapEnergy[y in H2_STOR_ALL],
        if (y in intersect(NEW_CAP_H2_ENERGY, RET_CAP_H2_ENERGY))
            dfH2Gen[!, :Existing_Energy_Cap_tonne][y] + EP[:vH2CAPENERGY][y] -
            EP[:vH2RETCAPENERGY][y]
        elseif (y in setdiff(NEW_CAP_H2_ENERGY, RET_CAP_H2_ENERGY))
            dfH2Gen[!, :Existing_Energy_Cap_tonne][y] + EP[:vH2CAPENERGY][y]
        elseif (y in setdiff(RET_CAP_H2_ENERGY, NEW_CAP_H2_ENERGY))
            dfH2Gen[!, :Existing_Energy_Cap_tonne][y] - EP[:vH2RETCAPENERGY][y]
        else
            dfH2Gen[!, :Existing_Energy_Cap_tonne][y]
        end
    )

    ## Objective Function Expressions ##

    # Energy capacity costs
    # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
    # If resource is not eligible for new energy capacity, fixed costs are only O&M costs
    #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCFixH2Energy[y in H2_STOR_ALL],
            if y in NEW_CAP_H2_ENERGY # Resources eligible for new capacity
                1 / ModelScalingFactor^2 * (
                    dfH2Gen[!, :Inv_Cost_Energy_p_tonne_yr][y] * vH2CAPENERGY[y] +
                    dfH2Gen[!, :Fixed_OM_Cost_Energy_p_tonne_yr][y] * eH2TotalCapEnergy[y]
                )
            else
                1 / ModelScalingFactor^2 *
                (dfH2Gen[!, :Fixed_OM_Cost_Energy_p_tonne_yr][y] * eH2TotalCapEnergy[y])
            end
        )
    else
        @expression(
            EP,
            eCFixH2Energy[y in H2_STOR_ALL],
            if y in NEW_CAP_H2_ENERGY # Resources eligible for new capacity
                dfH2Gen[!, :Inv_Cost_Energy_p_tonne_yr][y] * vH2CAPENERGY[y] +
                dfH2Gen[!, :Fixed_OM_Cost_Energy_p_tonne_yr][y] * eH2TotalCapEnergy[y]
            else
                dfH2Gen[!, :Fixed_OM_Cost_Energy_p_tonne_yr][y] * eH2TotalCapEnergy[y]
            end
        )
    end

    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixH2Energy, sum(EP[:eCFixH2Energy][y] for y in H2_STOR_ALL))

    # Add term to objective function expression
    EP[:eObj] += eTotalCFixH2Energy

    ### Constratints ###
    # Cannot retire more energy capacity than existing energy capacity
    @constraint(
        EP,
        cMaxRetH2Energy[y in RET_CAP_H2_ENERGY],
        vH2RETCAPENERGY[y] <= dfH2Gen[!, :Existing_Energy_Cap_tonne][y]
    )

    ## Constraints on new built energy capacity
    # Constraint on maximum energy capacity (if applicable) [set input to -1 if no constraint on maximum energy capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is >= Max_Cap_MWh and lead to infeasabilty
    @constraint(
        EP,
        cMaxCapH2Energy[y in intersect(
            dfH2Gen[dfH2Gen.Max_Energy_Cap_tonne.>0, :R_ID],
            H2_STOR_ALL,
        )],
        eH2TotalCapEnergy[y] <= dfH2Gen[!, :Max_Energy_Cap_tonne][y]
    )

    # Constraint on minimum energy capacity (if applicable) [set input to -1 if no constraint on minimum energy apacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is <= Min_Cap_MWh and lead to infeasabilty
    @constraint(
        EP,
        cMinCapH2Energy[y in intersect(
            dfH2Gen[dfH2Gen.Min_Energy_Cap_tonne.>0, :R_ID],
            H2_STOR_ALL,
        )],
        eH2TotalCapEnergy[y] >= dfH2Gen[!, :Min_Energy_Cap_tonne][y]
    )

    return EP
end
