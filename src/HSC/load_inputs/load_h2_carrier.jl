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
    load_h2_carrier(setup::Dict, path::AbstractString, sep::AbstractString, inputs_gen::Dict)

Function for reading input parameters related to hydrogen carriers.
Liquifiers and evaporators are considered in the HSC_generation.csv. 
"""
function load_h2_carrier(setup::Dict, path::AbstractString, sep::AbstractString, inputs_gen::Dict)

    #Read in H2 carrier related cost and performance data
    h2_carrier_in = DataFrame(CSV.File(joinpath(path, "HSC_carriers.csv"), header=true), copycols=true)

    #Read in routes eligible for H2 carriers
    h2_carrier_routes = DataFrame(CSV.File(joinpath(path, "HSC_carrier_routes.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
    h2_carrier_in[!,:R_ID] = 1:size(collect(skipmissing(h2_carrier_in[!,1])),1)

    # Store DataFrame of generators/resources input data for use in model
    inputs_gen["dfH2carrier"] = h2_carrier_in

    # Index of H2 carriers and sub-processes
    inputs_gen["H2_CARRIER_ALL"] = size(collect(skipmissing(h2_carrier_in[!,:R_ID])),1)

    # carrier names
    inputs_gen["carrier_names"] = unique(h2_carrier_in[:, :carrier])
  
    # # carrier sub-process names
    inputs_gen["carrier_process_names"] = unique(h2_carrier_in[:, :process])

    # Hydrogenation processes
    inputs_gen["CARRIER_HYD"] = h2_carrier_in[h2_carrier_in.HYD.==1,:process] 
    # Dehydrogenation processe for each carrier type
    inputs_gen["CARRIER_DEHYD"] = h2_carrier_in[h2_carrier_in.HYD.==2,:process]

    # Defining a dictionary to map carrier type and process type to R_ID for extracting parameters
    R_ID = Dict{Tuple{String, String}, Int64}()

    #### Mapping each carrier, process pair to a corresponding R_ID
    for c in inputs_gen["carrier_names"], p in inputs_gen["carrier_process_names"]  
      R_ID[(c,p)] =  h2_carrier_in[intersect(findall(x -> x == p, h2_carrier_in[:,:process]), findall(x -> x ==c, h2_carrier_in[:,:carrier])),:R_ID][1]       
    end

    inputs_gen["carrier_R_ID"] = R_ID

    # # Set of all rows corresponding to carrier hydrogenation process
    # inputs_gen["CARRIER_HYD"] = h2_carrier_in[findall(x -> x == "hyd", h2_carrier_in[:,:process]),:R_ID]
   
    # # Set of all rows corresponding to carrier dehydrogenation process
    # inputs_gen["CARRIER_DEHYD"] = h2_carrier_in[findall(x -> x == "dehyd", h2_carrier_in[:, :process]),:R_ID]
   
    #store dataframe related carrier_routes and distance
    inputs_gen["dfh2carrier_candidate_routes"] = h2_carrier_routes

    # Matrix of allowed routes for carriers
    inputs_gen["carrier_candidate_routes"] = Matrix(inputs_gen["dfh2carrier_candidate_routes"][:,[:Zone1,:Zone2]]) 

    # Convert each row to a tuple of source sink pairs eligible for carriers
    inputs_gen["carrier_candidate_routes_tuple"] = [(inputs_gen["carrier_candidate_routes"][i, 1], inputs_gen["carrier_candidate_routes"][i, 2]) for i in 1:size(inputs_gen["carrier_candidate_routes"], 1)]
    # println("carrier_candidate_routes_tuple,", inputs_gen["carrier_candidate_routes_tuple"])

    # println("routes from zone 4,", [r for r in inputs_gen["carrier_candidate_routes_tuple"] if r[1] == 4])

    # set of candidate source sinks for carriers
    inputs_gen["carrier_zones"] = unique(inputs_gen["carrier_candidate_routes"])
    # println("carrier_zones,", inputs_gen["carrier_zones"])

 
    println(" -- HSC_carriers.csv Successfully Read!")

    return inputs_gen

end

