"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
    syn_ng_resources(EP::Model, inputs::Dict, setup::Dict)

This module creates decision variables, expressions, and constraints related to synthetic gas resources.

This module defines the power consumption decision variable $x_{f,t}^{\textrm{E,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, representing power consumed by synthetic gas resource $f$ at time period $t$.

The variable defined in this file named after ```vSyn_NG_Power_in``` cover variable $x_{f,t}^{E,Syn}$.

This module defines the hydrogen consumption decision variable $x_{f,t}^{\textrm{H,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, representing hydrogen consumed by synthetic gas resource $f$ at time period $t$.

The variable defined in this file named after ```vSyn_NG_H2in``` cover variable $x_{f,t}^{H,Syn}$.

This module defines the synthetic gasoline, jetgas, and diesel production decision variables $x_{f,t}^{\textrm{Gasoline,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, $x_{f,t}^{\textrm{Jetgas,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, $x_{f,t}^{\textrm{Diesel,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$ representing  synthetic gasoline, jetgas, and diesel produced by resource $f$ at time period $t$.

The variables defined in this file named after ```vSyn_NG_Prod_Gasoline``` cover variable $x_{f,t}^{Gasoline,Syn}$, ```vSyn_NG_Prod_Jetgas``` cover variable $x_{f,t}^{Jetgas,Syn}$, and ```vSyn_NG_Prod``` cover variable $x_{f,t}^{Diesel,Syn}$.

**Maximum CO2 input to synthetic gas resource**

```math
\begin{equation*}
	x_{f,t}^{\textrm{C,Syn}} \leq  y_{f}^{\textrm{C,Syn}} \quad \forall f \in \mathcal{F}, t \in \mathcal{T}
\end{equation*}
```
"""
function ethylene_production_resources(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Ethylene Production Resources")

	#=

	
	# @expression(EP, eEthyleneBalance[t=1:T, z=1:Z], 0)
	dfEthylene = inputs["dfEthylene"]
    
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	Ethylene_RES_ALL = inputs["Ethylene_RES_ALL"]

	####Variables####
	#Define variables needed across both commit and no commit sets
    
    #Amount of Ethylene Produced in tonne
	@variable(EP, vEthylene_Prod[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )

	#Amount of Ethane required in tonne
	@variable(EP, vEthylene_ethanein[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )

	#Amount of Ethanol required in tonne
	@variable(EP, vEthylene_ethanolin[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )

	#Amount of Ethanol required in tonne
	@variable(EP, vEthylene_CO2in[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	
    #Power Required by Ethylene Resource
    @variable(EP, vEthylene_Power_in[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )

    #Hydrogen Produced by Ethylene Resource
    @variable(EP, vEthylene_H2out[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )

	#Natural Gas Consumed Ethylene Production Resource
	@variable(EP, vEthylene_NG_in[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	

	#################################################################################################################

	###Expressions###
	@expression(EP, eEthylene_Prod_Plant[k = 1:Ethylene_RES_ALL, t=1:T], vEthylene_Prod[k,t])

    # Ethylene Balance Expression
    @expression(EP, eEthylene_Prod[t=1:T, z=1:Z],
		sum(EP[:eEthylene_Prod_Plant][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))


	EP[:eEthyleneBalance] += eEthylene_Prod
	

	##################################################################################################################


	#Power Balance Expression

	#@expression(EP, eEthylene_NG_Cons_cost[t=1:T, z=1:Z],
	# 	sum(EP[:vEthylene_Power_in][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID]))) 



	@expression(EP, eEthylene_Power_Cons[t=1:T, z=1:Z],
		sum(EP[:vEthylene_Power_in][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID]))) 

	EP[:ePowerBalance] += -eEthylene_Power_Cons
		
	#Power consumption associated with Ethylene Production in each time step 
	############## Old Code ##################
	#@constraints(EP, begin
	#[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_Power_in][k,t] == EP[:vEthylene_ethanein][k,t] * dfEthylene[!,:mwh_p_tonne_ethane][k]
	#end)
	#################################### ----------  #####################
	@constraints(EP, begin
	[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_Power_in][k,t] == EP[:vEthylene_Prod][k,t] * dfEthylene[!,:mwh_p_tonne_ethylene][k]
	end)

	##################################################################################################################

	# Hydrogen Balance Expression
	@expression(EP, eEthylene_H2_Prod[t=1:T, z=1:Z],
	sum(EP[:vEthylene_H2out][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] += eEthylene_H2_Prod

	# Hydrogen Production
	################  Old Code  ########################################
	#@constraints(EP, begin
	#[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_H2out][k,t] == EP[:vEthylene_ethanein][k,t] * dfEthylene[!,:tonnes_h2_p_tonne_ethane][k]
	#end)
	############################ ---------------------- #######################

	@constraints(EP, begin
	[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_H2out][k,t] == EP[:vEthylene_Prod][k,t] * dfEthylene[!,:tonnes_h2_p_tonne_ethylene][k]
	end)
	
	################################################################################################################

	# Natural Gas Balance Expression

	@expression(EP, eEthylene_NG_Cons[t=1:T, z=1:Z],
	sum(EP[:vEthylene_NG_in][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))

	# Old: EP[:eNGBalance] -= eEthylene_NG_Cons
	EP[:eNGBalance] += -eEthylene_NG_Cons

	

	# EP[:eNGBalance] += -EP[:eBio_ELEC_Plant_NG_consumption_per_time_per_zone]
	# NG usage
	################################### Old Code  ############################
	#@constraints(EP, begin 
	#[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_NG_in][k,t] == EP[:vEthylene_ethanein][k,t] * dfEthylene[!,:mmbtu_ng_p_tonne_ethane][k]
	#end)
	####################################  ------------------------  ################################
	
	@constraints(EP, begin 
	[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_NG_in][k,t] == EP[:vEthylene_Prod][k,t] * dfEthylene[!,:mmbtu_ng_p_tonne_ethylene][k]
	end)
	# Cost of Natural Gas consumed in Ethylene Production

	@expression(EP,eNG_Cons_cost_per_time[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_NG_in][k,t]*dfEthylene[!,:ng_cost_p_mmbtu_ng][k])

	@expression(EP,eNG_Cons_cost_per_type[k in 1:Ethylene_RES_ALL], sum(EP[:eNG_Cons_cost_per_time][k,t] for t in 1:T))

	@expression(EP,eNG_Cons_cost, sum(EP[:eNG_Cons_cost_per_type][k] for k in 1:Ethylene_RES_ALL))
	# Add term to objective function expression
	EP[:eObj] += EP[:eNG_Cons_cost]


	###Constraints###
	
	# Ethylene Production Equal to Ethane in * Conversion factor 
	##################################### Old Code  ##########################################
	#@constraints(EP, begin 
	#[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_Prod][k,t] == EP[:vEthylene_ethanein][k,t] * dfEthylene[!,:tonne_ethylene_p_tonne_ethane][k]
	#end)
	################################## ----  ##############################################

	################################################ Big Error ##############################
	#@constraints(EP, begin 
	#[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_Prod][k,t] == EP[:vEthylene_Prod][k,t] * dfEthylene[!,:tonne_ethane_p_tonne_ethylene][k]
	#end)

	@expression(EP, eEthylene_Ethane_Cons[t=1:T, z=1:Z],
	sum(EP[:vEthylene_ethanein][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	
	# Ethane input constraint
	@constraints(EP, begin 
	[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_ethanein][k,t] == EP[:vEthylene_Prod][k,t] * dfEthylene[!,:tonne_ethane_p_tonne_ethylene][k]
	end)


	# Ethane Balance
	# EP[:eEthaneBalance] += -eEthylene_Ethane_Cons

	# Ethanol input constraint Balance

	@expression(EP, eEthylene_Ethanol_Cons[t=1:T, z=1:Z],
	sum(EP[:vEthylene_ethanolin][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	
	# Ethane input constraint
	@constraints(EP, begin 
	[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_ethanolin][k,t] == EP[:vEthylene_Prod][k,t] * dfEthylene[!,:tonne_ethanol_p_tonne_ethylene][k]
	end)

	# Ethanol Balance
	# EP[:eEthanolBalance] += -eEthylene_Ethanol_Cons

	# CO2 inout constraint balance

	@expression(EP, eEthylene_CO2in_Cons[t=1:T, z=1:Z],
	sum(EP[:vEthylene_CO2in][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	
	# Ethane input constraint
	@constraints(EP, begin 
	[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_CO2in][k,t] == EP[:vEthylene_Prod][k,t] * dfEthylene[!,:tonne_co2in_p_tonne_ethylene][k]
	end)

	# CO2 Balance
	# EP[:eCaptured_CO2_Balance] += -EP[:vEthylene_CO2in]

    #Plant CO2 captured per type of resource defined by CCS rate (Add to captured CO2 balance)
    #@expression(EP,eEthylene_CO2_Captured_By_Res[k=1:Ethylene_RES_ALL,t=1:T], 
    #dfEthylene[!,:CCS_Rate][k] * EP[:eEthylene_CO2_Production_By_Plant][k,t])

    #Total CO2 used from capture per zone per time
    @expression(EP, eEthylene_CO2_From_Capture_Per_Zone_Per_Time[z=1:Z, t=1:T], 
    sum(vEthylene_CO2in[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))

    @expression(EP, eEthylene_CO2_From_Capture_Per_Time_Per_Zone[t=1:T, z=1:Z], 
    sum(vEthylene_CO2in[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))

    #ADD TO CO2 BALANCE
    EP[:eCaptured_CO2_Balance] += -EP[:eEthylene_CO2_From_Capture_Per_Time_Per_Zone]



    # Production must be smaller than available capacity
	@constraints(EP, begin 
	[k in 1:Ethylene_RES_ALL, t=1:T], EP[:vEthylene_Prod][k,t] <= EP[:vCapacity_Ethylene_per_type][k] 
	end)

	=#

	##################################################### VERSION 2 ###########################################

	## step 1: load the saved information
	# Greenfield projects:
	dfEthylene = inputs["dfEthylene"]
	Ethylene_RES_ALL = inputs["Ethylene_RES_ALL"]
	# Existing projects:
	dfEthylene_plants = inputs["dfEthylene_plants"]
	Ethylene_Plants_ALL = inputs["Ethylene_Plants_ALL"]

	Plant_Inv_Cost_p_tonne_ethylene_p_hr_yr = dfEthylene_plants[!,:Plant_Inv_Cost_p_tonne_ethylene_p_hr_yr] # $/tonne
	Plant_Fixed_OM_cost_p_tonne_ethylene_p_hr_yr = dfEthylene_plants[!,:Plant_Fixed_OM_cost_p_tonne_ethylene_p_hr_yr]  # $/tonne
	Syn_gasoline_co2_per_mmbtu = inputs["Syn_gasoline_co2_per_mmbtu"]
	# Other quantities:
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## step 2: Define variables-
	# Inputs to the process (a) raw material: Ethane, Ethanol, CO2 and H2 (b) power, and (c) natural gas
	# Ethane demand in ton (a) Greenfield projects, and (b) Existing plants
	@variable(EP, vEthylene_ethanein_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_ethanein_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )

	# Ethanol demand in ton (a) Greenfield projects, and (b) Existing plants
	@variable(EP, vEthylene_ethanolin_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_ethanolin_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )

	# CO2 demand in ton (a) Greenfield projects, and (b) Existing plants
	@variable(EP, vEthylene_CO2in_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_CO2in_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )

	# H2 demand in ton (a) Greenfield projects, and (b) Existing plants: Added negative of output
	# @variable(EP, vEthylene_H2in_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	# @variable(EP, vEthylene_H2in_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )
	
	# Power demand in MW (a) Greenfield projects, and (b) Existing plants
	@variable(EP, vEthylene_Powerin_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_Powerin_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )

	@variable(EP, vEthylene_Powerout_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_Powerout_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )

	# Natural gas demand in mmbtu (a) Greenfield projects, and (b) Existing plants
	@variable(EP, vEthylene_NGin_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_NGin_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )




	# Outputs from the process (a) Ethylene (b) hydrogen, (c) methane, (d) C3+ and (e) CO2 (written in the emissions file)

	# Ethylene production in ton (a) Greenfield projects, and (b) Existing plants
	@variable(EP, vEthylene_Prod_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_Prod_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )

	# H2 produced in ton (a) Greenfield projects, and (b) Existing plants
	@variable(EP, vEthylene_H2out_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_H2out_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_H2in_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_H2in_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )

	# CH4 produced in ton (a) Greenfield projects, and (b) Existing plants
	@variable(EP, vEthylene_CH4out_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_CH4out_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )

	# Gasoline produced in ton: Greenfield projects
	@variable(EP, vEthylene_Gasolineout_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )


	# LPG (C3+) produced in ton (a) Greenfield projects, and (b) Existing plants
	@variable(EP, vEthylene_C3plusout_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_C3plusout_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )

	# Propylene produced in ton (a) Greenfield projects, and (b) Existing plants
	@variable(EP, vEthylene_Propylene_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_Propylene_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )

	## step 3: Variables estimation (a) Ethylene, (b) Ethane, (c) Ethanol, (d) Hydrogen, (e) CO2, (f) methane, (g) LPG, (h) Power, and (i) Natural gas 
	## (a) Ethylene:
	# Ethylene balance for Greenfield projects
	@expression(EP, eEthylene_Prod_RES[k = 1:Ethylene_RES_ALL, t=1:T], vEthylene_Prod_GF[k,t])
	@expression(EP, eEthylene_Prod_GF[t=1:T, z=1:Z], sum(EP[:eEthylene_Prod_RES][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:eEthyleneBalance] += eEthylene_Prod_GF




	# Ethylene balance for Existing plants
	if setup["ModelEthylenePlants"] == 1
		@expression(EP, eEthylene_Prod_Plant[k = 1:Ethylene_Plants_ALL, t=1:T], vEthylene_Prod_EP[k,t])
		@expression(EP, eEthylene_Prod_EP[t=1:T, z=1:Z], sum(EP[:eEthylene_Prod_Plant][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
	
		EP[:eEthyleneBalance] += eEthylene_Prod_EP

		if setup["ModelEthylenePlantsDecommissioning"] == 1
			println(" -- Ethylene Plants Decommissioning module")

			@variable(EP, 0 <= vEthylene_PlantStatus[k = 1:Ethylene_Plants_ALL] <= 1)
			#@variable(EP, vEthylene_PlantStatus[k = 1:Ethylene_Plants_ALL], Bin)


			@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Prod_EP][k,t] <= EP[:vEthylene_PlantStatus][k] * dfEthylene_plants[!,:Ethylene_Capacity_t_p_hr][k] end)
			@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Prod_EP][k,t] >= EP[:vEthylene_PlantStatus][k] * dfEthylene_plants[!,:MinEthylene_Production_t_p_hr][k] end)
            @expression(EP, eFixed_OM_Ethylene_per_type_EP[i in 1:Ethylene_Plants_ALL], dfEthylene_plants[!,:Ethylene_Capacity_t_p_hr][i] * Plant_Fixed_OM_cost_p_tonne_ethylene_p_hr_yr[i] * EP[:vEthylene_PlantStatus][i])
			@expression(EP, eFixed_Cost_Ethylene_per_type_EP[i in 1:Ethylene_Plants_ALL], EP[:eFixed_OM_Ethylene_per_type_EP][i])
			@expression(EP,eFixed_Cost_Ethylene_total_EP, sum(EP[:eFixed_Cost_Ethylene_per_type_EP][i] for i in 1:Ethylene_Plants_ALL))
			EP[:eObj] += EP[:eFixed_Cost_Ethylene_total_EP]
			# Existing plants: Expression for total Fixed OM for all resource types 
			@expression(EP,eFixed_OM_Ethylene_total_EP, sum(EP[:eFixed_OM_Ethylene_per_type_EP][i] for i in 1:Ethylene_Plants_ALL))

		else
			@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Prod_EP][k,t] <= dfEthylene_plants[!,:Ethylene_Capacity_t_p_hr][k] end)
			@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Prod_EP][k,t] >= dfEthylene_plants[!,:MinEthylene_Production_t_p_hr][k] end)
		end
	end
	

	## (b) Ethane:
	# Ethane balance for Greenfield projects
	@expression(EP, eEthylene_Ethane_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_ethanein_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_ethanein_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:tonne_ethane_p_tonne_ethylene][k] end)
	
	if setup["ModelEthanePurchase"] == 1
		EP[:eEthaneBalance] -= eEthylene_Ethane_RES
	end
	# 

	# Ethane balance for Existing plants
	
	if setup["ModelEthylenePlants"] == 1
		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_ethanein_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plants_tonne_ethane_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_Ethane_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_ethanein_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
		
		if setup["ModelEthanePurchase"] == 1
			EP[:eEthaneBalance] -= eEthylene_Ethane_Plant
		end
		
	end
	# 

	## (c) Ethanol:
	# Ethanol balance for Greenfield projects
	@constraints(EP, begin	[k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_ethanolin_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:tonne_ethanol_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_Ethanol_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_ethanolin_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:eEthanolBalance] += -eEthylene_Ethanol_RES

	# Ethanol balance for Existing plants
	if setup["ModelEthylenePlants"] == 1
		@constraints(EP, begin	[k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_ethanolin_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plants_tonne_ethanol_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_Ethanol_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_ethanolin_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
	
		EP[:eEthanolBalance] += -eEthylene_Ethanol_Plant
	end
	


	## (d) Hydrogen:
	# Hydrogen balance for Greenfield projects: Out
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_H2out_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:tonnes_h2_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_H2_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_H2out_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:eH2Balance] += eEthylene_H2_RES

	# Hydrogen balance for Existing plants: Out
	if setup["ModelEthylenePlants"] == 1
		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_H2out_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plants_tonnes_h2_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_H2_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_H2out_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
	
		EP[:eH2Balance] += eEthylene_H2_Plant
	end
	

	# Hydrogen balance for Greenfield projects: In
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_H2in_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:tonnes_h2in_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_H2in_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_H2in_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:eH2Balance] -= eEthylene_H2in_RES

	# Hydrogen balance for Existing plants: In
	if setup["ModelEthylenePlants"] == 1
		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_H2in_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plants_tonnes_h2in_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_H2in_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_H2in_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
	
		EP[:eH2Balance] -= eEthylene_H2in_Plant
	end
	

	## (e) CO2:
	# CO2 balance for Greenfield projects
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_CO2in_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:tonne_co2in_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_CO2in_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_CO2in_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	@expression(EP, eEthylene_CO2inCCS_RES[z=1:Z, t=1:T], sum(EP[:vEthylene_CO2in_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	@expression(EP, eEthylene_CO2in_RES_zone_per_time[z=1:Z, t=1:T], sum(EP[:vEthylene_CO2in_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:eCaptured_CO2_Balance] -= eEthylene_CO2in_RES
	# @expression(EP, eEthylene_CO2_Capture_Per_Time_Per_Zone_GF[t=1:T, z=1:Z], sum(eEthylene_CO2_Captured_By_RES[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))
	
	# CO2 balance for Existing plants
	if setup["ModelEthylenePlants"] == 1
		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_CO2in_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plants_tonne_co2in_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_CO2in_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_CO2in_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
		@expression(EP, eEthylene_CO2inCCS_Plant[z=1:Z, t=1:T], sum(EP[:vEthylene_CO2in_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
		@expression(EP, eEthylene_CO2in_Plantzone_per_time[z=1:Z, t=1:T], sum(EP[:vEthylene_CO2in_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
	
		EP[:eCaptured_CO2_Balance] -= eEthylene_CO2in_Plant
	end
	

	#@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_CO2in_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:tonne_co2in_p_tonne_ethylene][k] end)
	#@expression(EP, eEthylene_CO2in_RES[t=1:T, z=1:Z], 
	#	sum(EP[:vEthylene_CO2in_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
		# @expression(EP, eEthylene_CO2_From_Capture_Per_Time_Per_Zone_GF[t=1:T, z=1:Z], sum(vEthylene_CO2in_GF[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))
	#EP[:eCaptured_CO2_Balance] -= eEthylene_CO2in_RES 


	# @expression(EP, eSyn_Fuel_CO2_Cons_Per_Time_Per_Zone[t=1:T, z=1:Z], sum(EP[:vSFCO2in][k,t] for k in intersect(1:SYN_FUELS_RES_ALL, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))
	# EP[:eCaptured_CO2_Balance] -= eSyn_Fuel_CO2_Cons_Per_Time_Per_Zone

	# CO2 balance for Existing plants
	#@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_CO2in_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plants_tonne_co2in_p_tonne_ethylene][k] end)
	#@expression(EP, eEthylene_CO2in_Plant[t=1:T, z=1:Z], 
#		sum(EP[:vEthylene_CO2in_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
		# @expression(EP, eEthylene_CO2_From_Capture_Per_Time_Per_Zone_EP[t=1:T, z=1:Z], sum(vEthylene_CO2in_EP[k,t] for k in dfEthylene_plants[(dfEthylene_plants[!,:Plant_Zone].==z),:R_ID]))
#	EP[:eCaptured_CO2_Balance] -= eEthylene_CO2in_Plant 

	## (f) Methane:
	# Methane balance for Greenfield projects
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_CH4out_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * tonne_to_mmbtu_NG * dfEthylene[!,:tonne_methane_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_CH4_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_CH4out_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:eNGBalance] += eEthylene_CH4_RES

	# Methane balance for Existing plants
	if setup["ModelEthylenePlants"] == 1
		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_CH4out_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * tonne_to_mmbtu_NG * dfEthylene_plants[!,:Plants_tonne_methane_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_CH4_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_CH4out_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
	
		EP[:eNGBalance] += eEthylene_CH4_Plant
	end
	


	## (g) LPG
	# LPG balance for Greenfield projects
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_C3plusout_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:tonne_LPG_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_C3plus_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_C3plusout_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	# EP[:eLPGBalance] += eEthylene_C3plus_RES

    @expression(EP, eTotal_C3Plus_RES_z[z = 1:Z], sum((inputs["omega"][t] * inputs["LPG_Prices"][t,z] * eEthylene_C3plus_RES[t,z]) for t in 1:T))
    @expression(EP, eTotal_C3Plus_RES, sum(EP[:eTotal_C3Plus_RES_z][z] for z in 1:Z))
	EP[:eObj] -= eTotal_C3Plus_RES


	# LPG balance for Existing plants
	if setup["ModelEthylenePlants"] == 1
		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_C3plusout_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plants_tonne_LPG_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_C3plus_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_C3plusout_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
		# EP[:eLPGBalance] += eEthylene_C3plus_Plant
		@expression(EP, eTotal_C3Plus_Plant_z[z = 1:Z], sum((inputs["omega"][t] * inputs["LPG_Prices"][t,z] * eEthylene_C3plus_Plant[t,z]) for t in 1:T))
		@expression(EP, eTotal_C3Plus_Plant, sum(EP[:eTotal_C3Plus_Plant_z][z] for z in 1:Z))
		EP[:eObj] -= eTotal_C3Plus_Plant
	end

	# Propylene 
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_Propylene_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:tonne_Propylene_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_Propylene_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_Propylene_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	
	if setup["ModelPropylenePurchase"] == 1
		EP[:ePropyleneBalance] += eEthylene_Propylene_RES
	end

	if setup["ModelEthylenePlants"] == 1
		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Propylene_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plant_tonne_Propylene_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_Propylene_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_Propylene_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))

		EP[:ePropyleneBalance] += eEthylene_Propylene_Plant

	end



	## (h) Power
	# Power balance for Greenfield projects: In
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_Powerin_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:mwh_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_Power_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_Powerin_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:ePowerBalance] += -eEthylene_Power_RES

	# Power balance for Existing plants: In
	if setup["ModelEthylenePlants"] == 1
		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Powerin_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plants_mwh_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_Power_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_Powerin_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
	
		EP[:ePowerBalance] += -eEthylene_Power_Plant
	end
	
	

	# Power balance for Greenfield projects: Out
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_Powerout_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:mwh_out_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_Powerout_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_Powerout_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:ePowerBalance] += eEthylene_Powerout_RES
	
	# Power balance for Existing plants: Out
	
	if setup["ModelEthylenePlants"] == 1
		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Powerout_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plants_mwh_out_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_Powerout_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_Powerout_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
	
		EP[:ePowerBalance] += eEthylene_Powerout_Plant
	end
	

	## (i) Natural Gas
	# Natural gas balance for Greenfield projects
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_NGin_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:mmbtu_ng_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_NG_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_NGin_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:eNGBalance] += -eEthylene_NG_RES

	# Cost associated with NG supply for Greenfield projects: Accounted in the variable cost
	#@expression(EP,eNG_Cons_cost_per_time_RES[k in 1:Ethylene_RES_ALL, t = 1:T], #EP[:vEthylene_NGin_GF][k,t]*dfEthylene[!,:ng_cost_p_mmbtu_ng][k])
	#@expression(EP,eNG_Cons_cost_per_type_RES[k in 1:Ethylene_RES_ALL], #sum(EP[:eNG_Cons_cost_per_time_RES][k,t] for t in 1:T))
	#@expression(EP,eNG_RES_cost, sum(EP[:eNG_Cons_cost_per_type_RES][k] for k in #1:Ethylene_RES_ALL))
	#EP[:eObj] += EP[:eNG_RES_cost]

	# Natural gas balance for Existing plants
	
	
	if setup["ModelEthylenePlants"] == 1
		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_NGin_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plants_mmbtu_ng_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_NG_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_NGin_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
		EP[:eNGBalance] += -eEthylene_NG_Plant
	end
	
	# (j) Gasoline
	
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_Gasolineout_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * tonne_to_mmbtu_Gasoline * dfEthylene[!,:tonne_Gasoline_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_Gasoline_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_Gasolineout_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:eSBFGasolineBalance] += eEthylene_Gasoline_RES

	@expression(EP,eCO2_Gasoline_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], Syn_gasoline_co2_per_mmbtu * EP[:eEthylene_Gasoline_RES][t,z])

	# Cost associated with NG supply for Existing plants: Accounted in the variable cost
	#@expression(EP,eNG_Cons_cost_per_time_Plants[k in 1:Ethylene_Plants_ALL, t = 1:T], #EP[:vEthylene_NGin_EP][k,t]*dfEthylene_plants[!,:Plants_ng_cost_p_mmbtu_ng][k])
	#@expression(EP,eNG_Cons_cost_per_type_Plant[k in 1:Ethylene_Plants_ALL], #sum(EP[:eNG_Cons_cost_per_time_Plants][k,t] for t in 1:T))
	#@expression(EP,eNG_Plant_cost, sum(EP[:eNG_Cons_cost_per_type_Plant][k] for k in #1:Ethylene_Plants_ALL))
	#EP[:eObj] += EP[:eNG_Plant_cost]

	## Step 4: Constraints on the plant capacities (a) Greenfield (capacity is a variable) and (b) Existing plants (fixed capacities)  
	# Capacities for the Greenfield projects 
	@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t=1:T], EP[:vEthylene_Prod_GF][k,t] <= EP[:vCapacity_Ethylene_per_type_GF][k] end)
	# Capacities for the Existing plants
#	if setup["ModelEthylenePlants"] == 1
#		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Prod_EP][k,t] <= dfEthylene_plants[!,:Ethylene_Capacity_t_p_hr][k] end)
#		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_Prod_EP][k,t] >= dfEthylene_plants[!,:MinEthylene_Production_t_p_hr][k] end)
#	end

	if setup["ModelProductionRamping"] == 1
		println(" -- Ethylene Production Ramping")
		# Ramping constraints for Greenfield projects
		#=
		@constraint(EP, [k = 1:Ethylene_RES_ALL, t = 1:T-1], vEthylene_Prod_GF[k,t+1] <= (1+EthylenePlantRamping) * vEthylene_Prod_GF[k,t])
		@constraint(EP, [k = 1:Ethylene_RES_ALL, t = 1:T-1], (1-EthylenePlantRamping) * vEthylene_Prod_GF[k,t] <= vEthylene_Prod_GF[k,t+1])
		=#
		@constraints(EP, begin [k in 1:Ethylene_RES_ALL, t=1:T],  EthylenePlantRamping * EP[:vCapacity_Ethylene_per_type_GF][k] <= EP[:vEthylene_Prod_GF][k,t] end)
		# Ramping constraints for Existing plants (if they are modeled)
		#=
		if setup["ModelEthylenePlants"] == 1
			@constraint(EP, [k = 1:Ethylene_Plants_ALL, t = 1:T-1], vEthylene_Prod_EP[k,t+1] <= (1+EthylenePlantRamping) * vEthylene_Prod_EP[k,t])
			@constraint(EP, [k = 1:Ethylene_Plants_ALL, t = 1:T-1], (1-EthylenePlantRamping) * vEthylene_Prod_EP[k,t] <= vEthylene_Prod_EP[k,t+1])
		end
		=#

	end

	if setup["ModelEthyleneRetrofitting"] == 1  

		println(" -- Ethylene Plants Retrofitting module")

		dfEthylene_retrofit = inputs["dfEthylene_retrofit"]
        Ethylene_retrofit_ALL = inputs["Ethylene_retrofit_ALL"]
		@variable(EP, vEthylene_ethanein_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
		# @variable(EP, vEthylene_ethanolin_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
		# @variable(EP, vEthylene_CO2in_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
		@variable(EP, vEthylene_Powerin_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
		# @variable(EP, vEthylene_Powerout_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
		@variable(EP, vEthylene_NGin_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
		@variable(EP, vEthylene_Prod_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
		@variable(EP, vEthylene_H2out_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
		@variable(EP, vEthylene_H2in_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
		@variable(EP, vEthylene_CH4out_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
		@variable(EP, vEthylene_C3plusout_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
		@variable(EP, vEthylene_Propylene_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )

		# Ethylene Production
		@expression(EP, eEthylene_Prod_RetrofitRES[k = 1:Ethylene_retrofit_ALL, t=1:T], vEthylene_Prod_Retrofit[k,t])
		@expression(EP, eEthylene_Prod_Retrofit[t=1:T, z=1:Z], sum(EP[:eEthylene_Prod_RetrofitRES][k,t] for k in intersect(1:Ethylene_retrofit_ALL, dfEthylene_retrofit[dfEthylene_retrofit[!,:Retrofit_Zone].==z,:][!,:R_ID])))
		EP[:eEthyleneBalance] += eEthylene_Prod_Retrofit




		# Ethane Required		
		@constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t = 1:T], EP[:vEthylene_ethanein_Retrofit][k,t] == EP[:vEthylene_Prod_Retrofit][k,t] * dfEthylene_retrofit[!,:Retrofit_tonne_ethane_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_Ethane_Retrofit[t=1:T, z=1:Z], sum(EP[:vEthylene_ethanein_Retrofit][k,t] for k in intersect(1:Ethylene_retrofit_ALL, dfEthylene_retrofit[dfEthylene_retrofit[!,:Retrofit_Zone].==z,:][!,:R_ID])))
		
		if setup["ModelEthanePurchase"] == 1
			EP[:eEthaneBalance] -= eEthylene_Ethane_Retrofit
		end

		# Hydrogen generated
		@constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t = 1:T], EP[:vEthylene_H2out_Retrofit][k,t] == EP[:vEthylene_Prod_Retrofit][k,t] * dfEthylene_retrofit[!,:Retrofit_tonnes_h2_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_H2_Retrofit[t=1:T, z=1:Z], sum(EP[:vEthylene_H2out_Retrofit][k,t] for k in intersect(1:Ethylene_retrofit_ALL, dfEthylene_retrofit[dfEthylene_retrofit[!,:Retrofit_Zone].==z,:][!,:R_ID])))
		EP[:eH2Balance] += eEthylene_H2_Retrofit

		# Hydrogen Input to the plants		
		@constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t = 1:T], EP[:vEthylene_H2in_Retrofit][k,t] == EP[:vEthylene_Prod_Retrofit][k,t] * dfEthylene_retrofit[!,:Retrofit_tonnes_h2in_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_H2in_Retrofit[t=1:T, z=1:Z], sum(EP[:vEthylene_H2in_Retrofit][k,t] for k in intersect(1:Ethylene_retrofit_ALL, dfEthylene_retrofit[dfEthylene_retrofit[!,:Retrofit_Zone].==z,:][!,:R_ID])))
		EP[:eH2Balance] -= eEthylene_H2in_Retrofit

		# LPG Produced
		@constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t = 1:T], EP[:vEthylene_C3plusout_Retrofit][k,t] == EP[:vEthylene_Prod_Retrofit][k,t] * dfEthylene_retrofit[!,:Retrofit_tonne_LPG_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_C3plus_Retrofit[t=1:T, z=1:Z], sum(EP[:vEthylene_C3plusout_Retrofit][k,t] for k in intersect(1:Ethylene_retrofit_ALL, dfEthylene_retrofit[dfEthylene_retrofit[!,:Retrofit_Zone].==z,:][!,:R_ID])))
		# EP[:eLPGBalance] += eEthylene_C3plus_Retrofit
		@expression(EP, eTotal_C3Plus_Retrofit_z[z = 1:Z], sum((inputs["omega"][t] * inputs["LPG_Prices"][t,z] * eEthylene_C3plus_Retrofit[t,z]) for t in 1:T))
		@expression(EP, eTotal_C3Plus_Retrofit, sum(EP[:eTotal_C3Plus_Retrofit_z][z] for z in 1:Z))
		EP[:eObj] -= eTotal_C3Plus_Retrofit

		# Propylene
		@constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t = 1:T], EP[:vEthylene_Propylene_Retrofit][k,t] == EP[:vEthylene_Prod_Retrofit][k,t] * dfEthylene_retrofit[!,:Retrofit_tonne_Propylene_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_Propylene_Retrofit[t=1:T, z=1:Z], sum(EP[:vEthylene_Propylene_Retrofit][k,t] for k in intersect(1:Ethylene_retrofit_ALL, dfEthylene_retrofit[dfEthylene_retrofit[!,:Retrofit_Zone].==z,:][!,:R_ID])))
		EP[:ePropyleneBalance] += eEthylene_Propylene_Retrofit

		# Power Input to the plant		
		@constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t = 1:T], EP[:vEthylene_Powerin_Retrofit][k,t] == EP[:vEthylene_Prod_Retrofit][k,t] * dfEthylene_retrofit[!,:Retrofit_mwh_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_Power_Retrofit[t=1:T, z=1:Z], sum(EP[:vEthylene_Powerin_Retrofit][k,t] for k in intersect(1:Ethylene_retrofit_ALL, dfEthylene_retrofit[dfEthylene_retrofit[!,:Retrofit_Zone].==z,:][!,:R_ID])))
		EP[:ePowerBalance] += -eEthylene_Power_Retrofit

		# Natural Gas to the plant		
		@constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t = 1:T], EP[:vEthylene_NGin_Retrofit][k,t] == EP[:vEthylene_Prod_Retrofit][k,t] * dfEthylene_retrofit[!,:Retrofit_mmbtu_ng_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_NG_Retrofit[t=1:T, z=1:Z], sum(EP[:vEthylene_NGin_Retrofit][k,t] for k in intersect(1:Ethylene_retrofit_ALL, dfEthylene_retrofit[dfEthylene_retrofit[!,:Retrofit_Zone].==z,:][!,:R_ID])))
		EP[:eNGBalance] += -eEthylene_NG_Retrofit

		# Methane Production 
		@constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t = 1:T], EP[:vEthylene_CH4out_Retrofit][k,t] == EP[:vEthylene_Prod_Retrofit][k,t] * tonne_to_mmbtu_NG * dfEthylene_retrofit[!,:Retrofit_tonne_methane_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_CH4_Retrofit[t=1:T, z=1:Z], sum(EP[:vEthylene_CH4out_Retrofit][k,t] for k in intersect(1:Ethylene_retrofit_ALL, dfEthylene_retrofit[dfEthylene_retrofit[!,:Retrofit_Zone].==z,:][!,:R_ID])))
		EP[:eNGBalance] += eEthylene_CH4_Retrofit
		
		
		
		# Ethylene Production Capacities
		@constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t=1:T], EP[:vEthylene_Prod_Retrofit][k,t] <= EP[:vCapacity_Ethylene_per_type_Retrofit][k] end)
		@constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t=1:T],  EthylenePlantRamping * EP[:vCapacity_Ethylene_per_type_Retrofit][k] <= EP[:vEthylene_Prod_Retrofit][k,t] end)


		# Ethylene Production from EP + Retroftting = Original EP 

		@constraint(EP, cNetEthyleneProd[t=1:T,z=1:Z], (EP[:eEthylene_Prod_EP][t,z] + EP[:eEthylene_Prod_Retrofit][t,z]) <= inputs["Ethylene_EPs"][t,z])



	end
	

	

	

	
	return EP
end
