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

@doc raw"""
    write_h2_truck_capacity(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

"""
function write_syn_truck_capacity(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

    SYN_TRUCK_TYPES = inputs["SYN_TRUCK_TYPES"]
    NEW_CAP_SYN_TRUCK_CHARGE = inputs["NEW_CAP_SYN_TRUCK_CHARGE"]
    RET_CAP_SYN_TRUCK_CHARGE = inputs["RET_CAP_SYN_TRUCK_CHARGE"]
    NEW_CAP_SYN_TRUCK_ENERGY = inputs["NEW_CAP_SYN_TRUCK_ENERGY"]
    RET_CAP_SYN_TRUCK_ENERGY = inputs["RET_CAP_SYN_TRUCK_ENERGY"]

    dfSynTruck = inputs["dfSynTruck"]
    Z = inputs["Z"]

    # H2 truck capacity
    capNumber = zeros(size(SYN_TRUCK_TYPES))
    retNumber = zeros(size(SYN_TRUCK_TYPES))
    endNumber = zeros(size(SYN_TRUCK_TYPES))
    for j in SYN_TRUCK_TYPES
        if j in NEW_CAP_SYN_TRUCK_CHARGE
            capNumber[j] = value(EP[:vSynTruckNumber][j])
        end
        if j in RET_CAP_SYN_TRUCK_CHARGE
            retNumber[j] = value(EP[:vSynRetTruckNumber][j])
        end
        endNumber[j] = value(EP[:eTotalSynTruckNumber][j])
    end

    dfSynTruckCap = DataFrame(
        TruckType = inputs["SYN_TRUCK_TYPE_NAMES"],
        StartTruck = dfSynTruck[!, :Existing_Number],
        NewTruck = capNumber,
        RetTruck = retNumber,
        EndTruck = endNumber
    )

    for z in 1:Z
        dfSynTruckCap[!, Symbol("StartTruckEnergyZone$z")] = dfSynTruck[!, Symbol("Existing_Energy_Cap_tonne_z$z")]
        tempEnergy = zeros(size(SYN_TRUCK_TYPES))
        for j in SYN_TRUCK_TYPES
            if j in NEW_CAP_SYN_TRUCK_ENERGY
                tempEnergy[j] = value(EP[:vSynTruckEnergy][z,j])
            end
        end
        dfSynTruckCap[!,Symbol("NewTruckEnergyZone$z")] = tempEnergy

        tempEnergy = zeros(size(SYN_TRUCK_TYPES))
        for j in SYN_TRUCK_TYPES
            if j in RET_CAP_SYN_TRUCK_ENERGY
                tempEnergy[j] = value(EP[:vSynRetTruckEnergy][z,j])
            end
        end
        dfSynTruckCap[!,Symbol("RetTruckEnergyZone$z")] = tempEnergy

        tempEnergy = zeros(size(SYN_TRUCK_TYPES))
        for j in SYN_TRUCK_TYPES
            tempEnergy[j] = value(EP[:eTotalSynTruckEnergy][z,j])
        end
        dfSynTruckCap[!,Symbol("EndTruckEnergyZone$z")] = tempEnergy
    end

    dfSynTruckCap[!,:StartTruckEnergy] = sum(dfSynTruckCap[!, Symbol("StartTruckEnergyZone$z")] for z in 1:Z)
    dfSynTruckCap[!,:NewTruckEnergy] = sum(dfSynTruckCap[!, Symbol("NewTruckEnergyZone$z")] for z in 1:Z)
    dfSynTruckCap[!,:RetTruckEnergy] = sum(dfSynTruckCap[!, Symbol("RetTruckEnergyZone$z")] for z in 1:Z)
    dfSynTruckCap[!,:EndTruckEnergy] = sum(dfSynTruckCap[!, Symbol("EndTruckEnergyZone$z")] for z in 1:Z)

    dfSynTruckTotal = DataFrame(
        TruckType = "Total",
        StartTruck = sum(dfSynTruckCap[!,:StartTruck]),
        NewTruck = sum(dfSynTruckCap[!,:NewTruck]),
        RetTruck = sum(dfSynTruckCap[!,:RetTruck]),
        EndTruck = sum(dfSynTruckCap[!,:EndTruck]),
        StartTruckEnergy = sum(dfSynTruckCap[!,:StartTruckEnergy]),
        NewTruckEnergy = sum(dfSynTruckCap[!,:NewTruckEnergy]),
        RetTruckEnergy = sum(dfSynTruckCap[!,:RetTruckEnergy]),
        EndTruckEnergy = sum(dfSynTruckCap[!,:EndTruckEnergy])
    )

    for z in 1:Z
        dfSynTruckTotal[!,Symbol("StartTruckEnergyZone$z")] = [sum(dfSynTruckCap[!,Symbol("StartTruckEnergyZone$z")])]
        dfSynTruckTotal[!,Symbol("NewTruckEnergyZone$z")] = [sum(dfSynTruckCap[!,Symbol("NewTruckEnergyZone$z")])]
        dfSynTruckTotal[!,Symbol("RetTruckEnergyZone$z")] = [sum(dfSynTruckCap[!,Symbol("RetTruckEnergyZone$z")])]
        dfSynTruckTotal[!,Symbol("EndTruckEnergyZone$z")] = [sum(dfSynTruckCap[!,Symbol("EndTruckEnergyZone$z")])]
    end

    dfSynTruckCap = vcat(dfSynTruckCap, dfSynTruckTotal)

    CSV.write(joinpath(path, "Syn_fuels_truck_capacity.csv"), dfSynTruckCap)
end
