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
    bio_herb_supply(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the amount of bio herb supplies used into the network by zone $z$ by at time period $t, along with the cost and CO2 emissions associated with it.
"""

function bio_herb_supply(EP::Model, inputs::Dict, setup::Dict)

	println("Bioenergy herbaceous biomass supply cost module")

	#Define sets
	T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Zones

	#Variables
	@variable(EP,vHerb_biomass_utilized_per_zone_per_time[z in 1:Z, t in 1:T] >= 0)
	@variable(EP,vHerb_biomass_supply_cost_per_zone_per_time[z in 1:Z, t in 1:T] >= 0)

	if setup["BIO_Nonlinear_Supply"] == 1

		if setup["ParameterScale"] ==1
			Herb_biomass_quantity_per_h = inputs["Herb_biomass_quantity_per_h"]/ModelScalingFactor #Convert to ktonne
			Herb_biomass_cost_per_h = inputs["Herb_biomass_cost_per_h"]/ModelScalingFactor^2 #Convert to $M
			Herb_biomass_emission_per_h = inputs["Herb_biomass_emission_per_h"]/ModelScalingFactor #Convert to ktonne
		else
			Herb_biomass_quantity_per_h = inputs["Herb_biomass_quantity_per_h"] 
			Herb_biomass_cost_per_h = inputs["Herb_biomass_cost_per_h"]
			Herb_biomass_emission_per_h = inputs["Herb_biomass_emission_per_h"] #Convert to ktonne
		end

		if setup["BIO_Supply_Piecewise_Segments"] > 1
			#Create array for piecwise lines representing the supply curve for each region
			Herb_segments_biomass = setup["BIO_Supply_Piecewise_Segments"]
			Herb_intervals_biomass = Herb_segments_biomass + 1
			Herb_biomass_cost_per_h_piecewise = zeros(Z,Herb_intervals_biomass)
			Herb_biomass_quantity_per_h_piecewise = zeros(Z,Herb_intervals_biomass)
			Herb_biomass_emission_per_h_piecewise = zeros(Z,Herb_intervals_biomass)
			Herb_index_interval_track = zeros(Z,Herb_intervals_biomass)
			Herb_biomass_Supply_Max = zeros(Z)

			for z = 1:Z
				#Fill up first and end point of the arrays
				#Unlike CAPEX piecewise function, we do not extrapolate as there are limited availability of biomass
				#Max amount of biomass will be the end point of the supply curve

				Herb_biomass_quantity_zone_per_h = collect(skipmissing(Herb_biomass_quantity_per_h[:,z]))
				Herb_biomass_cost_zone_per_h = collect(skipmissing(Herb_biomass_cost_per_h[:,z]))
				Herb_biomass_emission_zone_per_h = collect(skipmissing(Herb_biomass_emission_per_h[:,z]))
				Herb_datapoints = size(Herb_biomass_cost_zone_per_h,1)

				Herb_biomass_quantity_per_h_piecewise[z,1] = 0
				Herb_biomass_cost_per_h_piecewise[z,1] = 0
				Herb_biomass_emission_per_h_piecewise[z,1] = 0
				Herb_index_interval_track[z,1] = 0

				Herb_biomass_quantity_per_h_piecewise[z,end] = Herb_biomass_quantity_zone_per_h[end]
				Herb_biomass_cost_per_h_piecewise[z,end] = Herb_biomass_cost_zone_per_h[end]
				Herb_biomass_emission_per_h_piecewise[z,end] = Herb_biomass_emission_zone_per_h[end]
				Herb_index_interval_track[z,end] = Herb_datapoints

				#Fill up other intervals of piecewise lines
				#Find the index of positions of intersect
				Herb_index_interval = Int(floor(Herb_datapoints/(Herb_segments_biomass)))

				for i in 2:Herb_intervals_biomass-1
					Herb_current_index = Herb_index_interval*(i-1)
					Herb_biomass_cost_per_h_piecewise[z,i] = Herb_biomass_cost_zone_per_h[Herb_current_index]
					Herb_biomass_quantity_per_h_piecewise[z,i] = Herb_biomass_quantity_zone_per_h[Herb_current_index]
					Herb_biomass_emission_per_h_piecewise[z,i] = Herb_biomass_emission_zone_per_h[Herb_current_index]
					Herb_index_interval_track[z,i] = Herb_current_index
				end

				Herb_biomass_Supply_Max[z] = Herb_biomass_quantity_zone_per_h[end]
			end

			#####################################################################################################################################

			#Model piecewise function for biomass supply curve
			@variable(EP,w_piecewise_Herb_biomass[z in 1:Z, k in 1:Herb_intervals_biomass, t in 1:T] >= 0 )
			@variable(EP,z_piecewise_Herb_biomass[z in 1:Z, k in 1:Herb_intervals_biomass, t in 1:T],Bin)
			@variable(EP,y_piecewise_Herb_biomass[z in 1:Z, t in 1:T],Bin)

			##Constraints

			#Piecewise constriants for Cost
			@constraint(EP,cSum_z_piecewise_Herb_biomass[z in 1:Z, t in 1:T], sum(EP[:z_piecewise_Herb_biomass][z,k,t] for k in 1:Herb_intervals_biomass) == EP[:y_piecewise_Herb_biomass][z,t])
			@constraint(EP,cLeq_w_z_piecewise_Herb_biomass[z in 1:Z, k in 1:Herb_intervals_biomass, t in 1:T], EP[:w_piecewise_Herb_biomass][z,k,t] <= EP[:z_piecewise_Herb_biomass][z,k,t])
			@constraint(EP,cHerb_biomass_cost_per_zone[z in 1:Z, t in 1:T], EP[:vHerb_biomass_supply_cost_per_zone_per_time][z,t] == sum(EP[:z_piecewise_Herb_biomass][z,k,t]*Herb_biomass_cost_per_h_piecewise[z,k] + EP[:w_piecewise_Herb_biomass][z,k,t]*(Herb_biomass_cost_per_h_piecewise[z,k-1]-Herb_biomass_cost_per_h_piecewise[z,k]) for k = 2:Herb_intervals_biomass))
			@constraint(EP,cHerb_biomass_utilized_per_zone[z in 1:Z, t in 1:T], EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] == sum(EP[:z_piecewise_Herb_biomass][z,k,t]*Herb_biomass_quantity_per_h_piecewise[z,k] + EP[:w_piecewise_Herb_biomass][z,k,t]*(Herb_biomass_quantity_per_h_piecewise[z,k-1]-Herb_biomass_quantity_per_h_piecewise[z,k]) for k = 2:Herb_intervals_biomass))
			
			#Herb_biomass supply cost per zone per time
			#Add to Obj, need to account for time weight omega
			@expression(EP, eHerb_biomass_supply_cost_per_zone_per_time[z in 1:Z, t in 1:T], inputs["omega"][t] * EP[:vHerb_biomass_supply_cost_per_zone_per_time][z,t])
			
			#Herb_biomass emissions per zone per time
			@expression(EP,eHerb_biomass_emission_per_zone_per_time[z in 1:Z, t in 1:T], sum(EP[:z_piecewise_Herb_biomass][z,k,t]*Herb_biomass_emission_per_h_piecewise[z,k] + EP[:w_piecewise_Herb_biomass][z,k,t]*(Herb_biomass_emission_per_h_piecewise[z,k-1]-Herb_biomass_emission_per_h_piecewise[z,k]) for k = 2:Herb_intervals_biomass))

			#Output without time weight to show hourly cost
			@expression(EP, eHerb_biomass_supply_cost_per_zone_per_time_output[z in 1:Z, t in 1:T], EP[:vHerb_biomass_supply_cost_per_zone_per_time][z,t])

		else

			Herb_biomass_Supply_Max = zeros(Z)
			Herb_biomass_Cost_Max = zeros(Z)
			Herb_biomass_Emission_Max = zeros(Z)

			for z = 1:Z
				Herb_biomass_quantity_zone_per_h = collect(skipmissing(Herb_biomass_quantity_per_h[:,z]))
				Herb_biomass_cost_zone_per_h = collect(skipmissing(Herb_biomass_cost_per_h[:,z]))
				Herb_biomass_emission_zone_per_h = collect(skipmissing(Herb_biomass_emission_per_h[:,z]))

				Herb_biomass_Supply_Max[z] = Herb_biomass_quantity_zone_per_h[end]
				Herb_biomass_Cost_Max[z] = Herb_biomass_cost_zone_per_h[end]
				Herb_biomass_Emission_Max[z] = Herb_biomass_emission_zone_per_h[end]
			end

			Herb_biomass_cost_per_tonne = Herb_biomass_Cost_Max./Herb_biomass_Supply_Max
			Herb_biomass_emission_per_tonne = Herb_biomass_Emission_Max./Herb_biomass_Supply_Max

			#Add to Obj, need to account for time weight omega
			@expression(EP, eHerb_biomass_supply_cost_per_zone_per_time[z in 1:Z, t in 1:T], inputs["omega"][t] * EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] * Herb_biomass_cost_per_tonne[z])
			@expression(EP, eHerb_biomass_emission_per_zone_per_time[z in 1:Z, t in 1:T], EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] * Herb_biomass_emission_per_tonne[z])

			#Output without time weight to show hourly cost
			@expression(EP, eHerb_biomass_supply_cost_per_zone_per_time_output[z in 1:Z, t in 1:T], EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] * Herb_biomass_cost_per_tonne[z])


		end

	elseif setup["BIO_Nonlinear_Supply"] == 0

		Herb_biomass_supply_df = inputs["Herb_biomass_supply_df"]

		if setup["ParameterScale"] ==1
			Herb_biomass_Supply_Max = Herb_biomass_supply_df[!,:Max_tonne_per_hr]/ModelScalingFactor #Convert to ktonne
			Herb_biomass_cost_per_tonne = Herb_biomass_supply_df[!,:Cost_per_tonne_per_hr]/ModelScalingFactor #Convert to $M/ktonne
			Herb_biomass_emission_per_tonne = Herb_biomass_supply_df[!,:Emissions_tonne_per_tonne] #Convert to ktonne/ktonne = tonne/tonne
		else
			Herb_biomass_Supply_Max = Herb_biomass_supply_df[!,:Max_tonne_per_hr]
			Herb_biomass_cost_per_tonne = Herb_biomass_supply_df[!,:Cost_per_tonne_per_hr]
			Herb_biomass_emission_per_tonne = Herb_biomass_supply_df[!,:Emissions_tonne_per_tonne]
		end

		#Add to Obj, need to account for time weight omega
		@expression(EP, eHerb_biomass_supply_cost_per_zone_per_time[z in 1:Z, t in 1:T], inputs["omega"][t] * EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] * Herb_biomass_cost_per_tonne[z])
		@expression(EP, eHerb_biomass_emission_per_zone_per_time[z in 1:Z, t in 1:T], EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] * Herb_biomass_emission_per_tonne[z])

		#Output without time weight to show hourly cost
		@expression(EP, eHerb_biomass_supply_cost_per_zone_per_time_output[z in 1:Z, t in 1:T], EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] * Herb_biomass_cost_per_tonne[z])

	end

	#Total biomass supply cost per zone
	@expression(EP, eHerb_biomass_supply_cost_per_zone[z in 1:Z], sum(EP[:eHerb_biomass_supply_cost_per_zone_per_time][z,t] for t in 1:T))

	#Total biomass supply cost
	@expression(EP, eHerb_biomass_supply_cost, sum(EP[:eHerb_biomass_supply_cost_per_zone][z] for z in 1:Z))

	#Max biomass supply constraint
	@constraint(EP,cHerb_biomass_Max[z in 1:Z, t in 1:T], EP[:vHerb_biomass_utilized_per_zone_per_time][z,t] <= Herb_biomass_Supply_Max[z])

	EP[:eObj] += EP[:eHerb_biomass_supply_cost]

	return EP

end
