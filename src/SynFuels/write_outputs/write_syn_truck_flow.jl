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
	write_h2_truck_flow(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

"""
function write_syn_truck_flow(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

    SYN_TRUCK_TYPES = inputs["SYN_TRUCK_TYPES"]
	SYN_TRUCK_TYPE_NAMES = inputs["SYN_TRUCK_TYPE_NAMES"]

	Z = inputs["Z"]
	T = inputs["T"]

    # H2 truck flow
	truck_flow_path = joinpath(path, "SynTruckFlow")
	if !isdir(truck_flow_path)
		mkdir(truck_flow_path)
	end

	for j in SYN_TRUCK_TYPES
		dfH2TruckFlow = DataFrame(Time = 1:T)
		for z in 1:Z
			dfH2TruckFlow[!,Symbol("Zone$z")] = value.(EP[:vSynTruckFlow])[z,j,:]
		end
		CSV.write(joinpath(truck_flow_path, string("SynTruckFlow_",SYN_TRUCK_TYPE_NAMES[j],".csv")), dfH2TruckFlow)
	end

	# H2 truck Number
	truck_number_path = joinpath(path, "SynTruckNumber")
	if !isdir(truck_number_path)
		mkdir(truck_number_path)
	end

	dfH2TruckNumberFull = DataFrame(Time = 1:T)
	dfH2TruckNumberEmpty = DataFrame(Time = 1:T)
	for j in SYN_TRUCK_TYPES
		dfH2TruckNumberFull[!,Symbol(SYN_TRUCK_TYPE_NAMES[j])] = value.(EP[:vH2N_full])[j,:]
		dfH2TruckNumberEmpty[!,Symbol(SYN_TRUCK_TYPE_NAMES[j])] = value.(EP[:vH2N_empty])[j,:]
	end
	CSV.write(joinpath(truck_number_path, "SynTruckNumberFull.csv"), dfH2TruckNumberFull)
	CSV.write(joinpath(truck_number_path, "SynTruckNumberEmpty.csv"), dfH2TruckNumberEmpty)

	# H2 truck state
	truck_state_path = joinpath(path, "SynTruckState")
	if !isdir(truck_state_path)
		mkdir(truck_state_path)
	end

	dfH2TruckAvailFull = DataFrame(Time = 1:T)
	dfH2TruckAvailEmpty = DataFrame(Time = 1:T)
	dfH2TruckCharged = DataFrame(Time = 1:T)
	dfH2TruckDischarged = DataFrame(Time = 1:T)
	for j in SYN_TRUCK_TYPES
		for z in 1:Z
			dfH2TruckAvailFull[!,Symbol(string("Zone$z-",SYN_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vH2Navail_full])[z,j,:]
			dfH2TruckAvailEmpty[!,Symbol(string("Zone$z-",SYN_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vH2Navail_empty])[z,j,:]
			dfH2TruckCharged[!,Symbol(string("Zone$z-",SYN_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vH2Ncharged])[z,j,:]
			dfH2TruckDischarged[!,Symbol(string("Zone$z-",SYN_TRUCK_TYPE_NAMES[j]))] = value.(EP[:vH2Ndischarged])[z,j,:]
		end
	end

	CSV.write(joinpath(truck_state_path, "SynTruckAvailFull.csv"), dfH2TruckAvailFull)
	CSV.write(joinpath(truck_state_path, "SynTruckAvailEmpty.csv"), dfH2TruckAvailEmpty)
	CSV.write(joinpath(truck_state_path, "SynTruckCharged.csv"), dfH2TruckCharged)
	CSV.write(joinpath(truck_state_path, "SynTruckDischarged.csv"), dfH2TruckDischarged)

	# H2 truck transit
	truck_transit_path = joinpath(path, "SynTruckTransit")
	if !isdir(truck_transit_path)
		mkdir(truck_transit_path)
	end

	dfSynTruckTravelFull = DataFrame(Time = 1:T)
	dfSynTruckArriveFull = DataFrame(Time = 1:T)
	dfSynTruckDepartFull = DataFrame(Time = 1:T)
	dfSynTruckTravelEmpty = DataFrame(Time = 1:T)
	dfSynTruckArriveEmpty = DataFrame(Time = 1:T)
	dfSynTruckDepartEmpty = DataFrame(Time = 1:T)
	for j in SYN_TRUCK_TYPES
		dfSynTruckTravelFull[!,Symbol(SYN_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vSynNtravel_full])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfSynTruckArriveFull[!,Symbol(SYN_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vSynNarrive_full])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfSynTruckDepartFull[!,Symbol(SYN_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vSynNdepart_full])[zz,z,j,:] for zz in 1:Z, z in 1:Z)

		dfSynTruckTravelEmpty[!,Symbol(SYN_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vSynNtravel_empty])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfSynTruckArriveEmpty[!,Symbol(SYN_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vSynNarrive_empty])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
		dfSynTruckDepartEmpty[!,Symbol(SYN_TRUCK_TYPE_NAMES[j])] = sum(value.(EP[:vSynNdepart_empty])[zz,z,j,:] for zz in 1:Z, z in 1:Z)
	end

	CSV.write(joinpath(truck_transit_path, "SynTruckTravelFull.csv"), dfSynTruckTravelFull)
	CSV.write(joinpath(truck_transit_path, "SynTruckArriveFull.csv"), dfSynTruckArriveFull)
	CSV.write(joinpath(truck_transit_path, "SynTruckDepartFull.csv"), dfSynTruckDepartFull)

	CSV.write(joinpath(truck_transit_path, "SynTruckTravelEmpty.csv"), dfSynTruckTravelEmpty)
	CSV.write(joinpath(truck_transit_path, "SynTruckArriveEmpty.csv"), dfSynTruckArriveEmpty)
	CSV.write(joinpath(truck_transit_path, "SynTruckDepartEmpty.csv"), dfSynTruckDepartEmpty)
end
