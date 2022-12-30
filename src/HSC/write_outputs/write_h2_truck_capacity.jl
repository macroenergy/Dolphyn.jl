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

    dfH2Truck = inputs["dfH2Truck"]
    Z = inputs["Z"]

    # H2 truck capacity
    capNumber = zeros(size(H2_TRUCK_TYPES))
    retNumber = zeros(size(H2_TRUCK_TYPES))
    endNumber = zeros(size(H2_TRUCK_TYPES))
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

    for z in 1:Z
        dfH2TruckCap[!, Symbol("StartTruckCompZone$z")] = dfH2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")]
        tempComp = zeros(size(H2_TRUCK_TYPES))
        for j in H2_TRUCK_TYPES
            if j in NEW_CAP_TRUCK
                tempComp[j] = value(EP[:vH2TruckComp][z,j])
            end
        end
        dfH2TruckCap[!,Symbol("NewTruckCompZone$z")] = tempComp

        tempComp = zeros(size(H2_TRUCK_TYPES))
        for j in H2_TRUCK_TYPES
            if j in RET_CAP_TRUCK
                tempComp[j] = value(EP[:vH2RetTruckComp][z,j])
            end
        end
        dfH2TruckCap[!,Symbol("RetTruckCompZone$z")] = tempComp

        tempComp = zeros(size(H2_TRUCK_TYPES))
        for j in H2_TRUCK_TYPES
            tempComp[j] = value(EP[:eTotalH2TruckComp][z,j])
        end
        dfH2TruckCap[!,Symbol("EndTruckCompZone$z")] = tempComp
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
    CSV.write(string(path, sep, "h2_truck_capacity.csv"), dfH2TruckCap)
end