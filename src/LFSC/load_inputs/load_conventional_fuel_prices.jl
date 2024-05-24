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
	load_conventional_fuel_prices(setup::Dict, path::AbstractString, sep::AbstractString, inputs_bio_supply::Dict)

Function for reading input parameters related to conventional fuels regional prices.
"""
function load_conventional_fuel_prices(setup::Dict, path::AbstractString, sep::AbstractString, inputs_regional_fuel_price::Dict)

	inputs_regional_fuel_price["Conv_Gasoline_Regional_Price"] = DataFrame(CSV.File(string(path,sep,"LFSC_Gasoline_Prices.csv"), header=true), copycols=true)

	inputs_regional_fuel_price["Conv_Jetfuel_Regional_Price"] = DataFrame(CSV.File(string(path,sep,"LFSC_Jetfuel_Prices.csv"), header=true), copycols=true)

	inputs_regional_fuel_price["Conv_Diesel_Regional_Price"] = DataFrame(CSV.File(string(path,sep,"LFSC_Diesel_Prices.csv"), header=true), copycols=true)
	
	println("Regional Conventional Fuel Prices Successfully Read!")

    return inputs_regional_fuel_price

end

