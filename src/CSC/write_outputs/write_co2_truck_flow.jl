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
	write_co2_truck_flow(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

"""
function write_co2_truck_flow(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

    CO2_TRUCK_TYPES = inputs["CO2_TRUCK_TYPES"]
	CO2_TRUCK_TYPE_NAMES = inputs["CO2_TRUCK_TYPE_NAMES"]

	Z = inputs["Z"]
	T = inputs["T"]

    # CO2 truck flow
	truck_flow_path = joinpath(path, "CO2TruckFlow")
	if !isdir(truck_flow_path)
		mkdir(truck_flow_path)
	end

	for j in CO2_TRUCK_TYPES
		dfCO2TruckFlow = DataFrame(Time = 1:T)
		for z in 1:Z
			dfCO2TruckFlow[!,Symbol("Zone$z")] = value.(EP[:vCO2TruckFlow])[z,j,:]
		end
		CSV.write(joinpath(truck_flow_path, string("CO2TruckFlow_",CO2_TRUCK_TYPE_NAMES[j],".csv")), dfCO2TruckFlow)
	end

	# CO2 truck Number
	truck_number_path = joinpath(path, "CO2TruckNumber")
	if !isdir(truck_number_path)
		mkdir(truck_number_path)
	end

	dfCO2TruckNumberFull = DataFrame(Time = 1:T)
	dfCO2TruckNumberEmpty = DataFrame(Time = 1:T)
	for j in CO2_TRUCK_TYPES
		dfCO2TruckNumberFull[!,Symbol(CO2_TRUCK_TYPE_NAMES[j])] = value.(EP[:vCO2N_full])[j,:]
		dfCO2TruckNumberEmpty[!,Symbol(CO2_TRUCK_TYPE_NAMES[j])] = value.(EP[:vCO2N_empty])[j,:]
	end
	CSV.write(joinpath(truck_number_path, "CO2TruckNumberFull.csv"), dfCO2TruckNumberFull)
	CSV.write(joinpath(truck_number_path, "CO2TruckNumberEmpty.csv"), dfCO2TruckNumberEmpty)

	# CO2 truck state
	truck_state_path = joinpath(path, "CO2TruckState")
	if !isdir(truck_state_path)
		mkdir(truck_state_path)
	end

	dfCO2TruckAvailFull = DataFrame(Time = 1:T)
	dfCO2TruckAvailEmpty = DataFrame(Time = 1:T)
	dfCO2TruckCharged = DataFrame(Time = 1:T)
	dfCO2TruckDischarged = DataFrame(Time = 1:T)
	for j in CO2_TRUCK_TYPES
		for z in 1:Z
			dfCO2TruckAvailFull[!,Symbol(string("Zone$z-",CO2_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vCO2Navail_full])[z,j,:]
			dfCO2TruckAvailEmpty[!,Symbol(string("Zone$z-",CO2_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vCO2Navail_empty])[z,j,:]
			dfCO2TruckCharged[!,Symbol(string("Zone$z-",CO2_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vCO2Ncharged])[z,j,:]
			dfCO2TruckDischarged[!,Symbol(string("Zone$z-",CO2_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vCO2Ndischarged])[z,j,:]
		end
	end

	CSV.write(joinpath(truck_state_path, "CO2TruckAvailFull.csv"), dfCO2TruckAvailFull)
	CSV.write(joinpath(truck_state_path, "CO2TruckAvailEmpty.csv"), dfCO2TruckAvailEmpty)
	CSV.write(joinpath(truck_state_path, "CO2TruckCharged.csv"), dfCO2TruckCharged)
	CSV.write(joinpath(truck_state_path, "CO2TruckDischarged.csv"), dfCO2TruckDischarged)

	# CO2 truck transit
	truck_transit_path = joinpath(path, "CO2Transit")
	if !isdir(truck_transit_path)
		mkdir(truck_transit_path)
	end

	dfCO2TruckTravelFull = DataFrame(Time = 1:T)
	dfCO2TruckArriveFull = DataFrame(Time = 1:T)
	dfCO2TruckDepartFull = DataFrame(Time = 1:T)
	dfCO2TruckTravelEmpty = DataFrame(Time = 1:T)
	dfCO2TruckArriveEmpty = DataFrame(Time = 1:T)
	dfCO2TruckDepartEmpty = DataFrame(Time = 1:T)
	for j in CO2_TRUCK_TYPES
		dfCO2TruckTravelFull[!,Symbol(CO2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vCO2Ntravel_full])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfCO2TruckArriveFull[!,Symbol(CO2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vCO2Narrive_full])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfCO2TruckDepartFull[!,Symbol(CO2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vCO2Ndepart_full])[zz,z,j,:] for zz in 1:Z, z in 1:Z)

		dfCO2TruckTravelEmpty[!,Symbol(CO2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vCO2Ntravel_empty])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfCO2TruckArriveEmpty[!,Symbol(CO2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vCO2Narrive_empty])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfCO2TruckDepartEmpty[!,Symbol(CO2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vCO2Ndepart_empty])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
	end

	CSV.write(joinpath(truck_transit_path, "CO2TruckTravelFull.csv"), dfCO2TruckTravelFull)
	CSV.write(joinpath(truck_transit_path, "CO2TruckArriveFull.csv"), dfCO2TruckArriveFull)
	CSV.write(joinpath(truck_transit_path, "CO2TruckDepartFull.csv"), dfCO2TruckDepartFull)

	CSV.write(joinpath(truck_transit_path, "CO2TruckTravelEmpty.csv"), dfCO2TruckTravelEmpty)
	CSV.write(joinpath(truck_transit_path, "CO2TruckArriveEmpty.csv"), dfCO2TruckArriveEmpty)
	CSV.write(joinpath(truck_transit_path, "CO2TruckDepartEmpty.csv"), dfCO2TruckDepartEmpty)
end
