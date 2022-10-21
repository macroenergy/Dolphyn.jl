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
    DAC_investment(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the built capacity and the total fixed cost (Investment + Fixed O&M) of DAC resource $k$.

"""
function co2_capture_investment(EP::Model, inputs::Dict, setup::Dict)
	
	println("DAC Fixed Cost module")

	dfCO2Capture = inputs["dfCO2Capture"]
	CO2_RES_ALL = inputs["CO2_RES_ALL"]

	Z = inputs["Z"]
	T = inputs["T"]
	
	#General variables for non-piecewise and piecewise cost functions
	@variable(EP,vCapacity_DAC_per_type[i in 1:CO2_RES_ALL])
	@variable(EP,vDummy_Capacity_DAC_per_type[i in 1:CO2_RES_ALL, t in 1:T]) #To linearize UC constraint
	@variable(EP,vCAPEX_DAC_per_type[i in 1:CO2_RES_ALL])

	if setup["ParameterScale"] == 1
		DAC_Capacity_Min_Limit = dfCO2Capture[!,:Min_capacity_tonne_per_hr]/ModelScalingFactor # kt/h
		DAC_Capacity_Max_Limit = dfCO2Capture[!,:Max_capacity_tonne_per_hr]/ModelScalingFactor # kt/h
	else
		DAC_Capacity_Min_Limit = dfCO2Capture[!,:Min_capacity_tonne_per_hr] # t/h
		DAC_Capacity_Max_Limit = dfCO2Capture[!,:Max_capacity_tonne_per_hr] # t/h
	end
	
	if setup["CSC_Nonlinear_CAPEX"] == 1

		if setup["ParameterScale"] == 1
			##Load cost and capacity parameters
			RefCAPEX_per_t_per_h_y = dfCO2Capture[!,:Ref_CAPEX_per_yr]/ModelScalingFactor^2 # $M
			RefFixed_OM_per_t_per_h_y = dfCO2Capture[!,:Ref_Fixed_OM_per_yr]/ModelScalingFactor^2 # $M
			RefCapacity_t_per_h = dfCO2Capture[!,:Ref_capacity_tonne_per_hr]/ModelScalingFactor # kt/h
		else
			##Load cost and capacity parameters
			RefCAPEX_per_t_per_h_y = dfCO2Capture[!,:Ref_CAPEX_per_yr] # $
			RefFixed_OM_per_t_per_h_y = dfCO2Capture[!,:Ref_Fixed_OM_per_yr] # $
			RefCapacity_t_per_h = dfCO2Capture[!,:Ref_capacity_tonne_per_hr] # t/h
		end
		
	
		if setup["DAC_CAPEX_Piecewise_Segments"] > 1
			#####################################################################################################################################
			##Piecewise Function for Investment Cost
			#Define steps for piecewise function
			Segments = setup["DAC_CAPEX_Piecewise_Segments"]
			Intervals = Segments + 1
			CAPEX_Intervals = zeros(CO2_RES_ALL,Intervals) #Parameter alpha
			Capacity_Intervals = zeros(CO2_RES_ALL,Intervals) #Parameter X
	
			#Input coordinates of capacity (x-axis) into piecewise and find corresponding line of CAPEX vs Capacity
			for i in 1:CO2_RES_ALL
	
				#Fill up first coordinate as zero
				Capacity_Interval_Size_i = RefCapacity_t_per_h[i]/(Intervals-2)
				CAPEX_Interval_Size_i = RefCAPEX_per_t_per_h_y[i]/(Intervals-2) #Irrelevant piece of code
				
				Capacity_Intervals[i,1] = 0
				CAPEX_Intervals[i,1] = 0
	
				#Fill up other intervals
				for k in 2:Intervals-1
					Capacity_Intervals[i,k] = Capacity_Intervals[i,k-1] + Capacity_Interval_Size_i
					CAPEX_Intervals[i,k] = RefCAPEX_per_t_per_h_y[i]*(Capacity_Intervals[i,k]/RefCapacity_t_per_h[i])^0.6
				end
			end
	
			#Write linear function to find plant Fixed OM from ref Capacity and ref Fixed OM
			#Not sure how to set infinity so we use a very large number which can be changed for example 100 MT/year approx = 10000 t/h
			#Find gradient of last segment
			DAC_CAPEX_Extrapolate_Gradient = zeros(CO2_RES_ALL)
	
			for i in 1:CO2_RES_ALL
				DAC_CAPEX_Extrapolate_Gradient[i] = (CAPEX_Intervals[i,Intervals-1] - CAPEX_Intervals[i,Intervals-2])/(Capacity_Intervals[i,Intervals-1] - Capacity_Intervals[i,Intervals-2])
			end
	
			#Extrapolate CAPEX as linear line to very large capacity limit after reference capacity of 1 MT/y
			DAC_CAPEX_Max_Limit = zeros(CO2_RES_ALL)
	
			for i in 1:CO2_RES_ALL
				DAC_CAPEX_Max_Limit[i] = CAPEX_Intervals[i,Intervals-1] + DAC_CAPEX_Extrapolate_Gradient[i] * (DAC_Capacity_Max_Limit[i] - Capacity_Intervals[i,Intervals-1])
				Capacity_Intervals[i,Intervals] = DAC_Capacity_Max_Limit[i]
				CAPEX_Intervals[i,Intervals] = DAC_CAPEX_Max_Limit[i]
			end
	
			#####################################################################################################################################
			##Variables
			#Model piecewise function for CAPEX
			@variable(EP,w_piecewise_DAC[i in 1:CO2_RES_ALL, k in 1:Intervals] >= 0 )
			@variable(EP,z_piecewise_DAC[i in 1:CO2_RES_ALL, k in 1:Intervals],Bin)
			@variable(EP,y_piecewise_DAC[i in 1:CO2_RES_ALL],Bin)
	
			#####################################################################################################################################
			##Constraints
	
			#Piecewise constriants
			@constraint(EP,cSum_z_piecewise_DAC[i in 1:CO2_RES_ALL], sum(EP[:z_piecewise_DAC][i,k] for k in 1:Intervals) == EP[:y_piecewise_DAC][i])
			@constraint(EP,cLeq_w_z_piecewise_DAC[i in 1:CO2_RES_ALL,k in 1:Intervals], EP[:w_piecewise_DAC][i,k] <= EP[:z_piecewise_DAC][i,k])
			@constraint(EP,cCAPEX_DAC_per_type[i in 1:CO2_RES_ALL], EP[:vCAPEX_DAC_per_type][i] == sum(EP[:z_piecewise_DAC][i,k]*CAPEX_Intervals[i,k] + EP[:w_piecewise_DAC][i,k]*(CAPEX_Intervals[i,k-1]-CAPEX_Intervals[i,k]) for k = 2:Intervals))
			@constraint(EP,cCapacity_DAC_per_type[i in 1:CO2_RES_ALL], EP[:vCapacity_DAC_per_type][i] == sum(EP[:z_piecewise_DAC][i,k]*Capacity_Intervals[i,k] + EP[:w_piecewise_DAC][i,k]*(Capacity_Intervals[i,k-1]-Capacity_Intervals[i,k]) for k = 2:Intervals))
	
			#Investment cost = CAPEX
			@expression(EP, eCAPEX_DAC_per_type[i in 1:CO2_RES_ALL], EP[:vCAPEX_DAC_per_type][i])
	
			#Fixed OM cost
			@expression(EP, eFixed_OM_DAC_per_type[i in 1:CO2_RES_ALL], EP[:vCapacity_DAC_per_type][i] * RefFixed_OM_per_t_per_h_y[i]/RefCapacity_t_per_h[i])
	
		else
			#Linear CAPEX using refcapex similar to fixed O&M cost calculation method
			#Investment cost = CAPEX
			#Consider using constraint for vCAPEX_DAC_per_type? Or expression is better
			@expression(EP, eCAPEX_DAC_per_type[i in 1:CO2_RES_ALL], EP[:vCapacity_DAC_per_type][i] * RefCAPEX_per_t_per_h_y[i]/RefCapacity_t_per_h[i])
	
			#Fixed OM cost
			@expression(EP, eFixed_OM_DAC_per_type[i in 1:CO2_RES_ALL], EP[:vCapacity_DAC_per_type][i] * RefFixed_OM_per_t_per_h_y[i]/RefCapacity_t_per_h[i])
		end
	
	elseif setup["CSC_Nonlinear_CAPEX"] == 0
		
		if setup["ParameterScale"] == 1
			DAC_Inv_Cost_per_tonne_per_hr_yr = dfCO2Capture[!,:Inv_Cost_per_tonne_per_hr_yr]/ModelScalingFactor # $M/kton
			DAC_Fixed_OM_Cost_per_tonne_per_hr_yr = dfCO2Capture[!,:Fixed_OM_Cost_per_tonne_per_hr_yr]/ModelScalingFactor # $M/kton
		else
			DAC_Inv_Cost_per_tonne_per_hr_yr = dfCO2Capture[!,:Inv_Cost_per_tonne_per_hr_yr]
			DAC_Fixed_OM_Cost_per_tonne_per_hr_yr = dfCO2Capture[!,:Fixed_OM_Cost_per_tonne_per_hr_yr]
		end
	
		#Investment cost = CAPEX
		@expression(EP, eCAPEX_DAC_per_type[i in 1:CO2_RES_ALL], EP[:vCapacity_DAC_per_type][i] * DAC_Inv_Cost_per_tonne_per_hr_yr[i])
	
		#Fixed OM cost
		@expression(EP, eFixed_OM_DAC_per_type[i in 1:CO2_RES_ALL], EP[:vCapacity_DAC_per_type][i] * DAC_Fixed_OM_Cost_per_tonne_per_hr_yr[i])
	
	end
	
	#####################################################################################################################################
	#Min and max capacity constraints
	@constraint(EP,cMinCapacity_per_unit[i in 1:CO2_RES_ALL], EP[:vCapacity_DAC_per_type][i] >= DAC_Capacity_Min_Limit[i])
	@constraint(EP,cMaxCapacity_per_unit[i in 1:CO2_RES_ALL], EP[:vCapacity_DAC_per_type][i] <= DAC_Capacity_Max_Limit[i])
	
	#####################################################################################################################################
	##Expressions
	#Cost per type of technology
	
	#Total fixed cost = CAPEX + Fixed OM
	@expression(EP, eFixed_Cost_DAC_per_type[i in 1:CO2_RES_ALL], EP[:eFixed_OM_DAC_per_type][i] + EP[:eCAPEX_DAC_per_type][i])
	
	#Total cost
	#Expression for total CAPEX for all resoruce types (For output and to add to objective function)
	@expression(EP,eCAPEX_DAC_total, sum(EP[:eCAPEX_DAC_per_type][i] for i in 1:CO2_RES_ALL))
	
	#Expression for total Fixed OM for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_OM_DAC_total, sum(EP[:eFixed_OM_DAC_per_type][i] for i in 1:CO2_RES_ALL))
	
	#Expression for total Fixed Cost for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_Cost_DAC_total, sum(EP[:eFixed_Cost_DAC_per_type][i] for i in 1:CO2_RES_ALL))
	
	EP[:eObj] += EP[:eFixed_Cost_DAC_total]

    return EP

end
