"""
GenX: An Configurable Capacity Expansion Model
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
	write_co2_captured_across_sectors(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting co2 storage balance of resources across different zones.
"""
function write_co2_captured_across_sectors(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfGen = inputs["dfGen"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	dfCO2Captured_Sectors = DataFrame(PowerCCS = sum(sum(inputs["omega"].* (value.(EP[:ePower_CO2_captured_per_zone_per_time_acc])[z,:])) for z in 1:Z), HydrogenCCS = sum(sum(inputs["omega"].* (value.(EP[:eHydrogen_CO2_captured_per_zone_per_time_acc])[z,:])) for z in 1:Z))

	#dfCO2Captured_Sectors = DataFrame(:PowerCCS => Float64, :HydrogenCCS => Float64)

	#dfCO2Captured_Sectors[!, :PowerCCS] = sum(sum(inputs["omega"].* (value.(EP[:ePower_CO2_captured_per_zone_per_time_acc])[z,:])) for z in 1:Z)


	#if setup["ModelH2"] == 1
	#	dfCO2Captured_Sectors[!, :HydrogenCCS] = sum(sum(inputs["omega"].* (value.(EP[:eHydrogen_CO2_captured_per_zone_per_time_acc])[z,:])) for z in 1:Z)
	#else
	#	dfCO2Captured_Sectors[!, :HydrogenCCS] = 0
	#end


    dfCO2Captured_Sectors[!, :Total] = sum.(eachrow(dfCO2Captured_Sectors))
	
	CSV.write(string(path,sep,"CCS_Accounting.csv"), dfCO2Captured_Sectors, writeheader=true)
end
