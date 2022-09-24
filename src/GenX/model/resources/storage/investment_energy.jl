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
	investment_energy(EP::Model, inputs::Dict)

This function defines the expressions and constraints keeping track of total available storage energy capacity as well as constraints on capacity retirements. 
The function also adds investment and fixed OM costs related to energy capacity to the objective function.

The total energy capacity of storage resource is defined as the sum of the existing capacity plus the newly invested capacity minus any retired capacity.

```math
\begin{equation*}
	y_{s,z}^{\textrm{E,ENE,total}} = y_{s,z}^{\textrm{E,ENE,existing}} + y_{s,z}^{\textrm{E,ENE,new}} - y_{s,z}^{\textrm{E,ENE,retired}} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}
\end{equation*}
```

**Cost expressions**

In addition, this module adds investment and fixed OM costs related to energy capacity to the objective function:
```math
\begin{equation*}
	\textrm{C}^{\textrm{E,ENE,c}} = \sum_{s \in \mathcal{S}} \sum_{z \in \mathcal{Z}} \left(\textrm{c}_{s,z}^{\textrm{E,ENE,INV}}} \times y_{s,z}^{\textrm{E,ENE,new}} + \textrm{c}_{s,z}^{\textrm{E,ENE,FOM}} \times y_{s,z}^{\textrm{E,ENE,total}}\right)
\end{equation*}
```

**Constraints on storage energy capacity**

One cannot retire more capacity than existing capacity.
```math
\begin{equation*}
	0 \leq y_{s,z}^{\textrm{E,ENE,retired}} \leq y_{s,z}^{\textrm{E,ENE,existing}} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}
\end{equation*}
```

For storage resources where upper bound $\overline{R_{s,z}^{\textrm{E,ENE}}}$ and lower bound $\underline{R_{s,z}^{\textrm{E,ENE}}}$ is defined, then we impose constraints on minimum and maximum storage energy capacity.
```math
\begin{equation*}
	\underline{R}_{s,z}^{\textrm{E,ENE}} \leq y_{s,z}^{\textrm{E,ENE}} \leq \overline{R}_{s,z}^{\textrm{E,ENE}} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}
\end{equation*}
```
"""
function investment_energy(EP::Model, inputs::Dict)

	println("Storage Investment Module")

	dfGen = inputs["dfGen"]

	G = inputs["G"] # Number of resources (generators, storage, DR, and DERs)

	STOR_ALL = inputs["STOR_ALL"] # Set of all storage resources
	NEW_CAP_ENERGY = inputs["NEW_CAP_ENERGY"] # Set of all storage resources eligible for new energy capacity
	RET_CAP_ENERGY = inputs["RET_CAP_ENERGY"] # Set of all storage resources eligible for energy capacity retirements

	### Variables ###

	## Energy storage reservoir capacity (MWh capacity) built/retired for storage with variable power to energy ratio (STOR=1 or STOR=2)

	# New installed energy capacity of resource "y"
	@variable(EP, vCAPENERGY[y in NEW_CAP_ENERGY] >= 0)

	# Retired energy capacity of resource "y" from existing capacity
	@variable(EP, vRETCAPENERGY[y in RET_CAP_ENERGY] >= 0)

	### Expressions ###

	@expression(EP, eTotalCapEnergy[y in STOR_ALL],
		if (y in intersect(NEW_CAP_ENERGY, RET_CAP_ENERGY))
			dfGen[!,:Existing_Cap_MWh][y] + EP[:vCAPENERGY][y] - EP[:vRETCAPENERGY][y]
		elseif (y in setdiff(NEW_CAP_ENERGY, RET_CAP_ENERGY))
			dfGen[!,:Existing_Cap_MWh][y] + EP[:vCAPENERGY][y]
		elseif (y in setdiff(RET_CAP_ENERGY, NEW_CAP_ENERGY))
			dfGen[!,:Existing_Cap_MWh][y] - EP[:vRETCAPENERGY][y]
		else
			dfGen[!,:Existing_Cap_MWh][y] + EP[:vZERO]
		end
	)

	## Objective Function Expressions ##

	# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new energy capacity, fixed costs are only O&M costs
	@expression(EP, eCFixEnergy[y in STOR_ALL],
		if y in NEW_CAP_ENERGY # Resources eligible for new capacity
			dfGen[!,:Inv_Cost_per_MWhyr][y]*vCAPENERGY[y] + dfGen[!,:Fixed_OM_Cost_per_MWhyr][y]*eTotalCapEnergy[y]
		else
			dfGen[!,:Fixed_OM_Cost_per_MWhyr][y]*eTotalCapEnergy[y]
		end
	)

	# Sum individual resource contributions to fixed costs to get total fixed costs
	@expression(EP, eTotalCFixEnergy, sum(EP[:eCFixEnergy][y] for y in STOR_ALL))

	# Add term to objective function expression
	EP[:eObj] += eTotalCFixEnergy

	### Constratints ###

	## Constraints on retirements and capacity additions
	# Cannot retire more energy capacity than existing energy capacity
	@constraint(EP, cMaxRetEnergy[y in RET_CAP_ENERGY], vRETCAPENERGY[y] <= dfGen[!,:Existing_Cap_MWh][y])

	## Constraints on new built energy capacity
	# Constraint on maximum energy capacity (if applicable) [set input to -1 if no constraint on maximum energy capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is >= Max_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMaxCapEnergy[y in intersect(dfGen[dfGen.Max_Cap_MWh.>0,:R_ID], STOR_ALL)], eTotalCapEnergy[y] <= dfGen[!,:Max_Cap_MWh][y])

	# Constraint on minimum energy capacity (if applicable) [set input to -1 if no constraint on minimum energy apacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is <= Min_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMinCapEnergy[y in intersect(dfGen[dfGen.Min_Cap_MWh.>0,:R_ID], STOR_ALL)], eTotalCapEnergy[y] >= dfGen[!,:Min_Cap_MWh][y])

	return EP
end
