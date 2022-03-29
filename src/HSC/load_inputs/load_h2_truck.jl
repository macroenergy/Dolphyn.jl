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
    load_h2_truck(path::AbstractString, sep::AbstractString, inputs_truck::Dict)    

Function for reading input parameters related to CO$_2$ emissions cap constraints
"""
function load_h2_truck(path::AbstractString, sep::AbstractString, inputs_truck::Dict)

    Z = inputs_truck["Z"]
    Z_set = 1:Z

    zone_distance = DataFrame(CSV.File(string(path, sep, "zone-distances-km.csv"), header=true), copycols=true)

	RouteLength = zone_distance[Z_set,Z_set.+1]
	inputs_truck["RouteLength"] = RouteLength
    
    println("zone-distances-km.csv Successfully Read!")
    # H2 truck type inputs
    h2_truck_in = DataFrame(CSV.File(string(path,sep,"HSC_truck.csv"), header=true), copycols=true)

    # Add Truck Type IDs after reading to prevent user errors
	h2_truck_in[!,:T_TYPE] = 1:size(collect(skipmissing(h2_truck_in[!,1])),1)

    # Set of H2 truck types
    inputs_truck["H2_TRUCK_TYPES"] = h2_truck_in[!,:T_TYPE]
    # Set of H2 truck type names
    inputs_truck["H2_TRUCK_TYPE_NAMES"] = h2_truck_in[!,:H2TruckType]
    # Set of H2 truck types eligible for new capacity
    inputs_truck["NEW_CAP_H2_TRUCK_CHARGE"] = h2_truck_in[h2_truck_in.New_Build .== 1, :T_TYPE]
    # Set of H2 truck types eligible for capacity retirement
    inputs_truck["RET_CAP_H2_TRUCK_CHARGE"] = intersect(h2_truck_in[h2_truck_in.New_Build .!= -1, :T_TYPE], h2_truck_in[h2_truck_in.Existing_Number .> 0, :T_TYPE])

    # Set of H2 truck types eligible for new energy capacity
    inputs_truck["NEW_CAP_H2_TRUCK_ENERGY"] = h2_truck_in[h2_truck_in.New_Build .== 1, :T_TYPE]
    # Set of H2 truck types eligible for energy capacity retirement
    inputs_truck["RET_CAP_H2_TRUCK_ENERGY"] = intersect(h2_truck_in[h2_truck_in.New_Build .!= -1, :T_TYPE], h2_truck_in[h2_truck_in.Existing_Number .> 0, :T_TYPE])
        
    # Store DataFrame of truck input data for use in model
    inputs_truck["dfH2Truck"] = h2_truck_in

    println("HSC_truck.csv Successfully Read!")
    return inputs_truck
end