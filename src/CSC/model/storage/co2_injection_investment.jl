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
    co2_injection_investment(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the total fixed cost (Investment + Fixed O&M) of injecting CO2 inside the geological sequestration storage

"""
function co2_injection_investment(EP::Model, inputs::Dict, setup::Dict)
	#Model the capacity and cost of injecting the CO2 into geological storage, ignore the cost of the geological storage itself as assume it is naturally ocurring and very large so no limit to how much can be stored

	println("Carbon Storage Injection Cost module")

    dfCO2Storage = inputs["dfCO2Storage"]
	CO2_STOR_ALL = inputs["CO2_STOR_ALL"]

	Z = inputs["Z"]
	T = inputs["T"]
	
	#General variables for non-piecewise and piecewise cost functions
	@variable(EP,vCapacity_CO2_Injection_per_type[i in 1:CO2_STOR_ALL])
	@variable(EP,vCAPEX_CO2_Injection_per_type[i in 1:CO2_STOR_ALL])

	if setup["ParameterScale"] == 1
		CO2_Injection_Capacity_Min_Limit = dfCO2Storage[!,:Min_capacity_tonne_per_yr]/ModelScalingFactor # kt/h
		CO2_Injection_Capacity_Max_Limit = dfCO2Storage[!,:Max_capacity_tonne_per_yr]/ModelScalingFactor # kt/h
	else
		CO2_Injection_Capacity_Min_Limit = dfCO2Storage[!,:Min_capacity_tonne_per_yr] # t/h
		CO2_Injection_Capacity_Max_Limit = dfCO2Storage[!,:Max_capacity_tonne_per_yr] # t/h
	end

	if setup["CSC_Nonlinear_CAPEX"] == 1

		##Load cost and capacity parameters
		#  ParameterScale = 1 --> objective function is in million $ . 
		# In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
		#  ParameterScale = 0 --> objective function is in $
		
		if setup["ParameterScale"] ==1 
			RefCAPEX_per_t_per_h_y = dfCO2Storage[!,:Ref_CAPEX_per_yr]/ModelScalingFactor^2 # $M
			RefFixed_OM_per_t_per_h_y = dfCO2Storage[!,:Ref_Fixed_OM_per_yr]/ModelScalingFactor^2 # $M
			RefCapacity_t_per_h = dfCO2Storage[!,:Ref_capacity_tonne_per_yr]/ModelScalingFactor # kt/h
		else
			RefCAPEX_per_t_per_h_y = dfCO2Storage[!,:Ref_CAPEX_per_yr] # $
			RefFixed_OM_per_t_per_h_y = dfCO2Storage[!,:Ref_Fixed_OM_per_yr] # $
			RefCapacity_t_per_h = dfCO2Storage[!,:Ref_capacity_tonne_per_yr] # t/h
		end

		if setup["CO2_Injection_CAPEX_Piecewise_Segments"] > 1 
			#####################################################################################################################################
			##Piecewise Function for Investment Cost
			#Define steps for piecewise function
			Segments = setup["CO2_Injection_CAPEX_Piecewise_Segments"]
			Intervals = Segments + 1
			CAPEX_Intervals = zeros(CO2_STOR_ALL,Intervals) #Parameter alpha
			Capacity_Intervals = zeros(CO2_STOR_ALL,Intervals) #Parameter X
	
			#Input coordinates of capacity (x-axis) into piecewise and find corresponding line of CAPEX vs Capacity
			for i in 1:CO2_STOR_ALL
	
				#Fill up first coordinate as zero
				Capacity_Interval_Size_i = RefCapacity_t_per_h[i]/(Intervals-2)
				CAPEX_Interval_Size_i = RefCAPEX_per_t_per_h_y[i]/(Intervals-2)
				
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
			CO2_Injection_CAPEX_Extrapolate_Gradient = zeros(CO2_STOR_ALL)
	
			for i in 1:CO2_STOR_ALL
				CO2_Injection_CAPEX_Extrapolate_Gradient[i] = (CAPEX_Intervals[i,Intervals-1] - CAPEX_Intervals[i,Intervals-2])/(Capacity_Intervals[i,Intervals-1] - Capacity_Intervals[i,Intervals-2])
			end
	
			#Extrapolate CAPEX as linear line to very large capacity limit after reference capacity of 1 MT/y
			CO2_Injection_CAPEX_Max_Limit = zeros(CO2_STOR_ALL)
	
			for i in 1:CO2_STOR_ALL
				CO2_Injection_CAPEX_Max_Limit[i] = CAPEX_Intervals[i,Intervals-1] + CO2_Injection_CAPEX_Extrapolate_Gradient[i] * (CO2_Injection_Capacity_Max_Limit[i] - Capacity_Intervals[i,Intervals-1])
				Capacity_Intervals[i,Intervals] = CO2_Injection_Capacity_Max_Limit[i]
				CAPEX_Intervals[i,Intervals] = CO2_Injection_CAPEX_Max_Limit[i]
			end
	
			#####################################################################################################################################
			##Variables
			#Model piecewise function for CAPEX
			@variable(EP,w_piecewise_CO2_Injection[i in 1:CO2_STOR_ALL, k in 1:Intervals] >= 0 )
			@variable(EP,z_piecewise_CO2_Injection[i in 1:CO2_STOR_ALL, k in 1:Intervals],Bin)
			@variable(EP,y_piecewise_CO2_Injection[i in 1:CO2_STOR_ALL],Bin)
	
			#####################################################################################################################################
			##Constraints
	
			#Piecewise constriants
			@constraint(EP,cSum_z_piecewise_CO2_Injection[i in 1:CO2_STOR_ALL], sum(EP[:z_piecewise_CO2_Injection][i,k] for k in 1:Intervals) == EP[:y_piecewise_CO2_Injection][i])
			@constraint(EP,cLeq_w_z_piecewise_CO2_Injection[i in 1:CO2_STOR_ALL,k in 1:Intervals], EP[:w_piecewise_CO2_Injection][i,k] <= EP[:z_piecewise_CO2_Injection][i,k])
			@constraint(EP,cCAPEX_CO2_Injection_per_type[i in 1:CO2_STOR_ALL], EP[:vCAPEX_CO2_Injection_per_type][i] == sum(EP[:z_piecewise_CO2_Injection][i,k]*CAPEX_Intervals[i,k] + EP[:w_piecewise_CO2_Injection][i,k]*(CAPEX_Intervals[i,k-1]-CAPEX_Intervals[i,k]) for k = 2:Intervals))
			@constraint(EP,cCapacity_CO2_Injection_per_type[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Injection_per_type][i] == sum(EP[:z_piecewise_CO2_Injection][i,k]*Capacity_Intervals[i,k] + EP[:w_piecewise_CO2_Injection][i,k]*(Capacity_Intervals[i,k-1]-Capacity_Intervals[i,k]) for k = 2:Intervals))
	
			#Investment cost = CAPEX
			@expression(EP, eCAPEX_CO2_Injection_per_type[i in 1:CO2_STOR_ALL], EP[:vCAPEX_CO2_Injection_per_type][i])
	
			#Fixed OM cost #Check again to match capacity
			@expression(EP, eFixed_OM_CO2_Injection_per_type[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Injection_per_type][i] * RefFixed_OM_per_t_per_h_y[i]/RefCapacity_t_per_h[i])
		else
			#Linear CAPEX using refcapex similar to fixed O&M cost calculation method
			#Investment cost = CAPEX
			#Consider using constraint for vCAPEX_CO2_Injection_per_type? Or expression is better
			@expression(EP, eCAPEX_CO2_Injection_per_type[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Injection_per_type][i] * RefCAPEX_per_t_per_h_y[i]/RefCapacity_t_per_h[i])
		   
			#Fixed OM cost #Check again to match capacity
			@expression(EP, eFixed_OM_CO2_Injection_per_type[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Injection_per_type][i] * RefFixed_OM_per_t_per_h_y[i]/RefCapacity_t_per_h[i])
	
		end
	
	elseif setup["CSC_Nonlinear_CAPEX"] == 0
	
		if setup["ParameterScale"] ==1 
			CO2_Capture_Stor_Inv_Cost_per_tonne_per_yr_yr = dfCO2Storage[!,:Inv_Cost_per_tonne_per_yr_yr]/ModelScalingFactor # $M/kton
			CO2_Capture_Stor_Fixed_OM_Cost_per_tonne_per_yr_yr = dfCO2Storage[!,:Fixed_OM_Cost_per_tonne_per_yr_yr]/ModelScalingFactor # $M/kton
		else
			CO2_Capture_Stor_Inv_Cost_per_tonne_per_yr_yr = dfCO2Storage[!,:Inv_Cost_per_tonne_per_yr_yr]
			CO2_Capture_Stor_Fixed_OM_Cost_per_tonne_per_yr_yr = dfCO2Storage[!,:Fixed_OM_Cost_per_tonne_per_yr_yr]
		end
	
		#Linear CAPEX using refcapex similar to fixed O&M cost calculation method
		#Consider using constraint for vCAPEX_CO2_Injection_per_type? Or expression is better
		@expression(EP, eCAPEX_CO2_Injection_per_type[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Injection_per_type][i] * CO2_Capture_Stor_Inv_Cost_per_tonne_per_yr_yr[i])
		
		#Fixed OM cost #Check again to match capacity
		@expression(EP, eFixed_OM_CO2_Injection_per_type[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Injection_per_type][i] * CO2_Capture_Stor_Fixed_OM_Cost_per_tonne_per_yr_yr[i])
	
	end
	
	#####################################################################################################################################
	#Min and max capacity constraints
	@constraint(EP,cMinCapacity_CO2_Injection_per_unit[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Injection_per_type][i] >= CO2_Injection_Capacity_Min_Limit[i])
	@constraint(EP,cMaxCapacity_CO2_Injection_per_unit[i in 1:CO2_STOR_ALL], EP[:vCapacity_CO2_Injection_per_type][i] <= CO2_Injection_Capacity_Max_Limit[i])
	
	#####################################################################################################################################
	##Expressions
	#Cost per type of technology
	
	
	#Total fixed cost = CAPEX + Fixed OM
	@expression(EP, eFixed_Cost_CO2_Injection_per_type[i in 1:CO2_STOR_ALL], EP[:eFixed_OM_CO2_Injection_per_type][i] + EP[:eCAPEX_CO2_Injection_per_type][i])
	
	#Total cost
	#Expression for total CAPEX for all resoruce types (For output and to add to objective function)
	@expression(EP,eCAPEX_CO2_Injection_total, sum(EP[:eCAPEX_CO2_Injection_per_type][i] for i in 1:CO2_STOR_ALL))
	
	#Expression for total Fixed OM for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_OM_CO2_Injection_total, sum(EP[:eFixed_OM_CO2_Injection_per_type][i] for i in 1:CO2_STOR_ALL))
	
	#Expression for total Fixed Cost for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_Cost_CO2_Injection_total, sum(EP[:eFixed_Cost_CO2_Injection_per_type][i] for i in 1:CO2_STOR_ALL))
	
	# Add term to objective function expression
	EP[:eObj] += EP[:eFixed_Cost_CO2_Injection_total]

    return EP

end
