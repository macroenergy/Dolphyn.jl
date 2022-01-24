function write_h2_truck_capacity(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)
    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"]
    NEW_CAP_H2_TRUCK_CHARGE = inputs["NEW_CAP_H2_TRUCK_CHARGE"]
    RET_CAP_H2_TRUCK_CHARGE = inputs["RET_CAP_H2_TRUCK_CHARGE"]
    NEW_CAP_H2_TRUCK_ENERGY = inputs["NEW_CAP_H2_TRUCK_ENERGY"]
    RET_CAP_H2_TRUCK_ENERGY = inputs["RET_CAP_H2_TRUCK_ENERGY"]

    dfH2Truck = inputs["dfH2Truck"]
    Z = inputs["Z"]

    # H2 truck capacity
    capNumber = zeros(size(H2_TRUCK_TYPES))
    retNumber = zeros(size(H2_TRUCK_TYPES))
    endNumber = zeros(size(H2_TRUCK_TYPES))
    for j in H2_TRUCK_TYPES
        if j in NEW_CAP_H2_TRUCK_CHARGE
            capNumber[j] = value(EP[:vH2CAPTRUCKNUMBER][j])
        end
        if j in RET_CAP_H2_TRUCK_CHARGE
            retNumber[j] = value(EP[:vH2RETCAPTRUCKNUMBER][j])
        end
        endNumber = value(EP[:eTotalH2CapTruckNumber][j])
    end

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
        for j in H2_TRUCK_TYPES
            if j in NEW_CAP_H2_TRUCK_ENERGY
                tempEnergy[j] = value(EP[:vH2CAPTRUCKENERGY][z,j])
            end
        end
        dfH2TruckCap[!,Symbol("NewTruckEnergyZone$z")] = tempEnergy

        tempEnergy = zeros(size(H2_TRUCK_TYPES))
        for j in H2_TRUCK_TYPES
            if j in RET_CAP_H2_TRUCK_ENERGY
                tempEnergy[j] = value(EP[:vH2RETCAPTRUCKENERGY][z,j])
            end
        end
        dfH2TruckCap[!,Symbol("RetTruckEnergyZone$z")] = tempEnergy

        tempEnergy = zeros(size(H2_TRUCK_TYPES))
        for j in H2_TRUCK_TYPES
            tempEnergy[j] = value(EP[:eTotalH2CapTruckEnergy][z,j])
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
    CSV.write(string(path, sep, "h2_truck_capacity.csv"), dfH2TruckCap)
end