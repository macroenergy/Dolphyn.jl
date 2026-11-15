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
	write_bio_zone_bionaturalgas_produced(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the bio natural gas produced across different zones with time.
"""
function write_bio_zone_bioethanol_produced(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfBioEthanol = inputs["dfBioEthanol"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Carbon balance for each zone
	dfZoneBioEthanolBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 1)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Bio Ethanol Produced"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

	   	for t in 1:T
			dfTemp1[t+rowoffset,1]= sum(value.(EP[:eBioEthanol_produced_tonne_per_plant_per_time][dfBioEthanol[(dfBioEthanol[!,:Zone].==z),:][!,:R_ID],t]))
	   	end

		if z==1
			dfZoneBioEthanolBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfZoneBioEthanolBalance = hcat(dfZoneBioEthanolBalance, dfTemp1)
		end
	end
	for c in 2:size(dfZoneBioEthanolBalance,2)
		dfZoneBioEthanolBalance[rowoffset,c]=sum(inputs["omega"].*dfZoneBioEthanolBalance[(rowoffset+1):size(dfZoneBioEthanolBalance,1),c])
	end
	dfZoneBioEthanolBalance = DataFrame(dfZoneBioEthanolBalance, :auto)
	CSV.write(string(path,sep,"BESC_zone_bioethanol_produced.csv"), dfZoneBioEthanolBalance, writeheader=false)
end
