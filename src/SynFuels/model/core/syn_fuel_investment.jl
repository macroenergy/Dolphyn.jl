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
    co2_investment(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the built capacity and the total fixed cost (Investment + Fixed O&M) of DAC resource $k$.

"""
function syn_fuel_investment(EP::Model, inputs::Dict, setup::Dict)
	
	println("Syn Fuel Cost module")

    dfSynFuel = inputs["dfSynFuel"]
	SYN_FUELS_RES_ALL = inputs["SYN_FUELS_RES_ALL"]
	T = inputs["T"]     # Number of time steps (hours)
	
	##Load cost parameters
	#  ParameterScale = 1 --> objective function is in million $ . 
	# In powedfSynFuelr system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	#  ParameterScale = 0 --> objective function is in $
	
	if setup["ParameterScale"] ==1 
		Inv_Cost_p_tonne_co2_p_hr_yr = dfSynFuel[!,:Inv_Cost_p_tonne_co2_p_hr_yr]/ModelScalingFactor^2 # $/t/h/y
		Fixed_OM_cost_p_tonne_co2_hr_yr = dfSynFuel[!,:Fixed_OM_cost_p_tonne_co2_hr_yr]/ModelScalingFactor^2 # $/t/h/y
	else
        Inv_Cost_p_tonne_co2_p_hr_yr = dfSynFuel[!,:Inv_Cost_p_tonne_co2_p_hr_yr]# $/t/h/y
		Fixed_OM_cost_p_tonne_co2_hr_yr = dfSynFuel[!,:Fixed_OM_cost_p_tonne_co2_hr_yr] # $/t/h/y
	end

	#Load capacity parameters
	MinCapacity_tonne_p_hr = dfSynFuel[!,:MinCapacity_tonne_p_hr] # t/h
	MaxCapacity_tonne_p_hr = dfSynFuel[!,:MaxCapacity_tonne_p_hr] # t/h

	#General variables for non-piecewise and piecewise cost functions
	@variable(EP,vCapacity_Syn_Fuel_per_type[i in 1:SYN_FUELS_RES_ALL]) #Capacity of units in co2 input mtonnes/hr 
	#@variable(EP,vDummy_Capacity_Syn_Fuel_per_type[i in 1:SYN_FUELS_RES_ALL, t in 1:T]) #To linearize UC constraint
	@variable(EP,vCAPEX_Syn_Fuel_per_type[i in 1:SYN_FUELS_RES_ALL])

	if setup["Syn_Fuel_CAPEX_Piecewise"] ==1 

        #COPIED FROM DAC. NEEDS TO BE MODIFIED FOR SYN FUELS

        #=

		#####################################################################################################################################
		##Piecewise Function for Investment Cost
		#Define steps for piecewise function
		Intervals = 4 #Parameter k must be geq 2 (k Intervals means k-1 segments), #Make option to choose different number of interval for diffferent unit types
		CAPEX_Intervals = zeros(SYN_FUELS_RES_ALL,Intervals) #Parameter alpha
		Capacity_Intervals = zeros(SYN_FUELS_RES_ALL,Intervals) #Parameter X

		#Input coordinates of capacity (x-axis) into piecewise and find corresponding line of CAPEX vs Capacity
		for i in 1:SYN_FUELS_RES_ALL

			#Fill up first coordinate as zero
			Capacity_Interval_Size_i = Cap_Size_tonne_p_hr[i]/(Intervals-2)
			CAPEX_Interval_Size_i = RefCAPEX_per_t_per_h_y[i]/(Intervals-2)
			
			Capacity_Intervals[i,1] = 0
			CAPEX_Intervals[i,1] = 0

			#Fill up other intervals
			for k in 2:Intervals-1
				Capacity_Intervals[i,k] = Capacity_Intervals[i,k-1] + Capacity_Interval_Size_i
				CAPEX_Intervals[i,k] = RefCAPEX_per_t_per_h_y[i]*(Capacity_Intervals[i,k]/Cap_Size_tonne_p_hr[i])^0.6
			end
		end

		#Write linear function to find plant Fixed OM from ref Capacity and ref Fixed OM
		#Not sure how to set infinity so we use a very large number which can be changed for example 100 MT/year approx = 10000 t/h
		#Find gradient of last segment
		DAC_CAPEX_Extrapolate_Gradient = zeros(SYN_FUELS_RES_ALL)

		for i in 1:SYN_FUELS_RES_ALL
			DAC_CAPEX_Extrapolate_Gradient[i] = (CAPEX_Intervals[i,Intervals-1] - CAPEX_Intervals[i,Intervals-2])/(Capacity_Intervals[i,Intervals-1] - Capacity_Intervals[i,Intervals-2])
		end

		#Extrapolate CAPEX as linear line to very large capacity limit after reference capacity of 1 MT/y
		DAC_CAPEX_Max_Limit = zeros(SYN_FUELS_RES_ALL)

		for i in 1:SYN_FUELS_RES_ALL
			DAC_CAPEX_Max_Limit[i] = CAPEX_Intervals[i,Intervals-1] + DAC_CAPEX_Extrapolate_Gradient[i] * (MaxCapacity_tonne_p_hr[i] - Capacity_Intervals[i,Intervals-1])
			Capacity_Intervals[i,Intervals] = MaxCapacity_tonne_p_hr[i]
			CAPEX_Intervals[i,Intervals] = DAC_CAPEX_Max_Limit[i]
		end

		#####################################################################################################################################
		##Variables
		#Model piecewise function for CAPEX
		@variable(EP,w_piecewise_DAC[i in 1:SYN_FUELS_RES_ALL, k in 1:Intervals] >= 0 )
		@variable(EP,z_piecewise_DAC[i in 1:SYN_FUELS_RES_ALL, k in 1:Intervals],Bin)
		@variable(EP,y_piecewise_DAC[i in 1:SYN_FUELS_RES_ALL],Bin)

		#####################################################################################################################################
		##Constraints

		#Piecewise constriants
		@constraint(EP,cSum_z_piecewise_DAC[i in 1:SYN_FUELS_RES_ALL], sum(EP[:z_piecewise_DAC][i,k] for k in 1:Intervals) == EP[:y_piecewise_DAC][i])
		@constraint(EP,cLeq_w_z_piecewise_DAC[i in 1:SYN_FUELS_RES_ALL,k in 1:Intervals], EP[:w_piecewise_DAC][i,k] <= EP[:z_piecewise_DAC][i,k])
		@constraint(EP,cCAPEX_DAC_per_type[i in 1:SYN_FUELS_RES_ALL], EP[:vCAPEX_Syn_Fuel_per_type][i] == sum(EP[:z_piecewise_DAC][i,k]*CAPEX_Intervals[i,k] + EP[:w_piecewise_DAC][i,k]*(CAPEX_Intervals[i,k-1]-CAPEX_Intervals[i,k]) for k = 2:Intervals))
		@constraint(EP,cCapacity_DAC_per_type[i in 1:SYN_FUELS_RES_ALL], EP[:vCapacity_Syn_Fuel_per_type][i] == sum(EP[:z_piecewise_DAC][i,k]*Capacity_Intervals[i,k] + EP[:w_piecewise_DAC][i,k]*(Capacity_Intervals[i,k-1]-Capacity_Intervals[i,k]) for k = 2:Intervals))
	
		#Investment cost = CAPEX
		@expression(EP, eCAPEX_Syn_Fuel_per_type[i in 1:SYN_FUELS_RES_ALL], EP[:vCAPEX_Syn_Fuel_per_type][i])

        =#

	elseif setup["Syn_Fuel_CAPEX_Piecewise"] == 0
		#Linear CAPEX using refcapex similar to fixed O&M cost calculation method
		#Investment cost = CAPEX
		#Consider using constraint for vCAPEX_Syn_Fuel_per_type? Or expression is better
		@expression(EP, eCAPEX_Syn_Fuel_per_type[i in 1:SYN_FUELS_RES_ALL], EP[:vCapacity_Syn_Fuel_per_type][i] * Inv_Cost_p_tonne_co2_p_hr_yr[i] )
	end

	#####################################################################################################################################
	#Min and max capacity constraints
	@constraint(EP,cMinCapacity_per_unit[i in 1:SYN_FUELS_RES_ALL], EP[:vCapacity_Syn_Fuel_per_type][i] * Cap_Size_tonne_p_hr[i] >= MinCapacity_tonne_p_hr[i])
	@constraint(EP,cMaxCapacity_per_unit[i in 1:SYN_FUELS_RES_ALL], EP[:vCapacity_Syn_Fuel_per_type][i] * Cap_Size_tonne_p_hr[i] <= MaxCapacity_tonne_p_hr[i])

	#####################################################################################################################################
	##Expressions
	#Cost per type of technology
	
	#Fixed OM cost #Check again to match capacity
	@expression(EP, eFixed_OM_Syn_Fuels_per_type[i in 1:SYN_FUELS_RES_ALL], EP[:vCapacity_Syn_Fuel_per_type][i] * Fixed_OM_cost_p_tonne_co2_hr_yr[i] * Cap_Size_tonne_p_hr[i])

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