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
    load_h2_truck(path::AbstractString, sep::AbstractString, inputs_truck::Dict)    

Function for reading input parameters related to hydrogen trucks.
A variable is created to distinguish between Gas and Liquid trucks, which is relevant for the hydrogen balance expressions. 
Other truck types like LOHC are currently not considered, but may need to be identified as Gas for the balance. 

"""
function load_h2_truck(path::AbstractString, sep::AbstractString, inputs_truck::Dict)

    Z = inputs_truck["Z"]

    ## Hydrogen truck route inputs
    dfH2Route =
        DataFrame(CSV.File(joinpath(path, "Routes.csv"), header = true), copycols = true)
    
    ## Add truck route IDs after reading to prevent user errors
    dfH2Route[!, :R_ID] = 1:size(collect(skipmissing(dfH2Route[!, 1])), 1)

    ## Number of routes in the truck network
    inputs_truck["R"] = size(collect(skipmissing(dfH2Route[!, :R_ID])), 1)
    R = inputs_truck["R"]

    inputs_truck["dfH2Route"] = dfH2Route

    ## Topology of the truck network source-sink matrix
    Truck_map = zeros(Int64, R, Z)

    # This assumes that routes are formatted z1, z2, ...
    # FIX ME
    for r = 1:R
        z_start = parse(Int64, dfH2Route[!, :StartZone][r][2:end])
        z_end = parse(Int64, dfH2Route[!, :EndZone][r][2:end])
        Truck_map[r, z_start] = 1
        Truck_map[r, z_end] = -1
    end

    Truck_map = DataFrame(Truck_map, :auto)
    # Create route number column
    Truck_map[!, :route_no] = 1:size(Truck_map, 1)
    # Pivot table
    Truck_map = stack(Truck_map, 1:Z)
    # Create zone column
    Truck_map[!, :Zone] = parse.(Int64, SubString.(Truck_map[!, :variable], 2))
    # Remove redundant rows
    Truck_map = Truck_map[Truck_map[!, :value].!=0, :]

    # Rename column
    colnames_pipe_map = ["route_no", "zone_str", "d", "Zone"]
    rename!(Truck_map, Symbol.(colnames_pipe_map))

    inputs_truck["Truck_map"] = Truck_map
    print_and_log("Routes.csv Successfully Read!")

    # H2 truck type inputs
    h2_truck_in = DataFrame(CSV.File(joinpath(path, "HSC_trucks.csv"), header=true), copycols=true)

    # Add Truck Type IDs after reading to prevent user errors
    h2_truck_in[!,:T_TYPE] = 1:size(collect(skipmissing(h2_truck_in[!,1])),1)

    # Set of H2 truck types
    inputs_truck["H2_TRUCK_TYPES"] = h2_truck_in[!,:T_TYPE]
    # Set of H2 truck type names
    inputs_truck["H2_TRUCK_TYPE_NAMES"] = h2_truck_in[!,:H2TruckType]

    # Gas trucks
    inputs_truck["H2_TRUCK_GAS"] = h2_truck_in[h2_truck_in.H2TruckType .== "Gas", :T_TYPE]
    inputs_truck["H2_TRUCK_LIQ"] = h2_truck_in[h2_truck_in.H2TruckType .== "Liquid", :T_TYPE]

    inputs_truck["H2_TRUCK_LONG_DURATION"] = h2_truck_in[h2_truck_in.LDS .== 1, :T_TYPE]
    inputs_truck["H2_TRUCK_SHORT_DURATION"] = h2_truck_in[h2_truck_in.LDS .== 0, :T_TYPE]

    # Set of H2 truck types eligible for new capacity
    inputs_truck["NEW_CAP_TRUCK"] = h2_truck_in[h2_truck_in.New_Build .== 1, :T_TYPE]
    # Set of H2 truck types eligible for capacity retirement
    inputs_truck["RET_CAP_TRUCK"] = intersect(h2_truck_in[h2_truck_in.New_Build .!= -1, :T_TYPE], h2_truck_in[h2_truck_in.Existing_Number .> 0, :T_TYPE])
        
    # Store DataFrame of truck input data for use in model
    inputs_truck["dfH2Truck"] = h2_truck_in

    # Average truck travel time between zones
    inputs_truck["TD"] = Dict()
    for j in inputs_truck["H2_TRUCK_TYPES"]
        inputs_truck["TD"][j] = Dict()
        for r in 1:R
            inputs_truck["TD"][j][r] = round.(Int, dfH2Route[!, :Distance][r] / h2_truck_in[!, :AvgTruckSpeed_mile_per_hour][j])
        end
    end

    print_and_log("HSC_trucks.csv Successfully Read!")
    return inputs_truck
end