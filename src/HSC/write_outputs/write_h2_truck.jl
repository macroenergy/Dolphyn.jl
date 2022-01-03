function write_h2_truck(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)
    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"]
    Z = inputs["Z"] 

    # H2 truck capacity
    dfH2TruckNumber = DataFrame(
        TruckType = H2_TRUCK_TYPES,
        NewTruck = value.(EP[:vH2CAPTRUCKNUMBER]),
        RetTruck = value.(EP[:vH2RETCAPTRUCKNUMBER]),
        EndTruck = value.(EP[:eTotalH2CapTruckNumber]),
    )

    for z in 1:Z
        dfH2TruckNumber[!,Symbol("NewTruckEnergyZone$z")] = value.(EP[:vH2CAPTRUCKENERGY][z,:])
        dfH2TruckNumber[!,Symbol("RetTruckEnergyZone$z")] = value.(EP[:vH2RETCAPTRUCKENERGY][z,:])
        dfH2TruckNumber[!,Symbol("EndTruckEnergyZone$z")] = value.(EP[:eTotalH2CapTruckEnergy][z,:])
    end

    dfH2TruckNumber[!,:NewTruckEnergy] = sum("NewTruckEnergyZone$z" for z in 1:Z)
    dfH2TruckNumber[!,:RetTruckEnergy] = sum("RetTruckEnergyZone$z" for z in 1:Z)
    dfH2TruckNumber[!,:EndTruckEnergy] = sum("EndTruckEnergyZone$z" for z in 1:Z)

    dfH2TruckTotal = DataFrame(
        Total = [
            "Total",
            sum(dfH2TruckNumber[!,:NewTruck]),
            sum(dfH2TruckNumber[!,:RetTruck]),
            sum(dfH2TruckNumber[!,:EndTruck]),
            for z in 1:Z
                sum(dfH2TruckNumber[!,Symbol("NewTruckEnergyZone$z")])
            end,
            sum(dfH2TruckNumber[!,:NewTruckEnergy]),
            sum(dfH2TruckNumber[!,:RetTruckEnergy]),
            sum(dfH2TruckNumber[!,:EndTruckEnergy])
        ]
    )

    dfH2TruckNumber = hcat(dfH2TruckNumber, dfH2TruckTotal)
    CSV.write(string(path, sep, "h2_truck_capacity.csv"), dfH2TruckNumber)

    # H2 truck flow
    key_TruckVar  = ["vH2TruckFlow", "vNavail_full","vNtravel_full","vNarrive_full","vNdepart_full","vNavail_empty","vNtravel_empty","vNarrive_empty","vNdepart_empty","vNcharged","vNdischarged","vN_full","vN_empty"]

    value_TruckVar = Dict()
	for key in key_TruckVar
		value_TruckVar[key] = value.(EP[Symbol(key)])
	end

    for j in H2_TRUCK_TYPES
	    for key in keys(value_TruckVar)
	        if length(size(value_TruckVar[key])) == 2
	            CSV.write(joinpath(path,string(key,"_",r,".csv")),DataFrame(value_TruckVar[key]))
	        #     println(dfPlan[key])
	        elseif length(size(value_TruckVar[key])) == 3
	            CSV.write(joinpath(path,string(key,"_",r,".csv")),DataFrame(value_TruckVar[key][:,r,:]))
	        elseif length(size(value_TruckVar[key])) == 4
	            resultpath_H2Truck = joinpath(path,string("truck_travel_",r))
	            if (isdir(resultpath_H2Truck)==false)
	        	     mkdir(resultpath_H2Truck)
	        	end
	            for z in 1:inputs_H2["Z"]
	                CSV.write(joinpath(resultpath_H2Truck,string(key,"_",z,".csv")),DataFrame(value_TruckVar[key][z,:,r,:]))
	            end
	        end
	    end
    end
end