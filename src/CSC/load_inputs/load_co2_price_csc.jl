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
	load_co2_price_csc(path::AbstractString, setup::Dict, inputs::Dict)

Function for reading input parameters related to CO$_2$ emission cap constraints
"""
function load_co2_price_csc(path::AbstractString, setup::Dict, inputs::Dict)

	# Set indices for internal use
	T = inputs["T"]   # Number of time steps (hours)
	Zones = inputs["Zones"] # List of modeled zones

	# Definition of CO2 emission cap requirements by zone (as Max Mtons)
	co2_price_csc = DataFrame(CSV.File(joinpath(path, "CSC_CO2_price.csv"), header=true), copycols=true)

	# Filter zonal CO2 price in modeled zones
	co2_price_csc = filter(row -> (row.Zone in ["z$z" for z in Zones]), co2_price_csc)

	# Emission limits
	if  setup["CO2CostOffset"] == 1 # Carbon capture offset via a carbon price on total emission
		if setup["ParameterScale"] == 1
			inputs["dfCO2CO2PriceZone"] = co2_price_csc[!,:CO2_Price]*ModelScalingFactor/1e+6
			# when scaled, the constraint unit is million$/ktonne
		else
			inputs["dfCO2CO2PriceZone"] = co2_price_csc[!,:CO2_Price]
			# when not scaled, the constraint unit is ton
		end
	end

	println("CSC_CO2_price.csv Successfully Read!")
	
	return inputs
end
