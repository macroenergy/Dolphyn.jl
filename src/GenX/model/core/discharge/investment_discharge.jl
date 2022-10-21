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
	investment_discharge(EP::Model, inputs::Dict)

Sets up constraints common to all generation resources.

This function defines the expressions and constraints keeping track of: 
- total available thermal generation capacity $y_{k, z}^{\textrm{E,THE}}$ as well as constraints on capacity retirements.
- total available renewable generation capacity $y_{r, z}^{\textrm{E,VRE}}$ as well as constraints on capacity retirements.
- total available storage discharge capacity $y_{s, z}^{\textrm{\textrm{E,STO},DIS}}$ as well as constraints on capacity retirements.

The expression defined in this file named after ```eTotalCap``` covers all variables $y_{k, z}^{\textrm{E,THE}}, y_{r, z}^{\textrm{E,VRE}}, 
y_{s, z}^{\textrm{\textrm{E,STO},DIS}}$.

```math
\begin{equation*}
	y_{g, z}^{\textrm{E,GEN}} = 
	\begin{cases}
		y_{k, z}^{\textrm{E,THE}} \quad if \quad k \in \mathcal{K} \\
		y_{r, z}^{\textrm{E,VRE}} \quad if \quad r \in \mathcal{R} \\
		y_{s, z}^{\textrm{\textrm{E,STO},DIS}} \quad if \quad s \in \mathcal{S}
	\end{cases}
	\quad \forall g \in \mathcal{G}, z \in \mathcal{Z}
\end{equation*}
```

The total capacity of each resource (thermal, renewable, storage, DR, flexible demand resources and hydro) is defined as the sum of the existing capacity plus the newly invested capacity minus any retired capacity. 
Note for energy storage resources in power sector, additional energy and charge power capacity decisions and constraints are defined in the storage module.

```math
\begin{equation*}
	\begin{split}
	y_{g, z}^{\textrm{E,GEN}} &= y_{g, z}^{\textrm{E,GEN,total}} \\ 
	& = y_{g, z}^{\textrm{E,GEN,existing}}+y_{g, z}^{\textrm{E,GEN,new}}-y_{g}^{\textrm{E,GEN,retired}}
	\end{split}
	\quad \forall g \in \mathcal{G}, z \in \mathcal{Z}
\end{equation*}
```

**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of generation (fixed OM plus investment costs) from all generation resources $g \in \mathcal{G}$ (thermal, renewable, storage, DR, flexible demand resources and hydro):

```math
\begin{equation*}
	\textrm{C}^{\textrm{E,GEN,c}} = \sum_{z \in \mathcal{Z}}\left(\sum_{g \in \mathcal{G}} y_{g, z}^{\textrm{E,GEN,new}}\times \textrm{c}_{g, z}^{\textrm{E,INV}} + \sum_{g \in \mathcal{G}} y_{g, z}^{\textrm{E,GEN,total}}\times \textrm{c}_{g, z}^{\textrm{E,FOM}}\right)
\end{equation*}
```

**Constraints on generation discharge capacity**

One cannot retire more capacity than existing capacity.
```math
\begin{equation*}
	0 \leq y_{g, z}^{\textrm{E,GEN,retired}} \leq y_{g, z}^{\textrm{E,GEN,existing}} \quad \forall g \in \mathcal{G}, z \in \mathcal{Z}
\end{equation*}
```

For resources where upper bound $\overline{y}_{g, z}^{\textrm{E,GEN}}$ and lower bound $\underline{y}_{g, z}^{\textrm{E,GEN}}$ of capacity is defined, then we impose constraints on minimum and maximum power capacity.

```math
\begin{equation*}
	\underline{y}_{g, z}^{\textrm{E,GEN}} \leq y_{g, z}^{\textrm{E,GEN}} \leq \overline{y}_{g, z}^{\textrm{E,GEN}} \quad \forall g \in \mathcal{G}, z \in \mathcal{Z}
\end{equation*}
```
"""
function investment_discharge(EP::Model, inputs::Dict)

	print_and_log("Investment Discharge Module")

	dfGen = inputs["dfGen"]

	G = inputs["G"] # Number of resources (generators, storage, DR, and DERs)

	NEW_CAP = inputs["NEW_CAP"] # Set of all resources eligible for new capacity
	RET_CAP = inputs["RET_CAP"] # Set of all resources eligible for capacity retirements
	COMMIT = inputs["COMMIT"] # Set of all resources eligible for unit commitment

	### Variables ###

	# Retired capacity of resource "y" from existing capacity
	@variable(EP, vRETCAP[y in RET_CAP] >= 0);

    # New installed capacity of resource "y"
	@variable(EP, vCAP[y in NEW_CAP] >= 0);

	### Expressions ###

	# Cap_Size is set to 1 for all variables when unit UCommit == 0
	# When UCommit > 0, Cap_Size is set to 1 for all variables except those where THERM == 1
	@expression(EP, eTotalCap[y in 1:G],
		if y in intersect(NEW_CAP, RET_CAP) # Resources eligible for new capacity and retirements
			if y in COMMIT
				dfGen[!,:Existing_Cap_MW][y] + dfGen[!,:Cap_Size][y]*(EP[:vCAP][y] - EP[:vRETCAP][y])
			else
				dfGen[!,:Existing_Cap_MW][y] + EP[:vCAP][y] - EP[:vRETCAP][y]
			end
		elseif y in setdiff(NEW_CAP, RET_CAP) # Resources eligible for only new capacity
			if y in COMMIT
				dfGen[!,:Existing_Cap_MW][y] + dfGen[!,:Cap_Size][y]*EP[:vCAP][y]
			else
				dfGen[!,:Existing_Cap_MW][y] + EP[:vCAP][y]
			end
		elseif y in setdiff(RET_CAP, NEW_CAP) # Resources eligible for only capacity retirements
			if y in COMMIT
				dfGen[!,:Existing_Cap_MW][y] - dfGen[!,:Cap_Size][y]*EP[:vRETCAP][y]
			else
				dfGen[!,:Existing_Cap_MW][y] - EP[:vRETCAP][y]
			end
		else # Resources not eligible for new capacity or retirements
			dfGen[!,:Existing_Cap_MW][y] + EP[:vZERO]
		end
	)

	## Objective Function Expressions ##

	# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new capacity, fixed costs are only O&M costs
	@expression(EP, eCFix[y in 1:G],
		if y in NEW_CAP # Resources eligible for new capacity
			if y in COMMIT
				dfGen[!,:Inv_Cost_per_MWyr][y]*dfGen[!,:Cap_Size][y]*vCAP[y] + dfGen[!,:Fixed_OM_Cost_per_MWyr][y]*eTotalCap[y]
			else
				dfGen[!,:Inv_Cost_per_MWyr][y]*vCAP[y] + dfGen[!,:Fixed_OM_Cost_per_MWyr][y]*eTotalCap[y]
			end
		else
			dfGen[!,:Fixed_OM_Cost_per_MWyr][y]*eTotalCap[y]
		end
	)

	# Sum individual resource contributions to fixed costs to get total fixed costs
	@expression(EP, eTotalCFix, sum(EP[:eCFix][y] for y in 1:G))
	@expression(EP, eCFix_Thermal, sum(EP[:eCFix][y] for y in inputs["THERM_ALL"]))
	@expression(EP, eCFix_VRE, sum(EP[:eCFix][y] for y in inputs["VRE"]))
	@expression(EP, eCFix_Must_Run, sum(EP[:eCFix][y] for y in inputs["MUST_RUN"]))
	@expression(EP, eCFix_Hydro, sum(EP[:eCFix][y] for y in inputs["HYDRO_RES"]))
	@expression(EP, eCFix_Stor_Inv, sum(EP[:eCFix][y] for y in inputs["STOR_ALL"]))

	# Add term to objective function expression
	EP[:eObj] += eTotalCFix

	### Constratints ###

	## Constraints on retirements and capacity additions
	# Cannot retire more capacity than existing capacity
	@constraint(EP, cMaxRetNoCommit[y in setdiff(RET_CAP,COMMIT)], vRETCAP[y] <= dfGen[!,:Existing_Cap_MW][y])
	@constraint(EP, cMaxRetCommit[y in intersect(RET_CAP,COMMIT)], dfGen[!,:Cap_Size][y]*vRETCAP[y] <= dfGen[!,:Existing_Cap_MW][y])

	## Constraints on new built capacity
	# Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
	@constraint(EP, cMaxCap[y in intersect(dfGen[dfGen.Max_Cap_MW.>0,:R_ID], 1:G)], eTotalCap[y] <= dfGen[!,:Max_Cap_MW][y])

	# Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is <= Min_Cap_MW and lead to infeasabilty
	@constraint(EP, cMinCap[y in intersect(dfGen[dfGen.Min_Cap_MW.>0,:R_ID], 1:G)], eTotalCap[y] >= dfGen[!,:Min_Cap_MW][y])

	return EP
end
