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
	ucommit(EP::Model, inputs::Dict, UCommit::Int)

This function creates decision variables and cost expressions associated with thermal plant unit commitment or start-up and shut-down decisions (cycling on/off)

**Unit commitment decision variables**

Commitment state variable $n_{k,z,t}^{\textrm{E,THE}}$ of generator cluster $k$ in zone $z$ at time $t$ $\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$.

Startup decision variable $n_{k,z,t}^{\textrm{E,UP}}$ of generator cluster $k$ in zone $z$ at time $t$ $\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$.

Shutdown decision variable $n_{k,z,t}^{\textrm{E,DN}}$ of generator cluster $k$ in zone $z$ at time $t$ $\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$.

The variable defined in this file named after ```vCOMMIT``` covers $n_{k,z,t}^{\textrm{E,THE}}$.

The variable defined in this file named after ```vSTART``` covers $n_{k,z,t}^{\textrm{E,UP}}$.

The variable defined in this file named after ```vSHUT``` covers $n_{k,z,t}^{\textrm{E,DN}}$.

**Cost expressions**

The total cost of start-ups across all generators subject to unit commitment ($k \in \mathcal{UC}, \mathcal{UC} \subseteq \mathcal{G}$) and all time periods $t$ is expressed as:

```math
\begin{equation*}
	\textrm{C}^{\textrm{E,start}} = \sum_{k \in \mathcal{UC}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{k}^{\textrm{E,start}} \times n_{k,z,t}^{\textrm{E,UP}}
\end{equation*}
```

If set ```UCommit``` to 1, the unit commitment variables are set to integer types. IF ```UCommit``` =2, these variables are treated as continuous.
"""
function ucommit(EP::Model, inputs::Dict, UCommit::Int)

	print_and_log("Unit Commitment Module")

	dfGen = inputs["dfGen"]

	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	COMMIT = inputs["COMMIT"] # For not, thermal resources are the only ones eligible for Unit Committment

	### Variables ###

	## Decision variables for unit commitment
	# commitment state variable
	@variable(EP, vCOMMIT[y in COMMIT, t=1:T] >= 0)
	# startup event variable
	@variable(EP, vSTART[y in COMMIT, t=1:T] >= 0)
	# shutdown event variable
	@variable(EP, vSHUT[y in COMMIT, t=1:T] >= 0)

	### Expressions ###

	## Objective Function Expressions ##

	# Startup costs of "generation" for resource "y" during hour "t"
	@expression(EP, eCStart[y in COMMIT, t=1:T],(inputs["omega"][t]*inputs["C_Start"][y]*vSTART[y,t]))

	# Julia is fastest when summing over one row one column at a time
	@expression(EP, eTotalCStartT[t=1:T], sum(eCStart[y,t] for y in COMMIT))
	@expression(EP, eTotalCStart, sum(eTotalCStartT[t] for t=1:T))

	EP[:eObj] += eTotalCStart

	### Constratints ###
	## Declaration of integer/binary variables
	if UCommit == 1 # Integer UC constraints
		for y in COMMIT
			set_integer.(vCOMMIT[y,:])
			set_integer.(vSTART[y,:])
			set_integer.(vSHUT[y,:])
			if y in inputs["RET_CAP"]
				set_integer(EP[:vRETCAP][y])
			end
			if y in inputs["NEW_CAP"]
				set_integer(EP[:vCAP][y])
			end
		end
	end #END unit commitment configuration
	return EP
end
