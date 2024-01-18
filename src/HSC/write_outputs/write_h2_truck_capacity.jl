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
    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"]
    NEW_CAP_TRUCK = inputs["NEW_CAP_TRUCK"]
    RET_CAP_TRUCK = inputs["RET_CAP_TRUCK"]
   # NEW_CAP_TRUCK = inputs["NEW_CAP_TRUCK"]
   # RET_CAP_TRUCK = inputs["RET_CAP_TRUCK"]

    dfH2Truck = inputs["dfH2Truck"]
    Z = inputs["Z"]

    # H2 truck capacity
    capNumber = zeros(size(H2_TRUCK_TYPES))
    retNumber = zeros(size(H2_TRUCK_TYPES))
    endNumber = zeros(size(H2_TRUCK_TYPES))
    truck_new_cap = intersect(inputs["H2_TRUCK_TYPES"], inputs["NEW_CAP_TRUCK"])
    truck_ret_cap = intersect(inputs["H2_TRUCK_TYPES"], inputs["RET_CAP_TRUCK"])
    if !isempty(truck_new_cap)
        capNumber[truck_new_cap] = value.(EP[:vH2TruckNumber][truck_new_cap]).data
    end
    if !isempty(truck_ret_cap)
        retNumber[truck_ret_cap] = value.(EP[:vH2RetTruckNumber][truck_ret_cap]).data
    end
    endNumber[H2_TRUCK_TYPES] = value.(EP[:eTotalH2TruckNumber][H2_TRUCK_TYPES]).data

    dfH2TruckCap = DataFrame(
        TruckType = inputs["H2_TRUCK_TYPE_NAMES"],
        StartTruck = dfH2Truck[!, :Existing_Number],
        NewTruck = capNumber,
        RetTruck = retNumber,
        EndTruck = endNumber
    )

    for z in 1:Z
        dfH2TruckCap[!, Symbol("StartTruckEnergyZone$z")] = dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")]
        tempEnergy = zeros(size(H2_TRUCK_TYPES))
        truck_new_cap = intersect(inputs["H2_TRUCK_TYPES"], inputs["NEW_CAP_TRUCK"])
        tempEnergy[truck_new_cap] = value.(EP[:vH2TruckEnergy][z,truck_new_cap]).data
        dfH2TruckCap[!,Symbol("NewTruckEnergyZone$z")] = tempEnergy

        tempEnergy = zeros(size(H2_TRUCK_TYPES))
        truck_ret_cap = intersect(inputs["H2_TRUCK_TYPES"], inputs["RET_CAP_TRUCK"])
        tempEnergy[truck_ret_cap] = value.(EP[:vH2RetTruckEnergy][z,truck_ret_cap]).data
        dfH2TruckCap[!,Symbol("RetTruckEnergyZone$z")] = tempEnergy

        tempEnergy = zeros(size(H2_TRUCK_TYPES))
        for j in H2_TRUCK_TYPES
            tempEnergy[j] = value(EP[:eTotalH2TruckEnergy][z,j])
        end
        dfH2TruckCap[!,Symbol("EndTruckEnergyZone$z")] = tempEnergy
    end

    dfH2TruckCap[!,:StartTruckEnergy] = sum(dfH2TruckCap[!, Symbol("StartTruckEnergyZone$z")] for z in 1:Z)
    dfH2TruckCap[!,:NewTruckEnergy] = sum(dfH2TruckCap[!, Symbol("NewTruckEnergyZone$z")] for z in 1:Z)
    dfH2TruckCap[!,:RetTruckEnergy] = sum(dfH2TruckCap[!, Symbol("RetTruckEnergyZone$z")] for z in 1:Z)
    dfH2TruckCap[!,:EndTruckEnergy] = sum(dfH2TruckCap[!, Symbol("EndTruckEnergyZone$z")] for z in 1:Z)

    dfH2TruckTotal = DataFrame(
        TruckType = "Total",
        StartTruck = sum(dfH2TruckCap[!,:StartTruck]),
        NewTruck = sum(dfH2TruckCap[!,:NewTruck]),
        RetTruck = sum(dfH2TruckCap[!,:RetTruck]),
        EndTruck = sum(dfH2TruckCap[!,:EndTruck]),
        StartTruckEnergy = sum(dfH2TruckCap[!,:StartTruckEnergy]),
        NewTruckEnergy = sum(dfH2TruckCap[!,:NewTruckEnergy]),
        RetTruckEnergy = sum(dfH2TruckCap[!,:RetTruckEnergy]),
        EndTruckEnergy = sum(dfH2TruckCap[!,:EndTruckEnergy])
    )

    for z in 1:Z
        dfH2TruckTotal[!,Symbol("StartTruckEnergyZone$z")] = [sum(dfH2TruckCap[!,Symbol("StartTruckEnergyZone$z")])]
        dfH2TruckTotal[!,Symbol("NewTruckEnergyZone$z")] = [sum(dfH2TruckCap[!,Symbol("NewTruckEnergyZone$z")])]
        dfH2TruckTotal[!,Symbol("RetTruckEnergyZone$z")] = [sum(dfH2TruckCap[!,Symbol("RetTruckEnergyZone$z")])]
        dfH2TruckTotal[!,Symbol("EndTruckEnergyZone$z")] = [sum(dfH2TruckCap[!,Symbol("EndTruckEnergyZone$z")])]
    end

    dfH2TruckCap = vcat(dfH2TruckCap, dfH2TruckTotal)
    
    CSV.write(string(path, sep, "HSC_h2_truck_capacity.csv"), dftranspose(dfH2TruckCap, false))
end
