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
    bio_wood_supply(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the amount of bio wood supplies used into the network by zone $z$ by at time period $t, along with the cost and CO2 emissions associated with it.
"""

function bio_wood_supply(EP::Model, inputs::Dict, setup::Dict)

	println("Bioenergy woody biomass supply cost module")

	#Define sets
	T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Zones

	#Variables
	@variable(EP,vWood_biomass_utilized_per_zone_per_time[z in 1:Z, t in 1:T] >= 0)
	@variable(EP,vWood_biomass_supply_cost_per_zone_per_time[z in 1:Z, t in 1:T] >= 0)

	if setup["BIO_Nonlinear_Supply"] == 1

		if setup["ParameterScale"] ==1
			Wood_biomass_quantity_per_h = inputs["Wood_biomass_quantity_per_h"]/ModelScalingFactor #Convert to ktonne
			Wood_biomass_cost_per_h = inputs["Wood_biomass_cost_per_h"]/ModelScalingFactor^2 #Convert to $M
			Wood_biomass_emission_per_h = inputs["Wood_biomass_emission_per_h"]/ModelScalingFactor #Convert to ktonne
		else
			Wood_biomass_quantity_per_h = inputs["Wood_biomass_quantity_per_h"] 
			Wood_biomass_cost_per_h = inputs["Wood_biomass_cost_per_h"]
			Wood_biomass_emission_per_h = inputs["Wood_biomass_emission_per_h"] #Convert to ktonne
		end

		if setup["BIO_Supply_Piecewise_Segments"] > 1
			#Create array for piecwise lines representing the supply curve for each region
			Wood_segments_biomass = setup["BIO_Supply_Piecewise_Segments"]
			Wood_intervals_biomass = Wood_segments_biomass + 1
			Wood_biomass_cost_per_h_piecewise = zeros(Z,Wood_intervals_biomass)
			Wood_biomass_quantity_per_h_piecewise = zeros(Z,Wood_intervals_biomass)
			Wood_biomass_emission_per_h_piecewise = zeros(Z,Wood_intervals_biomass)
			Wood_index_interval_track = zeros(Z,Wood_intervals_biomass)
			Wood_biomass_Supply_Max = zeros(Z)

			for z = 1:Z
				#Fill up first and end point of the arrays
				#Unlike CAPEX piecewise function, we do not extrapolate as there are limited availability of biomass
				#Max amount of biomass will be the end point of the supply curve

				Wood_biomass_quantity_zone_per_h = collect(skipmissing(Wood_biomass_quantity_per_h[:,z]))
				Wood_biomass_cost_zone_per_h = collect(skipmissing(Wood_biomass_cost_per_h[:,z]))
				Wood_biomass_emission_zone_per_h = collect(skipmissing(Wood_biomass_emission_per_h[:,z]))
				Wood_datapoints = size(Wood_biomass_cost_zone_per_h,1)

				Wood_biomass_quantity_per_h_piecewise[z,1] = 0
				Wood_biomass_cost_per_h_piecewise[z,1] = 0
				Wood_biomass_emission_per_h_piecewise[z,1] = 0
				Wood_index_interval_track[z,1] = 0

				Wood_biomass_quantity_per_h_piecewise[z,end] = Wood_biomass_quantity_zone_per_h[end]
				Wood_biomass_cost_per_h_piecewise[z,end] = Wood_biomass_cost_zone_per_h[end]
				Wood_biomass_emission_per_h_piecewise[z,end] = Wood_biomass_emission_zone_per_h[end]
				Wood_index_interval_track[z,end] = Wood_datapoints

				#Fill up other intervals of piecewise lines
				#Find the index of positions of intersect
				Wood_index_interval = Int(floor(Wood_datapoints/(Wood_segments_biomass)))

				for i in 2:Wood_intervals_biomass-1
					Wood_current_index = Wood_index_interval*(i-1)
					Wood_biomass_cost_per_h_piecewise[z,i] = Wood_biomass_cost_zone_per_h[Wood_current_index]
					Wood_biomass_quantity_per_h_piecewise[z,i] = Wood_biomass_quantity_zone_per_h[Wood_current_index]
					Wood_biomass_emission_per_h_piecewise[z,i] = Wood_biomass_emission_zone_per_h[Wood_current_index]
					Wood_index_interval_track[z,i] = Wood_current_index
				end

				Wood_biomass_Supply_Max[z] = Wood_biomass_quantity_zone_per_h[end]
			end

			#####################################################################################################################################

			#Model piecewise function for biomass supply curve
			@variable(EP,w_piecewise_Wood_biomass[z in 1:Z, k in 1:Wood_intervals_biomass, t in 1:T] >= 0 )
			@variable(EP,z_piecewise_Wood_biomass[z in 1:Z, k in 1:Wood_intervals_biomass, t in 1:T],Bin)
			@variable(EP,y_piecewise_Wood_biomass[z in 1:Z, t in 1:T],Bin)

			##Constraints

			#Piecewise constriants for Cost
			@constraint(EP,cSum_z_piecewise_Wood_biomass[z in 1:Z, t in 1:T], sum(EP[:z_piecewise_Wood_biomass][z,k,t] for k in 1:Wood_intervals_biomass) == EP[:y_piecewise_Wood_biomass][z,t])
			@constraint(EP,cLeq_w_z_piecewise_Wood_biomass[z in 1:Z, k in 1:Wood_intervals_biomass, t in 1:T], EP[:w_piecewise_Wood_biomass][z,k,t] <= EP[:z_piecewise_Wood_biomass][z,k,t])
			@constraint(EP,cWood_biomass_cost_per_zone[z in 1:Z, t in 1:T], EP[:vWood_biomass_supply_cost_per_zone_per_time][z,t] == sum(EP[:z_piecewise_Wood_biomass][z,k,t]*Wood_biomass_cost_per_h_piecewise[z,k] + EP[:w_piecewise_Wood_biomass][z,k,t]*(Wood_biomass_cost_per_h_piecewise[z,k-1]-Wood_biomass_cost_per_h_piecewise[z,k]) for k = 2:Wood_intervals_biomass))
			@constraint(EP,cWood_biomass_utilized_per_zone[z in 1:Z, t in 1:T], EP[:vWood_biomass_utilized_per_zone_per_time][z,t] == sum(EP[:z_piecewise_Wood_biomass][z,k,t]*Wood_biomass_quantity_per_h_piecewise[z,k] + EP[:w_piecewise_Wood_biomass][z,k,t]*(Wood_biomass_quantity_per_h_piecewise[z,k-1]-Wood_biomass_quantity_per_h_piecewise[z,k]) for k = 2:Wood_intervals_biomass))
			
			#Wood_biomass supply cost per zone per time
			#Add to Obj, need to account for time weight omega
			@expression(EP, eWood_biomass_supply_cost_per_zone_per_time[z in 1:Z, t in 1:T], inputs["omega"][t] * EP[:vWood_biomass_supply_cost_per_zone_per_time][z,t])
			
			#Wood_biomass emissions per zone per time
			@expression(EP,eWood_biomass_emission_per_zone_per_time[z in 1:Z, t in 1:T], sum(EP[:z_piecewise_Wood_biomass][z,k,t]*Wood_biomass_emission_per_h_piecewise[z,k] + EP[:w_piecewise_Wood_biomass][z,k,t]*(Wood_biomass_emission_per_h_piecewise[z,k-1]-Wood_biomass_emission_per_h_piecewise[z,k]) for k = 2:Wood_intervals_biomass))

			#Output without time weight to show hourly cost
			@expression(EP, eWood_biomass_supply_cost_per_zone_per_time_output[z in 1:Z, t in 1:T], EP[:vWood_biomass_supply_cost_per_zone_per_time][z,t])

		else

			Wood_biomass_Supply_Max = zeros(Z)
			Wood_biomass_Cost_Max = zeros(Z)
			Wood_biomass_Emission_Max = zeros(Z)

			for z = 1:Z
				Wood_biomass_quantity_zone_per_h = collect(skipmissing(Wood_biomass_quantity_per_h[:,z]))
				Wood_biomass_cost_zone_per_h = collect(skipmissing(Wood_biomass_cost_per_h[:,z]))
				Wood_biomass_emission_zone_per_h = collect(skipmissing(Wood_biomass_emission_per_h[:,z]))

				Wood_biomass_Supply_Max[z] = Wood_biomass_quantity_zone_per_h[end]
				Wood_biomass_Cost_Max[z] = Wood_biomass_cost_zone_per_h[end]
				Wood_biomass_Emission_Max[z] = Wood_biomass_emission_zone_per_h[end]
			end

			Wood_biomass_cost_per_tonne = Wood_biomass_Cost_Max./Wood_biomass_Supply_Max
			Wood_biomass_emission_per_tonne = Wood_biomass_Emission_Max./Wood_biomass_Supply_Max

			#Add to Obj, need to account for time weight omega
			@expression(EP, eWood_biomass_supply_cost_per_zone_per_time[z in 1:Z, t in 1:T], inputs["omega"][t] * EP[:vWood_biomass_utilized_per_zone_per_time][z,t] * Wood_biomass_cost_per_tonne[z])
			@expression(EP, eWood_biomass_emission_per_zone_per_time[z in 1:Z, t in 1:T], EP[:vWood_biomass_utilized_per_zone_per_time][z,t] * Wood_biomass_emission_per_tonne[z])

			#Output without time weight to show hourly cost
			@expression(EP, eWood_biomass_supply_cost_per_zone_per_time_output[z in 1:Z, t in 1:T], EP[:vWood_biomass_utilized_per_zone_per_time][z,t] * Wood_biomass_cost_per_tonne[z])
		end

	elseif setup["BIO_Nonlinear_Supply"] == 0

		Wood_biomass_supply_df = inputs["Wood_biomass_supply_df"]

		if setup["ParameterScale"] ==1
			Wood_biomass_Supply_Max = Wood_biomass_supply_df[!,:Max_tonne_per_hr]/ModelScalingFactor #Convert to ktonne
			Wood_biomass_cost_per_tonne = Wood_biomass_supply_df[!,:Cost_per_tonne_per_hr]/ModelScalingFactor #Convert to $M/ktonne
			Wood_biomass_emission_per_tonne = Wood_biomass_supply_df[!,:Emissions_tonne_per_tonne] #Convert to ktonne/ktonne = tonne/tonne
		else
			Wood_biomass_Supply_Max = Wood_biomass_supply_df[!,:Max_tonne_per_hr]
			Wood_biomass_cost_per_tonne = Wood_biomass_supply_df[!,:Cost_per_tonne_per_hr]
			Wood_biomass_emission_per_tonne = Wood_biomass_supply_df[!,:Emissions_tonne_per_tonne]
		end

		#Add to Obj, need to account for time weight omega
		@expression(EP, eWood_biomass_supply_cost_per_zone_per_time[z in 1:Z, t in 1:T], inputs["omega"][t] * EP[:vWood_biomass_utilized_per_zone_per_time][z,t] * Wood_biomass_cost_per_tonne[z])
		@expression(EP, eWood_biomass_emission_per_zone_per_time[z in 1:Z, t in 1:T], EP[:vWood_biomass_utilized_per_zone_per_time][z,t] * Wood_biomass_emission_per_tonne[z])

		#Output without time weight to show hourly cost
		@expression(EP, eWood_biomass_supply_cost_per_zone_per_time_output[z in 1:Z, t in 1:T], EP[:vWood_biomass_utilized_per_zone_per_time][z,t] * Wood_biomass_cost_per_tonne[z])

	end

	#Total biomass supply cost per zone
	@expression(EP, eWood_biomass_supply_cost_per_zone[z in 1:Z], sum(EP[:eWood_biomass_supply_cost_per_zone_per_time][z,t] for t in 1:T))

	#Total biomass supply cost
	@expression(EP, eWood_biomass_supply_cost, sum(EP[:eWood_biomass_supply_cost_per_zone][z] for z in 1:Z))

	#Max biomass supply constraint
	@constraint(EP,cWood_biomass_Max[z in 1:Z, t in 1:T], EP[:vWood_biomass_utilized_per_zone_per_time][z,t] <= Wood_biomass_Supply_Max[z])

	EP[:eObj] += EP[:eWood_biomass_supply_cost]

	return EP

end
