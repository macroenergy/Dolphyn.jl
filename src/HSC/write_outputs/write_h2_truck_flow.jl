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
    write_h2_truck_flow(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)    

Fucntion for reporting hydrogen flow via trucsk.    
"""
function write_h2_truck_flow(
    path::AbstractString,
    sep::AbstractString,
    inputs::Dict,
    setup::Dict,
    EP::Model,
)
    H2_TRUCK_TYPES::Vector{Int64} = inputs["H2_TRUCK_TYPES"]
    H2_TRUCK_TYPE_NAMES::Vector{String7} = inputs["H2_TRUCK_TYPE_NAMES"]
    Z::Int64 = inputs["Z"]
    T::Int64  = inputs["T"]
    R::Int64  = inputs["R"]

    # H2 truck flow on each zone for every type of truck 
    truck_flow_path = joinpath(path, "H2TruckFlow")
    if (isdir(truck_flow_path) == false)
        mkdir(truck_flow_path)
    end

    dfH2TruckFlow = DataFrame(Time = 1:T)
    jump2df!(dfH2TruckFlow, EP, :vH2TruckFlow, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES, Z)

    CSV.write(string(truck_flow_path, sep, string("H2TruckFlow.csv")), dfH2TruckFlow)

    # H2 truck Number tracking among zones with truck accessibility
    truck_number_path = joinpath(path, "H2TruckNumber")
    if (isdir(truck_number_path) == false)
        mkdir(truck_number_path)
    end

    dfH2TruckNumberFull = DataFrame(Time = 1:T)
    dfH2TruckNumberEmpty = DataFrame(Time = 1:T)

    jump2df!(dfH2TruckNumberFull, EP, :vH2N_full, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES)
    jump2df!(dfH2TruckNumberEmpty, EP, :vH2N_empty, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES)

    CSV.write(string(truck_number_path, sep, "H2TruckNumberFull.csv"), dfH2TruckNumberFull)
    CSV.write(
        string(truck_number_path, sep, "H2TruckNumberEmpty.csv"),
        dfH2TruckNumberEmpty,
    )

    # H2 truck state - Available full, available empty, charged and discharged truck numbersk
    truck_state_path = joinpath(path, "H2TruckState")
    if (isdir(truck_state_path) == false)
        mkdir(truck_state_path)
    end
    dfH2TruckAvailFull = DataFrame(Time = 1:T)
    dfH2TruckAvailEmpty = DataFrame(Time = 1:T)
    dfH2TruckCharged = DataFrame(Time = 1:T)
    dfH2TruckDischarged = DataFrame(Time = 1:T)

    jump2df!(dfH2TruckAvailFull, EP, :vH2Navail_full, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES, Z)
    jump2df!(dfH2TruckAvailEmpty, EP, :vH2Navail_empty, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES, Z)
    jump2df!(dfH2TruckCharged, EP, :vH2Ncharged, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES, Z)
    jump2df!(dfH2TruckDischarged, EP, :vH2Ndischarged, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES, Z)

    CSV.write(
        string(truck_state_path, sep, string("H2TruckAvailFull.csv")),
        dfH2TruckAvailFull,
    )
    CSV.write(
        string(truck_state_path, sep, string("H2TruckAvailEmpty.csv")),
        dfH2TruckAvailEmpty,
    )
    CSV.write(string(truck_state_path, sep, string("H2TruckCharged.csv")), dfH2TruckCharged)
    CSV.write(
        string(truck_state_path, sep, string("H2TruckDischarged.csv")),
        dfH2TruckDischarged,
    )

    # H2 truck transit on each route
    truck_transit_path = joinpath(path, "H2Transit")
    if (isdir(truck_transit_path) == false)
        mkdir(truck_transit_path)
    end

    directions = Dict(1 => "Positive", -1 => "Negative")
    dfH2TruckTravelFull = DataFrame(Time = 1:T)
    dfH2TruckArriveFull = DataFrame(Time = 1:T)
    dfH2TruckDepartFull = DataFrame(Time = 1:T)
    dfH2TruckTravelEmpty = DataFrame(Time = 1:T)
    dfH2TruckArriveEmpty = DataFrame(Time = 1:T)
    dfH2TruckDepartEmpty = DataFrame(Time = 1:T)

    jump2df!(dfH2TruckTravelFull, EP, :vH2Ntravel_full, directions, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES, R)
    jump2df!(dfH2TruckArriveFull, EP, :vH2Narrive_full, directions, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES, R)
    jump2df!(dfH2TruckDepartFull, EP, :vH2Ndepart_full, directions, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES, R)
    jump2df!(dfH2TruckTravelEmpty, EP, :vH2Ntravel_empty, directions, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES, R)
    jump2df!(dfH2TruckArriveEmpty, EP, :vH2Narrive_empty, directions, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES, R)
    jump2df!(dfH2TruckDepartEmpty, EP, :vH2Ndepart_empty, directions, H2_TRUCK_TYPE_NAMES, H2_TRUCK_TYPES, R)

    CSV.write(string(truck_transit_path, sep, "H2TruckTravelFull.csv"), dfH2TruckTravelFull)
    CSV.write(string(truck_transit_path, sep, "H2TruckArriveFull.csv"), dfH2TruckArriveFull)
    CSV.write(string(truck_transit_path, sep, "H2TruckDepartFull.csv"), dfH2TruckDepartFull)

    CSV.write(
        string(truck_transit_path, sep, "H2TruckTravelEmpty.csv"),
        dfH2TruckTravelEmpty,
    )
    CSV.write(
        string(truck_transit_path, sep, "H2TruckArriveEmpty.csv"),
        dfH2TruckArriveEmpty,
    )
    CSV.write(
        string(truck_transit_path, sep, "H2TruckDepartEmpty.csv"),
        dfH2TruckDepartEmpty,
    )
end

function jump2df!(df::DataFrame, EP::Model, jumpvar::Symbol, H2_TRUCK_TYPE_NAMES::Vector{String7}, H2_TRUCK_TYPES::Vector{Int64})
    temp::JuMP.Containers.DenseAxisArray{Float64} = value.(EP[jumpvar])
    for j in H2_TRUCK_TYPES
        df[!, Symbol(H2_TRUCK_TYPE_NAMES[j])] = temp[j,:] 
    end
end

function jump2df!(df::DataFrame, EP::Model, jumpvar::Symbol, H2_TRUCK_TYPE_NAMES::Vector{String7}, H2_TRUCK_TYPES::Vector{Int64}, Z::Int64)
    temp::JuMP.Containers.DenseAxisArray{Float64} = value.(EP[jumpvar])
    for j in H2_TRUCK_TYPES
        for z = 1:Z
            df[!, Symbol(string("Zone$z-", H2_TRUCK_TYPE_NAMES[j]))] = temp[z,j,:] 
        end
    end
end

function jump2df!(df::DataFrame, EP::Model, jumpvar::Symbol, directions::Dict{Int64,String}, H2_TRUCK_TYPE_NAMES::Vector{String7}, H2_TRUCK_TYPES::Vector{Int64}, R::Int64)
    # temp::JuMP.Containers.DenseAxisArray{Float64, 4} = value.(EP[jumpvar])
    temp::JuMP.Containers.DenseAxisArray{Float64, 4, Ax, L} where {Ax, L<:NTuple{4, JuMP.Containers._AxisLookup}} = value.(EP[jumpvar])
    for d in [-1, 1]
        direction = directions[d]
        for j in H2_TRUCK_TYPES
            truck_name = H2_TRUCK_TYPE_NAMES[j]
            for r = 1:R
                @inbounds df[!, Symbol(string(truck_name,"onRoute$r","Direction$direction)"))] = temp[r,j,d,:]
            end
        end
    end
end