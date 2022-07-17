"""
CaptureX: An Configurable Capacity Expansion Model
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

function write_co2_capture_compression_zone(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfCO2CaptureComp = inputs["dfCO2CaptureComp"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Carbon balance for each zone
	dfCO2CaptureCompBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 1)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Captured CO2 Compressed"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))
	   	for t in 1:T
	     	dfTemp1[t+rowoffset,1]= sum(value.(EP[:vCO2_Capture_Compressed][dfCO2CaptureComp[dfCO2CaptureComp[!,:Zone].==z,:][!,:R_ID],t]))
	   	end

		if z==1
			dfCO2CaptureCompBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfCO2CaptureCompBalance = hcat(dfCO2CaptureCompBalance, dfTemp1)
		end
	end
	for c in 2:size(dfCO2CaptureCompBalance,2)
		dfCO2CaptureCompBalance[rowoffset,c]=sum(inputs["omega"].*dfCO2CaptureCompBalance[(rowoffset+1):size(dfCO2CaptureCompBalance,1),c])
	end
	dfCO2CaptureCompBalance = DataFrame(dfCO2CaptureCompBalance, :auto)
	CSV.write(string(path,sep,"CSC_co2_capture_compression_zone.csv"), dfCO2CaptureCompBalance, writeheader=false)
end
