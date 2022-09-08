"""
CaptureX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Captureeral Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Captureeral Public License for more details.
A complete copy of the GNU Captureeral Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	write_power(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the different values of power generated by the different technologies in operation.
"""
function write_co2_capture_plant(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfCO2Capture = inputs["dfCO2Capture"]
	H = inputs["CO2_RES_ALL"]     # Number of resources (Capture units, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)

	# Power injected by each resource in each time step
	# dfCO2CaptureOut_annual = DataFrame(Resource = inputs["CO2_RESOURCES_NAME"], Zone = dfCO2Capture[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))
	dfCO2CaptureOut = DataFrame(Resource = inputs["CO2_RESOURCES_NAME"], Zone = dfCO2Capture[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))

	for i in 1:H
		if setup["ParameterScale"]==1
			dfCO2CaptureOut[!,:AnnualSum][i] = sum(inputs["omega"].* (value.(EP[:vDAC_CO2_Captured])[i,:]))*ModelScalingFactor
		else
			dfCO2CaptureOut[!,:AnnualSum][i] = sum(inputs["omega"].* (value.(EP[:vDAC_CO2_Captured])[i,:]))
		end
	end

	# Load hourly values
	if setup["ParameterScale"]==1
		dfCO2CaptureOut = hcat(dfCO2CaptureOut, DataFrame((value.(EP[:vDAC_CO2_Captured]))*ModelScalingFactor, :auto))
	else
		dfCO2CaptureOut = hcat(dfCO2CaptureOut, DataFrame((value.(EP[:vDAC_CO2_Captured])), :auto))
	end

	# Add labels
	auxNew_Names=[Symbol("Resource");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
	rename!(dfCO2CaptureOut,auxNew_Names)

	total = DataFrame(["Total" 0 sum(dfCO2CaptureOut[!,:AnnualSum]) fill(0.0, (1,T))], :auto)

	for t in  1:T
		total[:,t+3] .= sum(dfCO2CaptureOut[:,Symbol("t$t")][1:H])
	end

	rename!(total,auxNew_Names)
	dfPower = vcat(dfCO2CaptureOut, total)

 	CSV.write(string(path,sep,"CSC_DAC_co2_capture_plant.csv"), dftranspose(dfCO2CaptureOut, false), writeheader=false)
	return dfCO2CaptureOut


end
