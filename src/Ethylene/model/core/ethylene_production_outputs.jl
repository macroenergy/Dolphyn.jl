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
	syn_ng_outputs(EP::Model, inputs::Dict, setup::Dict)
	
Sets up variables common to all synthetic gas resources.

This module defines the synthetic gas resource decision variable $x_{f,t}^{\textrm{C,Syn}} \forall f \in \mathcal{F}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing CO2 input into the synthetic gas resource $f$ at time period $t$.

$x_{f,b,t}^{\textrm{By,Syn}} \forall f \in \mathcal{F}, \forall b \in \mathcal{B}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing synthetic fuels by products $b$ (if any) by the synthetic fuels resource $f$ at time period $t$.

The variables defined in this file named after ```vSyn_NG_CO2in``` covers all variables $x_{f,t}^{\textrm{C,Syn}}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable OM plus fuel cost) from all synthetic fuels resources over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{NG,Syn,o}} = \sum_{f \in \mathcal{F}} \sum_{t \in \mathcal{T}} \omega_t \times \left(\textrm{c}_{f}^{\textrm{Syn,VOM}} + \textrm{c}_{f}^{\textrm{Syn,NG}}\right) \times x_{f,t}^{\textrm{C,Syn}}
\end{equation*}
```

"""
function ethylene_production_outputs(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Ethylene Production Variable Cost Module")

	#=

    dfEthylene = inputs["dfEthylene"]


	#Define sets
	Ethylene_RES_ALL = inputs["Ethylene_RES_ALL"] #Number of ethylene units
	T = inputs["T"]     # Number of time steps (hours)

    ## Variables ##
    # Ethane Required by Ethylene Production Resource in MTonnes
	#@variable(EP, vEthylene_ethanein[k in 1:Ethylene_RES_ALL, t = 1:T] >= 0 )

################ new added #############
	# Ethylene Output by Production Resource in MTonnes
	# @variable(EP, vEthylene_out[k in 1:Ethylene_RES_ALL, t = 1:T] >= 0)
	# @variable(EP, vEthylene_Prod[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )

	# Link ethane input to ethylene output based on process yield
	#@constraint(EP, [k in 1:Ethylene_RES_ALL, t = 1:T], 
	#vEthylene_ethanein[k, t] == dfEthylene[!,:tonne_ethane_p_tonne_ethylene][k] * EP[:eEthylene_Prod_Plant][k,t])
	
	### Expressions ###
	## Objective Function Expressions ##

	#Variable Cost of Ethylene Production
	###################### old code  #######################################
	#@expression(EP, eCEthyleneProdVar_out[k = 1:Ethylene_RES_ALL,t = 1:T], 
	#(inputs["omega"][t] * dfEthylene[!,:Var_OM_cost_p_tonne_ethane_p_hr_yr][k] * vEthylene_ethanein[k,t]))
	#######################  ----------------  ##########################

	############# new code ####################
	@expression(EP, eCEthyleneProdVar_out[k = 1:Ethylene_RES_ALL, t = 1:T], 
	inputs["omega"][t] * dfEthylene[!,:Var_OM_cost_p_tonne_ethylene_p_hr_yr][k] * EP[:vEthylene_Prod][k,t])
	##########################

	
    #Sum variable cost of Ethylene production
	@expression(EP, eTotalCEthyleneProdVarOutT[t=1:T], sum(eCEthyleneProdVar_out[k,t] for k in 1:Ethylene_RES_ALL))
	@expression(EP, eTotalCEthyleneProdVarOut, sum(eTotalCEthyleneProdVarOutT[t] for t in 1:T))

	#Add total variable discharging cost contribution to the objective function
	EP[:eObj] += eTotalCEthyleneProdVarOut

	=#
	########################################################## version 2 ################################################
	## Step 1: load the saved information
	# Greenfield projects:
	dfEthylene = inputs["dfEthylene"]
	Ethylene_RES_ALL = inputs["Ethylene_RES_ALL"]
	# Existing plants:
	dfEthylene_plants = inputs["dfEthylene_plants"]
	Ethylene_Plants_ALL = inputs["Ethylene_Plants_ALL"]
	# Other quantities:
	T = inputs["T"]     # Number of time steps (hours)

	## Step 2: Cost estimation
	# Greenfield projects: Variable operating cost (Var OPEX)
	@expression(EP, eCEthyleneProdVar_out_GF[k = 1:Ethylene_RES_ALL, t = 1:T], inputs["omega"][t] * dfEthylene[!,:Var_OM_cost_p_tonne_ethylene_p_hr_yr][k] * EP[:vEthylene_Prod_GF][k,t])
	# Greenfield projects: Sum variable cost of Ethylene production
	@expression(EP, eTotalCEthyleneProdVarOutT_GF[t=1:T], sum(eCEthyleneProdVar_out_GF[k,t] for k in 1:Ethylene_RES_ALL))
	@expression(EP, eTotalCEthyleneProdVarOut_GF, sum(eTotalCEthyleneProdVarOutT_GF[t] for t in 1:T))
	EP[:eObj] += eTotalCEthyleneProdVarOut_GF

	if setup["ModelEthylenePlants"] == 1
		# Existing Plants: Variable operating cost (Var OPEX)
		@expression(EP, eCEthyleneProdVar_out_EP[k = 1:Ethylene_Plants_ALL, t = 1:T], inputs["omega"][t] * dfEthylene_plants[!,:Plant_Var_OM_cost_p_tonne_ethylene_p_hr_yr][k] * EP[:vEthylene_Prod_EP][k,t])
		# Existing Plants: Sum variable cost of Ethylene production
		@expression(EP, eTotalCEthyleneProdVarOutT_EP[t=1:T], sum(eCEthyleneProdVar_out_EP[k,t] for k in 1:Ethylene_Plants_ALL))
		@expression(EP, eTotalCEthyleneProdVarOut_EP, sum(eTotalCEthyleneProdVarOutT_EP[t] for t in 1:T))
		EP[:eObj] += eTotalCEthyleneProdVarOut_EP

	end

	if setup["ModelEthyleneRetrofitting"] == 1

		dfEthylene_retrofit = inputs["dfEthylene_retrofit"]
        Ethylene_retrofit_ALL = inputs["Ethylene_retrofit_ALL"]
		# Existing Plants: Variable operating cost (Var OPEX)
		@expression(EP, eCEthyleneProdVar_out_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T], inputs["omega"][t] * dfEthylene_retrofit[!,:Retrofit_Var_OM_cost_p_tonne_ethylene_p_hr_yr][k] * EP[:vEthylene_Prod_Retrofit][k,t])
		# Existing Plants: Sum variable cost of Ethylene production
		@expression(EP, eTotalCEthyleneProdVarOutT_Retrofit[t=1:T], sum(eCEthyleneProdVar_out_Retrofit[k,t] for k in 1:Ethylene_retrofit_ALL))
		@expression(EP, eTotalCEthyleneProdVarOut_Retrofit, sum(eTotalCEthyleneProdVarOutT_Retrofit[t] for t in 1:T))
		EP[:eObj] += eTotalCEthyleneProdVarOut_Retrofit

	end






	return EP

end
