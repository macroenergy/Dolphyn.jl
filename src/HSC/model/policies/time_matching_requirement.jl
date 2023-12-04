"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2023,  Massachusetts Institute of Technology
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
    time_matching_requirement(EP::Model, inputs::Dict, setup::Dict)


This function establishes constraints that require electricity consumption from certain hydrogen resource groups to be matched by electricity generated using a specific set of electricity resources over a pre-specified time period.
Such a time-matching requirement (TMR) mimics the contracting of clean energy resources for hydrogen production, which being contemplated to qualify for tax credits for hydrogen production. 
TMR contraints can be established on either an hourly-matching basis, or an annual-matching basis. 

To implement these constraints, the user needs to specify TMR groups in both the hydrogen and electiricty generation resource files. 
This is done by adding a column H2_TMR followed by the group number (e.g. H2_TMR_1) to the HSC_generation.csv file and the generation.csv file. 
Resources that belong to the group should be marked with a "1" in the coresponding entry in the column of the group. 


We define a set of TMR policy constraints $p \in \mathcal{P}^{TMR}$. 
For each constraint we define a subset of hydrogen production resources $g \in \mathcal{G}^{H2, TMR}_{p}$, power generation resources $g \in \mathcal{G}^{E, TMR}_{p}$, and power storage resources $s \in \mathcal{S}^{E, TMR}_{p}$. 
These set of resources are resources allowed to participate in the fulfilment for TMR requirment constraint, $p$. 
For each constraint $p \in \mathcal{P}^{TMR}$, we define a subset of zones $z \in \mathcal{Z}^{H,ESR}_{p}$, corresponding to the eligible H2 production resources and a subset of zones  $z \in \mathcal{Z}^{E,ESR}_{p}$ corresponding to the set of eligible electricity sector resources.

The expression $TMR Excess Energy_{p, t}$  calculates the differences between electricity generation from resources in $set \mathcal{G}^{E, TMR}_{p}$ + net electricity storage discharge (discharge - charge)  for resources in set $\mathcal{S}^{E, TMR}_{p}$ and the electricity consumption by hydrogen production resources in $set \mathcal{G}^{H2, TMR}_{p}$ (given by variable $x_{g,z,t}^{\textrm{E,H-Gen}}$).
```math
\begin{equation*}
    {TMR Excess Energy_{p, t}} =
    \sum_{z in \in \mathcal{Z}^{E,ESR}_{p}} \sum_{g \in \mathcal{G}^{H2, TMR}_{p}}  x_{g,z,t}^{\textrm{E,GEN}} + 
	\sum_{z in \in \mathcal{Z}^{E,ESR}_{p}} \sum_{s \in \mathcal{S}^{E, TMR}_{p}}  x_{s,z,t}^{\textrm{E,DIS}}- 
	\sum_{z in \in \mathcal{Z}^{E,ESR}_{p}} \sum_{s \in \mathcal{S}^{E, TMR}_{p}}  x_{s,z,t}^{\textrm{E,CHA}}- 
	\sum_{z in \in \mathcal{Z}^{H,ESR}_{p}} \sum_{g \in \mathcal{G}^{H, TMR}_{p}} x_{g,z,t}^{\textrm{E,H-Gen}} 
\end{equation*}
```

$\forall {p \in \mathcal{P}^{TMR}}$

When the parameter ```TimeMatchingRequirement``` is set to 1, we implement the following constraint to simulate hourly time-matching where electricity resources are allowed to produce in excess of demand for H$_2$ production that can be sold to the grid (i.e. excess sales allowed):
```math
\begin{equation*}
    {TMR Excess Energy_{p, t}} >= 0  \; \forall \; p^{TMR} \in P,  t \in T
\end{equation*}
```

When the parameter ```TimeMatchingRequirement``` is set to 2, we implement the following constraint to simulate hourly time-matching with no excess sales:
```math
\begin{equation*}
    {TMR Excess Energy_{p, t}} = 0 \; \forall \; p^{TMR} \in P,  t \in T
\end{equation*}
```

When the parameter ```TimeMatchingRequirement``` is set to 3, we implement the following constraint to simulate annual time-matching:
```math
\begin{equation*}
    \sum_{t \in T} {TMR Excess Energy_{p, t} \times \Omega_t} = 0 \; \forall \; p^{TMR} \in P
\end{equation*}
```
Notice that in the annual time-matching case, the electricity sector resources can produce in excess of electricity demand for hydrogen production at each time step, so long as the annual sum of production and generation match. The $\Omega_t$ corresponds to time-weight of each time step which will be different from 1 when considering representative periods of system operation rahter than full year operation at an hourly resolution.

In addition, when ```EnergyShareRequirement``` is set to 1, excess sales from a given TMR group is added to the corresponding ESR constraint the TMR group maps to. 

"""
function time_matching_requirement(EP::Model, inputs::Dict, setup::Dict)

	print_and_log("Electricity Time Matching Requirement for H2 Production Module")

	dfGen = inputs["dfGen"] # Power sector inputs

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	#H = inputs["H2_RES_ALL"] #Number of Hydrogen gen units
	H2_GEN = inputs["H2_GEN"]
	dfH2Gen = inputs["dfH2Gen"]

	# Identify number of time matching requirements
	nH2_TMR = count(s -> startswith(String(s), "H2_TMR_"), names(dfGen))
	
	# Identify number of ESRR requirements
	nESR = count(s -> startswith(String(s), "ESR_"), names(dfGen))


	# Export expression regarding excess electricity generation from contracted VRE resources over the entire year that can be used for meeting RPS requirements

	# Hourly excess electricity supply from contracted electricity resources for H2 production
	@expression(EP,eExcessElectricitySupplyTMR[TMR=1:nH2_TMR, t=1:T],
	sum(dfGen[!,Symbol("H2_TMR_$TMR")][y]*EP[:vP][y,t] for y=dfGen[findall(x->x>0,dfGen[!,Symbol("H2_TMR_$TMR")]),:R_ID]) 
	- sum(dfGen[!,Symbol("H2_TMR_$TMR")][s]*EP[:vCHARGE][s,t] for s in intersect(dfGen[findall(x->x>0,dfGen[!,Symbol("H2_TMR_$TMR")]),:R_ID], inputs["STOR_ALL"]))
	-sum(EP[:vH2Gen][k,t]*dfH2Gen[!,:etaP2G_MWh_p_MWh][k] for k in intersect(H2_GEN, dfH2Gen[findall(x->x>0,dfH2Gen[!,Symbol("H2_TMR_$TMR")]),:R_ID]))
	)

	# Annual excess electricity supply from contracted electricity resources for H2 production
	@expression(EP, eExcessAnnualElectricitySupplyTMR[TMR=1:nH2_TMR], sum(eExcessElectricitySupplyTMR[TMR,t]*inputs["omega"][t] for t = 1:T))

	## Energy Share Requirements (minimum energy share from qualifying renewable resources) constraint
	if setup["TimeMatchingRequirement"] == 1 # hourly with excess sales allowed
		@constraint(EP, cH2TMR[TMR=1:nH2_TMR, t=1:T], eExcessElectricitySupplyTMR[TMR, t]>=0 )		
	elseif setup["TimeMatchingRequirement"] == 2 # hourly without excess sales 
		@constraint(EP, cH2TMR[TMR=1:nH2_TMR, t=1:T], eExcessElectricitySupplyTMR[TMR, t] ==0 )			
	elseif setup["TimeMatchingRequirement"] == 3 # annual matching 
		# Annual excess electricity supply from contracted electricity resources for H2 production
		@constraint(EP, cH2TMR_Annual[TMR=1:nH2_TMR], eExcessAnnualElectricitySupplyTMR[TMR] ==0 )	
	end


	#Add excess TMR Sales to ESR
	if (setup["EnergyShareRequirement"] == 1) && (setup["TMRSalestoESR"] == 1)
	
		#NOTE: All All resources belonging to the same TMR must all be be a part of the same ESRs. 
		#In this section we check whether this input requirement is satisfied

		# Function to check if all values in a column are the same
		function check_column_consistency(df, column_name)
			column_values = df[!, column_name]
			return all(x -> x == column_values[1], column_values)
		end

		for curr_tmr in 1:nH2_TMR
			# Filter the DataFrame based on a column's value being equal to 1
			dfGen_curr_tmr = filter(row -> row[Symbol("H2_TMR_$curr_tmr")] == 1, dfGen)

				for curr_esr in 1:nESR
					tmr_consistent = check_column_consistency(dfGen_curr_tmr, Symbol("ESR_$curr_esr"))
					if !tmr_consistent 
						error("All resources belonging to the same TMR must be part of the same ESR requirement")
					end
				end				

		end


		#Creating dataframe mappin ESRs to TMRs
		esr_tmr_df = DataFrame(ESR = Int[], TMR = Int[])
		for curr_esr in 1:nESR
			dfGen_curr_esr = filter(row -> row[Symbol("ESR_$curr_esr")] == 1, dfGen)
			for curr_tmr in 1:nH2_TMR
				if sum(dfGen_curr_esr[!, Symbol("H2_TMR_$curr_tmr")]) >= 1
					push!(esr_tmr_df, (ESR = curr_esr, TMR = curr_tmr))	
				end
			end
		end 

		if nrow(esr_tmr_df) != 0
			#Summing excess energy across all TMR resources in the same ESR group, creating an excess annual electricity supply variable from TMR resources for each ESR. 
			@expression(EP, eExcessAnnualElectricitySupplyESR[ESR=1:nESR], sum(eExcessElectricitySupplyTMR[TMR] for TMR in esr_tmr_df[(esr_tmr_df[!,:ESR].==ESR), :TMR]))
			EP[:eESR] += eExcessAnnualElectricitySupplyESR
		end

	end 

	return EP
end
