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
    write_h2_truck_capacity(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)

Functions for reporting capacities of hydrogen trucks (starting capacities or, existing capacities, retired capacities, and new-built capacities).    
"""
function write_h2_truck_capacity(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)

    # GC.enable(false)
    H2_TRUCK_TYPES::Vector{Int64} = inputs["H2_TRUCK_TYPES"]
    NEW_CAP_TRUCK::Vector{Int64} = inputs["NEW_CAP_TRUCK"]
    RET_CAP_TRUCK::Vector{Int64} = inputs["RET_CAP_TRUCK"]

    dfH2Truck::DataFrame = inputs["dfH2Truck"]
    Z::Int64 = inputs["Z"]

    # H2 truck capacity
    capNumber::Vector{Float64} = zeros(size(H2_TRUCK_TYPES))
    retNumber::Vector{Float64} = zeros(size(H2_TRUCK_TYPES))
    endNumber::Vector{Float64} = zeros(size(H2_TRUCK_TYPES))
    for j in H2_TRUCK_TYPES
        if j in NEW_CAP_TRUCK
            capNumber[j] = value(EP[:vH2TruckNumber][j])
        end
        if j in RET_CAP_TRUCK
            retNumber[j] = value(EP[:vH2RetTruckNumber][j])
        end
        endNumber[j] = value(EP[:eTotalH2TruckNumber][j])
    end

    dfH2TruckCap = DataFrame(
        TruckType = inputs["H2_TRUCK_TYPE_NAMES"],
        StartTruck = dfH2Truck[!, :Existing_Number],
        NewTruck = capNumber,
        RetTruck = retNumber,
        EndTruck = endNumber
    )

    prealloc_dfH2Truck_cols!(dfH2TruckCap, Z, H2_TRUCK_TYPES)

    for z in 1:Z
        dfH2TruckCap[!, Symbol("StartTruckCompZone$z")] = dfH2Truck[!, Symbol("Existing_Comp_Cap_tonne_p_hr_z$z")]

        temp_idx::Vector{Int64} = intersect(H2_TRUCK_TYPES, NEW_CAP_TRUCK)
        dfH2TruckCap[!,Symbol("NewTruckCompZone$z")][temp_idx] .= convert(Vector{Float64}, value.(EP[:vH2TruckComp][z,temp_idx]))

        temp_idx = intersect(H2_TRUCK_TYPES, RET_CAP_TRUCK)
        dfH2TruckCap[!,Symbol("RetTruckCompZone$z")][temp_idx] .= convert(Vector{Float64}, value.(EP[:vH2RetTruckComp][z,temp_idx]))

        temp_idx = H2_TRUCK_TYPES
        dfH2TruckCap[!,Symbol("EndTruckCompZone$z")][temp_idx] .= convert(Vector{Float64}, value.(EP[:eTotalH2TruckComp][z,temp_idx]))
    end

    dfH2TruckCap[!,:StartTruckComp] = sum(dfH2TruckCap[!, Symbol("StartTruckCompZone$z")] for z in 1:Z)
    dfH2TruckCap[!,:NewTruckComp] = sum(dfH2TruckCap[!, Symbol("NewTruckCompZone$z")] for z in 1:Z)
    dfH2TruckCap[!,:RetTruckComp] = sum(dfH2TruckCap[!, Symbol("RetTruckCompZone$z")] for z in 1:Z)
    dfH2TruckCap[!,:EndTruckComp] = sum(dfH2TruckCap[!, Symbol("EndTruckCompZone$z")] for z in 1:Z)

    dfH2TruckTotal = DataFrame(
        TruckType = "Total",
        StartTruck = sum(dfH2TruckCap[!,:StartTruck]),
        NewTruck = sum(dfH2TruckCap[!,:NewTruck]),
        RetTruck = sum(dfH2TruckCap[!,:RetTruck]),
        EndTruck = sum(dfH2TruckCap[!,:EndTruck]),
        StartTruckComp = sum(dfH2TruckCap[!,:StartTruckComp]),
        NewTruckComp = sum(dfH2TruckCap[!,:NewTruckComp]),
        RetTruckComp = sum(dfH2TruckCap[!,:RetTruckComp]),
        EndTruckComp = sum(dfH2TruckCap[!,:EndTruckComp])
    )
    for z in 1:Z
        dfH2TruckTotal[!,Symbol("StartTruckCompZone$z")] = [sum(dfH2TruckCap[!,Symbol("StartTruckCompZone$z")])]
        dfH2TruckTotal[!,Symbol("NewTruckCompZone$z")] = [sum(dfH2TruckCap[!,Symbol("NewTruckCompZone$z")])]
        dfH2TruckTotal[!,Symbol("RetTruckCompZone$z")] = [sum(dfH2TruckCap[!,Symbol("RetTruckCompZone$z")])]
        dfH2TruckTotal[!,Symbol("EndTruckCompZone$z")] = [sum(dfH2TruckCap[!,Symbol("EndTruckCompZone$z")])]
    end

    dfH2TruckCap = vcat(dfH2TruckCap, dfH2TruckTotal)
    CSV.write(joinpath(path, "h2_truck_capacity.csv"), dfH2TruckCap)
    # GC.enable(true)

end

function prealloc_dfH2Truck_cols!(dfH2TruckCap::DataFrame, Z::Int64, H2_TRUCK_TYPES::Vector{Int64})
    num_trucks::Tuple{Int64} = size(H2_TRUCK_TYPES)

    root_names::Vector{String} = [
        "StartTruckCompZone",
        "NewTruckCompZone",
        "RetTruckCompZone",
        "EndTruckCompZone"
    ]
    for z in 1:Z
        for root in root_names
            dfH2TruckCap[!, Symbol("$root$z")] = zeros(Float64, num_trucks)
        end
    end

    tail_names::Vector{String} = [
        "StartTruckComp",
        "NewTruckComp",
        "RetTruckComp",
        "EndTruckComp"
    ]
    for name in tail_names
        dfH2TruckCap[!, Symbol(name)] = zeros(Float64, num_trucks)
    end
end