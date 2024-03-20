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
	write_bio_zone_herb_consumed(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the herb biomass consumed across different zones with time.
"""
function write_bio_zone_herb_consumed(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones

	#Power consumed per zone
    dfBioZoneHerbQuantity = DataFrame(Zone = 1:Z, AnnualSum = Array{Union{Missing,Float32}}(undef, Z))

	for i in 1:Z
		if setup["ParameterScale"]==1
			dfBioZoneHerbQuantity[!,:AnnualSum][i] = sum(inputs["omega"].* (value.(EP[:vHerb_biomass_utilized_per_zone_per_time])[i,:]))*ModelScalingFactor
		else
			dfBioZoneHerbQuantity[!,:AnnualSum][i] = sum(inputs["omega"].* (value.(EP[:vHerb_biomass_utilized_per_zone_per_time])[i,:]))
		end
	end

	# Load hourly values
	if setup["ParameterScale"]==1
		dfBioZoneHerbQuantity = hcat(dfBioZoneHerbQuantity, DataFrame((value.(EP[:vHerb_biomass_utilized_per_zone_per_time]))*ModelScalingFactor, :auto))
	else
		dfBioZoneHerbQuantity = hcat(dfBioZoneHerbQuantity, DataFrame((value.(EP[:vHerb_biomass_utilized_per_zone_per_time])), :auto))
	end

	# Add labels
	auxNew_Names=[Symbol("Herbcaeous biomass consumed by zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
	rename!(dfBioZoneHerbQuantity,auxNew_Names)

	total = DataFrame(["Total" sum(dfBioZoneHerbQuantity[!,:AnnualSum]) fill(0.0, (1,T))], :auto)

	for t in  1:T
		total[:,t+2] .= sum(dfBioZoneHerbQuantity[:,Symbol("t$t")][1:Z])
	end

	rename!(total,auxNew_Names)
	dfBioZoneHerbQuantity = vcat(dfBioZoneHerbQuantity, total)

 	CSV.write(string(path,sep,"BESC_zone_supply_herb_consumed.csv"), dftranspose(dfBioZoneHerbQuantity, false), writeheader=false)
	return dfBioZoneHerbQuantity


end