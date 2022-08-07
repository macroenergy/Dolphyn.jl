"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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

@doc"""
    load_co2_truck(path::AbstractString, sep::AbstractString, inputs_truck::Dict)

"""
function load_co2_truck(path::AbstractString, sep::AbstractString, inputs_truck::Dict)

    Z = inputs_truck["Z"]
    Z_set = 1:Z

    zone_distance = DataFrame(CSV.File(string(path, sep, "zone-distances-miles.csv"), header=true), copycols=true)

	RouteLength = zone_distance[Z_set,Z_set.+1]
	inputs_truck["RouteLength"] = RouteLength
    
    println("zone-distances-miles.csv Successfully Read!")

    # Carbon truck type inputs
    co2_truck_in = DataFrame(CSV.File(string(path, sep, "CSC_trucks.csv"), header=true), copycols=true)

    # Add Truck Type IDs after reading to prevent user errors
	co2_truck_in[!,:T_TYPE] = 1:size(collect(skipmissing(co2_truck_in[!,1])),1)

    # Set of cabon truck types
    inputs_truck["CO2_TRUCK_TYPES"] = co2_truck_in[!,:T_TYPE]
    # Set of carbon truck type names
    inputs_truck["CO2_TRUCK_TYPE_NAMES"] = co2_truck_in[!,:H2TruckType]

    inputs_truck["CO2_TRUCK_LONG_DURATION"] = co2_truck_in[co2_truck_in.LDS .== 1, :T_TYPE]
	inputs_truck["CO2_TRUCK_SHORT_DURATION"] = co2_truck_in[co2_truck_in.LDS .== 0, :T_TYPE]

    # Set of carbon truck types eligible for new capacity
    inputs_truck["NEW_CAP_CO2_TRUCK_CHARGE"] = co2_truck_in[co2_truck_in.New_Build .== 1, :T_TYPE]
    # Set of carbon truck types eligible for capacity retirement
    inputs_truck["RET_CAP_CO2_TRUCK_CHARGE"] = intersect(co2_truck_in[co2_truck_in.New_Build .!= -1, :T_TYPE], co2_truck_in[co2_truck_in.Existing_Number .> 0, :T_TYPE])

    # Set of carbon truck types eligible for new energy capacity
    inputs_truck["NEW_CAP_CO2_TRUCK_ENERGY"] = co2_truck_in[co2_truck_in.New_Build .== 1, :T_TYPE]
    # Set of carbon truck types eligible for energy capacity retirement
    inputs_truck["RET_CAP_CO2_TRUCK_ENERGY"] = intersect(co2_truck_in[co2_truck_in.New_Build .!= -1, :T_TYPE], co2_truck_in[co2_truck_in.Existing_Number .> 0, :T_TYPE])
        
    # Store DataFrame of truck input data for use in model
    inputs_truck["dfCO2Truck"] = co2_truck_in


    # Average truck travel time between zones
    inputs_truck["TD"] = Dict()
    for j in inputs_truck["CO2_TRUCK_TYPES"]
        inputs_truck["TD"][j] = round.(Int, RouteLength ./ co2_truck_in[!, :AvgTruckSpeed_mile_per_hour][j])
    end

    println("CSC_trucks.csv Successfully Read!")
    
    return inputs_truck
end