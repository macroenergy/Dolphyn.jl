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
function write_h2_truck_flow(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)
    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"]
	H2_TRUCK_TYPE_NAMES = inputs["H2_TRUCK_TYPE_NAMES"]
    Z = inputs["Z"]
	T = inputs["T"]

    # H2 truck flow
	truck_flow_path = string(path, sep, "H2TruckFlow")
	if (isdir(truck_flow_path) == false)
		mkdir(truck_flow_path)
	end

	for j in H2_TRUCK_TYPES
		dfH2TruckFlow = DataFrame(Time = 1:T)
		for z in 1:Z
			dfH2TruckFlow[!,Symbol("Zone$z")] = value.(EP[:vH2TruckFlow])[z,j,:]
		end
		CSV.write(string(truck_flow_path, sep, string("H2TruckFlow_",H2_TRUCK_TYPE_NAMES[j],".csv")), dfH2TruckFlow)
	end

	# H2 truck Number
	truck_number_path = string(path, sep, "H2TruckNumber")
	if (isdir(truck_number_path) == false)
		mkdir(truck_number_path)
	end

	dfH2TruckNumberFull = DataFrame(Time = 1:T)
	dfH2TruckNumberEmpty = DataFrame(Time = 1:T)
	for j in H2_TRUCK_TYPES
		dfH2TruckNumberFull[!,Symbol(H2_TRUCK_TYPE_NAMES[j])] = value.(EP[:vH2N_full])[j,:]
		dfH2TruckNumberEmpty[!,Symbol(H2_TRUCK_TYPE_NAMES[j])] = value.(EP[:vH2N_empty])[j,:]
	end
	CSV.write(string(truck_number_path, sep, "H2TruckNumberFull.csv"), dfH2TruckNumberFull)
	CSV.write(string(truck_number_path, sep, "H2TruckNumberEmpty.csv"), dfH2TruckNumberEmpty)

	# H2 truck state
	truck_state_path = string(path, sep, "H2TruckState")
	if (isdir(truck_state_path) == false)
		mkdir(truck_state_path)
	end
	dfH2TruckAvailFull = DataFrame(Time = 1:T)
	dfH2TruckAvailEmpty = DataFrame(Time = 1:T)
	dfH2TruckCharged = DataFrame(Time = 1:T)
	dfH2TruckDischarged = DataFrame(Time = 1:T)
	for j in H2_TRUCK_TYPES
		for z in 1:Z
			dfH2TruckAvailFull[!,Symbol(string("Zone$z-",H2_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vH2Navail_full])[z,j,:]
			dfH2TruckAvailEmpty[!,Symbol(string("Zone$z-",H2_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vH2Navail_empty])[z,j,:]
			dfH2TruckCharged[!,Symbol(string("Zone$z-",H2_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vH2Ncharged])[z,j,:]
			dfH2TruckDischarged[!,Symbol(string("Zone$z-",H2_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vH2Ndischarged])[z,j,:]
		end
	end
	CSV.write(string(truck_state_path, sep, string("H2TruckAvailFull.csv")), dfH2TruckAvailFull)
	CSV.write(string(truck_state_path, sep, string("H2TruckAvailEmpty.csv")), dfH2TruckAvailEmpty)
	CSV.write(string(truck_state_path, sep, string("H2TruckCharged.csv")), dfH2TruckCharged)
	CSV.write(string(truck_state_path, sep, string("H2TruckDischarged.csv")), dfH2TruckDischarged)

	# H2 truck transit
	truck_transit_path = string(path, sep, "H2Transit")
	if (isdir(truck_transit_path) == false)
		mkdir(truck_transit_path)
	end

	dfH2TruckTravelFull = DataFrame(Time = 1:T)
	dfH2TruckArriveFull = DataFrame(Time = 1:T)
	dfH2TruckDepartFull = DataFrame(Time = 1:T)
	dfH2TruckTravelEmpty = DataFrame(Time = 1:T)
	dfH2TruckArriveEmpty = DataFrame(Time = 1:T)
	dfH2TruckDepartEmpty = DataFrame(Time = 1:T)
	for j in H2_TRUCK_TYPES
		dfH2TruckTravelFull[!,Symbol(H2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vH2Ntravel_full])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfH2TruckArriveFull[!,Symbol(H2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vH2Narrive_full])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfH2TruckDepartFull[!,Symbol(H2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vH2Ndepart_full])[zz,z,j,:] for zz in 1:Z, z in 1:Z)

		dfH2TruckTravelEmpty[!,Symbol(H2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vH2Ntravel_empty])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfH2TruckArriveEmpty[!,Symbol(H2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vH2Narrive_empty])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfH2TruckDepartEmpty[!,Symbol(H2_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vH2Ndepart_empty])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
	end

	CSV.write(string(truck_transit_path, sep, "H2TruckTravelFull.csv"), dfH2TruckTravelFull)
	CSV.write(string(truck_transit_path, sep, "H2TruckArriveFull.csv"), dfH2TruckArriveFull)
	CSV.write(string(truck_transit_path, sep, "H2TruckDepartFull.csv"), dfH2TruckDepartFull)

	CSV.write(string(truck_transit_path, sep, "H2TruckTravelEmpty.csv"), dfH2TruckTravelEmpty)
	CSV.write(string(truck_transit_path, sep, "H2TruckArriveEmpty.csv"), dfH2TruckArriveEmpty)
	CSV.write(string(truck_transit_path, sep, "H2TruckDepartEmpty.csv"), dfH2TruckDepartEmpty)
end