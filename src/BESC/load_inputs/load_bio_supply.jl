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
	load_bio_supply(setup::Dict, path::AbstractString, sep::AbstractString, inputs_bio_supply::Dict)

Function for reading input parameters related to biomass supply in the bioenergy supply chain.
"""
function load_bio_supply(setup::Dict, path::AbstractString, sep::AbstractString, inputs_bio_supply::Dict)

	inputs_bio_supply["Herb_biomass_supply_df"] = DataFrame(CSV.File(string(path,sep,"BESC_Herb_Supply.csv"), header=true), copycols=true)
	println("Herb Biomass Supply Curves Successfully Read!")

	inputs_bio_supply["Wood_biomass_supply_df"] = DataFrame(CSV.File(string(path,sep,"BESC_Wood_Supply.csv"), header=true), copycols=true)
	println("Wood Biomass Supply Curves Successfully Read!")

    return inputs_bio_supply

end
