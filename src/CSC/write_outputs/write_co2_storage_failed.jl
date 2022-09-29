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
	write_co2_storage(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)

Function for writing the capacities of different CO2 storage technologies, including hydro reservoir, flexible storage tech etc.
"""
function write_co2_storage(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)
	dfCO2Stor = inputs["dfCO2Stor"]
	T = inputs["T"]     # Number of time steps (hours)
	H = inputs["CO2_STOR_ALL"]  # Set of CO2 storage resources

	# Storage level (state of charge) of each resource in each time step
	dfStorage = DataFrame(Resource = inputs["CO2_STORAGE_NAME"], Zone = dfCO2Stor[!,:Zone])
	s = zeros(H,T)
	storagevcapvalue = zeros(H,T)
	for i in 1:H
		s[i,:] = value.(EP[:vCO2S])[i,:]
	end

	# Incorporating effect of Parameter scaling (ParameterScale=1) on output values
	for y in 1:H
		storagevcapvalue[y,:] = s[y,:]
	end


	dfStorage = hcat(dfStorage, DataFrame(storagevcapvalue, :auto))
	auxNew_Names=[Symbol("Resource");Symbol("Zone");[Symbol("t$t") for t in 1:T]]
	rename!(dfStorage,auxNew_Names)
	CSV.write(string(path,sep,"CSC_storage.csv"), dftranspose(dfStorage, false), writeheader=false)
end
