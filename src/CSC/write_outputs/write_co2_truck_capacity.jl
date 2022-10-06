"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021, Massachusetts Institute of Technology and Peking University
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
    write_co2_truck_capacity(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

"""
function write_co2_truck_capacity(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

    CO2_TRUCK_TYPES = inputs["CO2_TRUCK_TYPES"]
    NEW_CAP_CO2_TRUCK_CHARGE = inputs["NEW_CAP_CO2_TRUCK_CHARGE"]
    RET_CAP_CO2_TRUCK_CHARGE = inputs["RET_CAP_CO2_TRUCK_CHARGE"]
    NEW_CAP_CO2_TRUCK_ENERGY = inputs["NEW_CAP_CO2_TRUCK_ENERGY"]
    RET_CAP_CO2_TRUCK_ENERGY = inputs["RET_CAP_CO2_TRUCK_ENERGY"]

    dfCO2Truck = inputs["dfCO2Truck"]
    Z = inputs["Z"]

    # CO2 truck capacity
    capNumber = zeros(size(CO2_TRUCK_TYPES))
    retNumber = zeros(size(CO2_TRUCK_TYPES))
    endNumber = zeros(size(CO2_TRUCK_TYPES))
    for j in CO2_TRUCK_TYPES
        if j in NEW_CAP_CO2_TRUCK_CHARGE
            capNumber[j] = value(EP[:vCO2TruckNumber][j])
        end
        if j in RET_CAP_CO2_TRUCK_CHARGE
            retNumber[j] = value(EP[:vCO2RetTruckNumber][j])
        end
        endNumber[j] = value(EP[:eTotalCO2TruckNumber][j])
    end

    dfCO2TruckCap = DataFrame(
        TruckType = inputs["CO2_TRUCK_TYPE_NAMES"],
        StartTruck = dfCO2Truck[!, :Existing_Number],
        NewTruck = capNumber,
        RetTruck = retNumber,
        EndTruck = endNumber
    )

    for z in 1:Z
        dfCO2TruckCap[!, Symbol("StartTruckEnergyZone$z")] = dfCO2Truck[!, Symbol("Existing_Energy_Cap_tonne_z$z")]
        tempEnergy = zeros(size(CO2_TRUCK_TYPES))
        for j in CO2_TRUCK_TYPES
            if j in NEW_CAP_CO2_TRUCK_ENERGY
                tempEnergy[j] = value(EP[:vCO2TruckEnergy][z,j])
            end
        end
        dfCO2TruckCap[!,Symbol("NewTruckEnergyZone$z")] = tempEnergy

        tempEnergy = zeros(size(CO2_TRUCK_TYPES))
        for j in CO2_TRUCK_TYPES
            if j in RET_CAP_CO2_TRUCK_ENERGY
                tempEnergy[j] = value(EP[:vCO2RetTruckEnergy][z,j])
            end
        end
        dfCO2TruckCap[!,Symbol("RetTruckEnergyZone$z")] = tempEnergy

        tempEnergy = zeros(size(CO2_TRUCK_TYPES))
        for j in CO2_TRUCK_TYPES
            tempEnergy[j] = value(EP[:eTotalCO2TruckEnergy][z,j])
        end
        dfCO2TruckCap[!,Symbol("EndTruckEnergyZone$z")] = tempEnergy
    end

    dfCO2TruckCap[!,:StartTruckEnergy] = sum(dfCO2TruckCap[!, Symbol("StartTruckEnergyZone$z")] for z in 1:Z)
    dfCO2TruckCap[!,:NewTruckEnergy] = sum(dfCO2TruckCap[!, Symbol("NewTruckEnergyZone$z")] for z in 1:Z)
    dfCO2TruckCap[!,:RetTruckEnergy] = sum(dfCO2TruckCap[!, Symbol("RetTruckEnergyZone$z")] for z in 1:Z)
    dfCO2TruckCap[!,:EndTruckEnergy] = sum(dfCO2TruckCap[!, Symbol("EndTruckEnergyZone$z")] for z in 1:Z)

    dfCO2TruckTotal = DataFrame(
        TruckType = "Total",
        StartTruck = sum(dfCO2TruckCap[!,:StartTruck]),
        NewTruck = sum(dfCO2TruckCap[!,:NewTruck]),
        RetTruck = sum(dfCO2TruckCap[!,:RetTruck]),
        EndTruck = sum(dfCO2TruckCap[!,:EndTruck]),
        StartTruckEnergy = sum(dfCO2TruckCap[!,:StartTruckEnergy]),
        NewTruckEnergy = sum(dfCO2TruckCap[!,:NewTruckEnergy]),
        RetTruckEnergy = sum(dfCO2TruckCap[!,:RetTruckEnergy]),
        EndTruckEnergy = sum(dfCO2TruckCap[!,:EndTruckEnergy])
    )

    for z in 1:Z
        dfCO2TruckTotal[!,Symbol("StartTruckEnergyZone$z")] = [sum(dfCO2TruckCap[!,Symbol("StartTruckEnergyZone$z")])]
        dfCO2TruckTotal[!,Symbol("NewTruckEnergyZone$z")] = [sum(dfCO2TruckCap[!,Symbol("NewTruckEnergyZone$z")])]
        dfCO2TruckTotal[!,Symbol("RetTruckEnergyZone$z")] = [sum(dfCO2TruckCap[!,Symbol("RetTruckEnergyZone$z")])]
        dfCO2TruckTotal[!,Symbol("EndTruckEnergyZone$z")] = [sum(dfCO2TruckCap[!,Symbol("EndTruckEnergyZone$z")])]
    end

    dfCO2TruckCap = vcat(dfCO2TruckCap, dfCO2TruckTotal)

    CSV.write(joinpath(path, "CSC_CO2_truck_capacity.csv"), dfCO2TruckCap)
end
