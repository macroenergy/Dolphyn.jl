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
    biorefinery_investment(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the built capacity and the total fixed cost (Investment + Fixed O&M) of biorefinery resource $k$.

"""
function biorefinery_investment(EP::Model, inputs::Dict, setup::Dict)
	
	println("Biorefinery Fixed Cost module")

	dfbiorefinery = inputs["dfbiorefinery"]
	BIO_RES_ALL = inputs["BIO_RES_ALL"]

	Z = inputs["Z"]
	T = inputs["T"]
	
	#General variables for non-piecewise and piecewise cost functions
	@variable(EP,vCapacity_BIO_per_type[i in 1:BIO_RES_ALL])
	@variable(EP,vCAPEX_BIO_per_type[i in 1:BIO_RES_ALL])

	if setup["ParameterScale"] == 1
		BIO_Capacity_Min_Limit = dfbiorefinery[!,:Min_capacity_tonne_per_hr]/ModelScalingFactor
		BIO_Capacity_Max_Limit = dfbiorefinery[!,:Max_capacity_tonne_per_hr]/ModelScalingFactor
	else
		BIO_Capacity_Min_Limit = dfbiorefinery[!,:Min_capacity_tonne_per_hr]
		BIO_Capacity_Max_Limit = dfbiorefinery[!,:Max_capacity_tonne_per_hr]
	end
	
	if setup["BIO_Nonlinear_CAPEX"] == 1

		#Exponent Terms
		sigma_1 = 1
		sigma_2 = 0.9
		sigma_3 = 0.8
		sigma_4 = 0.75
		sigma_5 = 0.72
		sigma_6 = 0.7
		sigma_7 = 0.65
		sigma_8 = 0.6
		sigma_9 = 0.5

		if setup["ParameterScale"] == 1
			##Load cost and capacity parameters
			Ref_CAPEX_per_yr_s1 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s1]/ModelScalingFactor^2 # $M
			Ref_CAPEX_per_yr_s2 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s2]/ModelScalingFactor^2
			Ref_CAPEX_per_yr_s3 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s3]/ModelScalingFactor^2
			Ref_CAPEX_per_yr_s4 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s4]/ModelScalingFactor^2
			Ref_CAPEX_per_yr_s5 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s5]/ModelScalingFactor^2
			Ref_CAPEX_per_yr_s6 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s6]/ModelScalingFactor^2
			Ref_CAPEX_per_yr_s7 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s7]/ModelScalingFactor^2
			Ref_CAPEX_per_yr_s8 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s8]/ModelScalingFactor^2
			Ref_CAPEX_per_yr_s9 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s9]/ModelScalingFactor^2
			Ref_Fixed_OM_per_yr = dfbiorefinery[!,:Ref_Fixed_OM_per_yr]/ModelScalingFactor^2

			Ref_capacity_tonne_per_hr = dfbiorefinery[!,:Ref_capacity_tonne_per_hr]/ModelScalingFactor # kt/h
		else
			Ref_CAPEX_per_yr_s1 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s1] # $
			Ref_CAPEX_per_yr_s2 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s2]
			Ref_CAPEX_per_yr_s3 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s3]
			Ref_CAPEX_per_yr_s4 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s4]
			Ref_CAPEX_per_yr_s5 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s5]
			Ref_CAPEX_per_yr_s6 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s6]
			Ref_CAPEX_per_yr_s7 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s7]
			Ref_CAPEX_per_yr_s8 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s8]
			Ref_CAPEX_per_yr_s9 = dfbiorefinery[!,:Ref_CAPEX_per_yr_s9]
			Ref_Fixed_OM_per_yr = dfbiorefinery[!,:Ref_Fixed_OM_per_yr]

			Ref_capacity_tonne_per_hr = dfbiorefinery[!,:Ref_capacity_tonne_per_hr] # t/h
		end
		
	
		if setup["BIO_CAPEX_Piecewise_Segments"] > 1
			#####################################################################################################################################
			##Piecewise Function for Investment Cost
			#Define steps for piecewise function
			Segments_BIO = setup["BIO_CAPEX_Piecewise_Segments"]
			Intervals_BIO = Segments_BIO + 1
			CAPEX_Intervals_BIO = zeros(BIO_RES_ALL,Intervals_BIO) #Parameter alpha
			Capacity_Intervals_BIO = zeros(BIO_RES_ALL,Intervals_BIO) #Parameter X
	
			#Input coordinates of capacity (x-axis) into piecewise and find corresponding line of CAPEX vs Capacity
			for i in 1:BIO_RES_ALL

				#Fill up first coordinate as zero
				Capacity_Interval_Size_i = Ref_capacity_tonne_per_hr[i]/(Intervals_BIO-2)
				
				Capacity_Intervals_BIO[i,1] = 0
				CAPEX_Intervals_BIO[i,1] = 0

				#Fill up other Intervals_BIO
				for k in 2:Intervals_BIO-1
					Capacity_Intervals_BIO[i,k] = Capacity_Intervals_BIO[i,k-1] + Capacity_Interval_Size_i
					CAPEX_Intervals_BIO[i,k] = (Ref_CAPEX_per_yr_s1[i]*(Capacity_Intervals_BIO[i,k]/Ref_capacity_tonne_per_hr[i])^sigma_1
											+ Ref_CAPEX_per_yr_s2[i]*(Capacity_Intervals_BIO[i,k]/Ref_capacity_tonne_per_hr[i])^sigma_2
											+ Ref_CAPEX_per_yr_s3[i]*(Capacity_Intervals_BIO[i,k]/Ref_capacity_tonne_per_hr[i])^sigma_3
											+ Ref_CAPEX_per_yr_s4[i]*(Capacity_Intervals_BIO[i,k]/Ref_capacity_tonne_per_hr[i])^sigma_4
											+ Ref_CAPEX_per_yr_s5[i]*(Capacity_Intervals_BIO[i,k]/Ref_capacity_tonne_per_hr[i])^sigma_5
											+ Ref_CAPEX_per_yr_s6[i]*(Capacity_Intervals_BIO[i,k]/Ref_capacity_tonne_per_hr[i])^sigma_6
											+ Ref_CAPEX_per_yr_s7[i]*(Capacity_Intervals_BIO[i,k]/Ref_capacity_tonne_per_hr[i])^sigma_7
											+ Ref_CAPEX_per_yr_s8[i]*(Capacity_Intervals_BIO[i,k]/Ref_capacity_tonne_per_hr[i])^sigma_8
											+ Ref_CAPEX_per_yr_s9[i]*(Capacity_Intervals_BIO[i,k]/Ref_capacity_tonne_per_hr[i])^sigma_9)
				end 
			end

			#Write linear function to find plant Fixed OM from ref Capacity and ref Fixed OM
			#Not sure how to set infinity so we use a very large number which can be changed for example 100 MT/year approx = 10000 t/h
			#Find gradient of last segment
			BIO_CAPEX_Extrapolate_Gradient = zeros(BIO_RES_ALL)

			for i in 1:BIO_RES_ALL
				BIO_CAPEX_Extrapolate_Gradient[i] = (CAPEX_Intervals_BIO[i,Intervals_BIO-1] - CAPEX_Intervals_BIO[i,Intervals_BIO-2])/(Capacity_Intervals_BIO[i,Intervals_BIO-1] - Capacity_Intervals_BIO[i,Intervals_BIO-2])
			end

			#Extrapolate CAPEX as linear line to very large capacity limit after reference capacity
			BIO_CAPEX_Max_Limit = zeros(BIO_RES_ALL)

			for i in 1:BIO_RES_ALL
				BIO_CAPEX_Max_Limit[i] = CAPEX_Intervals_BIO[i,Intervals_BIO-1] + BIO_CAPEX_Extrapolate_Gradient[i] * (BIO_Capacity_Max_Limit[i] - Capacity_Intervals_BIO[i,Intervals_BIO-1])
				Capacity_Intervals_BIO[i,Intervals_BIO] = BIO_Capacity_Max_Limit[i]
				CAPEX_Intervals_BIO[i,Intervals_BIO] = BIO_CAPEX_Max_Limit[i]
			end

		##############################################################################################################################################
			##Variables
			#Model piecewise function for CAPEX
			@variable(EP,w_piecewise_BIO[i in 1:BIO_RES_ALL, k in 1:Intervals_BIO] >= 0 )
			@variable(EP,z_piecewise_BIO[i in 1:BIO_RES_ALL, k in 1:Intervals_BIO],Bin)
			@variable(EP,y_piecewise_BIO[i in 1:BIO_RES_ALL],Bin)

		##############################################################################################################################################
			##Constraints

			#Piecewise constriants
			@constraint(EP,cSum_z_piecewise_BIO[i in 1:BIO_RES_ALL], sum(EP[:z_piecewise_BIO][i,k] for k in 1:Intervals_BIO) == EP[:y_piecewise_BIO][i])
			@constraint(EP,cLeq_w_z_piecewise_BIO[i in 1:BIO_RES_ALL,k in 1:Intervals_BIO], EP[:w_piecewise_BIO][i,k] <= EP[:z_piecewise_BIO][i,k])
			@constraint(EP,cCAPEX_BIO_per_type[i in 1:BIO_RES_ALL], EP[:vCAPEX_BIO_per_type][i] == sum(EP[:z_piecewise_BIO][i,k]*CAPEX_Intervals_BIO[i,k] + EP[:w_piecewise_BIO][i,k]*(CAPEX_Intervals_BIO[i,k-1]-CAPEX_Intervals_BIO[i,k]) for k = 2:Intervals_BIO))
			@constraint(EP,cCapacity_BIO_per_type[i in 1:BIO_RES_ALL], EP[:vCapacity_BIO_per_type][i] == sum(EP[:z_piecewise_BIO][i,k]*Capacity_Intervals_BIO[i,k] + EP[:w_piecewise_BIO][i,k]*(Capacity_Intervals_BIO[i,k-1]-Capacity_Intervals_BIO[i,k]) for k = 2:Intervals_BIO))

			#Investment cost = CAPEX
			@expression(EP, eCAPEX_BIO_per_type[i in 1:BIO_RES_ALL], EP[:vCAPEX_BIO_per_type][i])

		else
			Ref_CAPEX_per_yr = zeros(BIO_RES_ALL)

			for i in 1:BIO_RES_ALL
				Ref_CAPEX_per_yr[i] = (Ref_CAPEX_per_yr_s1[i]
				+ Ref_CAPEX_per_yr_s2[i]
				+ Ref_CAPEX_per_yr_s3[i]
				+ Ref_CAPEX_per_yr_s4[i]
				+ Ref_CAPEX_per_yr_s5[i]
				+ Ref_CAPEX_per_yr_s6[i]
				+ Ref_CAPEX_per_yr_s7[i]
				+ Ref_CAPEX_per_yr_s8[i]
				+ Ref_CAPEX_per_yr_s9[i])
			end

			@expression(EP, eCAPEX_BIO_per_type[i in 1:BIO_RES_ALL], EP[:vCapacity_BIO_per_type][i] * Ref_CAPEX_per_yr[i]/Ref_capacity_tonne_per_hr[i])

		end

		#Fixed OM cost
		@expression(EP, eFixed_OM_BIO_per_type[i in 1:BIO_RES_ALL], EP[:vCapacity_BIO_per_type][i] * Ref_Fixed_OM_per_yr[i]/Ref_capacity_tonne_per_hr[i])

	
	elseif setup["BIO_Nonlinear_CAPEX"] == 0
		
		if setup["ParameterScale"] == 1
			BIO_Inv_Cost_per_tonne_per_hr_yr = dfbiorefinery[!,:Inv_Cost_per_tonne_per_hr_yr]/ModelScalingFactor # $M/kton
			BIO_Fixed_OM_Cost_per_tonne_per_hr_yr = dfbiorefinery[!,:Fixed_OM_Cost_per_tonne_per_hr_yr]/ModelScalingFactor # $M/kton
		else
			BIO_Inv_Cost_per_tonne_per_hr_yr = dfbiorefinery[!,:Inv_Cost_per_tonne_per_hr_yr]
			BIO_Fixed_OM_Cost_per_tonne_per_hr_yr = dfbiorefinery[!,:Fixed_OM_Cost_per_tonne_per_hr_yr]
		end
	
		#Investment cost = CAPEX
		@expression(EP, eCAPEX_BIO_per_type[i in 1:BIO_RES_ALL], EP[:vCapacity_BIO_per_type][i] * BIO_Inv_Cost_per_tonne_per_hr_yr[i])
    
		#Fixed OM cost
		@expression(EP, eFixed_OM_BIO_per_type[i in 1:BIO_RES_ALL], EP[:vCapacity_BIO_per_type][i] * BIO_Fixed_OM_Cost_per_tonne_per_hr_yr[i])

	end
	
	#Min and max capacity constraints
	@constraint(EP,cMinCapacity_per_unit_BIO[i in 1:BIO_RES_ALL], EP[:vCapacity_BIO_per_type][i] >= BIO_Capacity_Min_Limit[i])
	@constraint(EP,cMaxCapacity_per_unit_BIO[i in 1:BIO_RES_ALL], EP[:vCapacity_BIO_per_type][i] <= BIO_Capacity_Max_Limit[i])

	#Total fixed cost = CAPEX + Fixed OM
	@expression(EP, eFixed_Cost_BIO_per_type[i in 1:BIO_RES_ALL], EP[:eFixed_OM_BIO_per_type][i] + EP[:eCAPEX_BIO_per_type][i])

	#Total fixed cost
	@expression(EP, eFixed_Cost_BIO, sum(EP[:eFixed_Cost_BIO_per_type][i] for i in 1:BIO_RES_ALL))

	#Total cost
	#Expression for total CAPEX for all resoruce types (For output and to add to objective function)
	@expression(EP,eCAPEX_BIO_total, sum(EP[:eCAPEX_BIO_per_type][i] for i in 1:BIO_RES_ALL))

	#Expression for total Fixed OM for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_OM_BIO_total, sum(EP[:eFixed_OM_BIO_per_type][i] for i in 1:BIO_RES_ALL))

	#Expression for total Fixed Cost for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_Cost_BIO_total, sum(EP[:eFixed_Cost_BIO_per_type][i] for i in 1:BIO_RES_ALL))

	EP[:eObj] += EP[:eFixed_Cost_BIO_total]

    return EP

end
