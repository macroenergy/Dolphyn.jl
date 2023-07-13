"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
syn_fuel_investment(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the built capacity and the total fixed cost (Investment + Fixed O&M) of Synfuel resource $k$.

"""
function syn_fuel_investment(EP::Model, inputs::Dict, setup::Dict)
	
	println("Syn Fuel Cost module")

    dfSynFuels = inputs["dfSynFuels"]
	SYN_FUELS_RES_ALL = inputs["SYN_FUELS_RES_ALL"]
	T = inputs["T"]     # Number of time steps (hours)
	
	##Load cost parameters
	#  ParameterScale = 1 --> objective function is in million $ . 
	# In powedfSynFuelr system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	#  ParameterScale = 0 --> objective function is in $

	#General variables for non-piecewise and piecewise cost functions
	@variable(EP,vCapacity_Syn_Fuel_per_type[i in 1:SYN_FUELS_RES_ALL]>=0) #Capacity of units in co2 input mtonnes/hr 
	@variable(EP,vCAPEX_Syn_Fuel_per_type[i in 1:SYN_FUELS_RES_ALL])

	if setup["ParameterScale"] == 1
		MinCapacity_tonne_p_hr = dfSynFuels[!,:MinCapacity_tonne_p_hr]/ModelScalingFactor # kt/h
		MaxCapacity_tonne_p_hr = dfSynFuels[!,:MaxCapacity_tonne_p_hr]/ModelScalingFactor # kt/h
		Inv_Cost_p_tonne_co2_p_hr_yr = dfSynFuels[!,:Inv_Cost_p_tonne_co2_p_hr_yr]/ModelScalingFactor # $M/kton
		Fixed_OM_cost_p_tonne_co2_hr_yr = dfSynFuels[!,:Fixed_OM_cost_p_tonne_co2_hr_yr]/ModelScalingFactor # $M/kton
	else
		#Load capacity parameters
		MinCapacity_tonne_p_hr = dfSynFuels[!,:MinCapacity_tonne_p_hr] # t/h
		MaxCapacity_tonne_p_hr = dfSynFuels[!,:MaxCapacity_tonne_p_hr] # t/h/h
		Inv_Cost_p_tonne_co2_p_hr_yr = dfSynFuels[!,:Inv_Cost_p_tonne_co2_p_hr_yr] # $/tonne
		Fixed_OM_cost_p_tonne_co2_hr_yr = dfSynFuels[!,:Fixed_OM_cost_p_tonne_co2_hr_yr] # $/tonne
	end


	#Linear CAPEX using refcapex similar to fixed O&M cost calculation method
	#Investment cost = CAPEX
	#Consider using constraint for vCAPEX_Syn_Fuel_per_type? Or expression is better
	@expression(EP, eCAPEX_Syn_Fuel_per_type[i in 1:SYN_FUELS_RES_ALL], EP[:vCapacity_Syn_Fuel_per_type][i] * Inv_Cost_p_tonne_co2_p_hr_yr[i] )
	#Fixed OM cost #Check again to match capacity
	@expression(EP, eFixed_OM_Syn_Fuels_per_type[i in 1:SYN_FUELS_RES_ALL], EP[:vCapacity_Syn_Fuel_per_type][i] * Fixed_OM_cost_p_tonne_co2_hr_yr[i])

	
	#####################################################################################################################################
	#Min and max capacity constraints
	@constraint(EP,cMinSFCapacity_per_unit[i in 1:SYN_FUELS_RES_ALL], EP[:vCapacity_Syn_Fuel_per_type][i]  >= MinCapacity_tonne_p_hr[i])
	@constraint(EP,cMaxSFCapacity_per_unit[i in 1:SYN_FUELS_RES_ALL], EP[:vCapacity_Syn_Fuel_per_type][i]  <= MaxCapacity_tonne_p_hr[i])

	#####################################################################################################################################
	##Expressions
	#Cost per type of technology
	
	#Total fixed cost = CAPEX + Fixed OM
	@expression(EP, eFixed_Cost_Syn_Fuels_per_type[i in 1:SYN_FUELS_RES_ALL], EP[:eFixed_OM_Syn_Fuels_per_type][i] + EP[:eCAPEX_Syn_Fuel_per_type][i])

	#Total cost
	#Expression for total CAPEX for all resoruce types (For output and to add to objective function)
	@expression(EP,eCAPEX_Syn_Fuel_total, sum(EP[:eCAPEX_Syn_Fuel_per_type][i] for i in 1:SYN_FUELS_RES_ALL))

	#Expression for total Fixed OM for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_OM_Syn_Fuel_total, sum(EP[:eFixed_OM_Syn_Fuels_per_type][i] for i in 1:SYN_FUELS_RES_ALL))

	#Expression for total Fixed Cost for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_Cost_Syn_Fuel_total, sum(EP[:eFixed_Cost_Syn_Fuels_per_type][i] for i in 1:SYN_FUELS_RES_ALL))

	# Add term to objective function expression
	EP[:eObj] += EP[:eFixed_Cost_Syn_Fuel_total]

    return EP

end