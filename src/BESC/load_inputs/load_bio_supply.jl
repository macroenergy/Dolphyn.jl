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

	#Read in herb biomass related inputs
    Herb_biomass_supply = DataFrame(CSV.File(string(path,sep,"BESC_Herb_Supply.csv"), header=true), copycols=true)

	# Add Resource IDs after reading to prevent user errors
	Herb_biomass_supply[!,:R_ID] = 1:size(collect(skipmissing(Herb_biomass_supply[!,1])),1)

    # Store DataFrame of resources input data for use in model
	inputs_bio_supply["dfHerb"] = Herb_biomass_supply

    # Index of supply resources
	inputs_bio_supply["HERB_SUPPLY_RES_ALL"] = size(collect(skipmissing(Herb_biomass_supply[!,:R_ID])),1)

	# Name of supply resources
	inputs_bio_supply["HERB_SUPPLY_NAME"] = collect(skipmissing(Herb_biomass_supply[!,:Biomass_Supply][1:inputs_bio_supply["HERB_SUPPLY_RES_ALL"]]))

	# Set of supply resources
	inputs_bio_supply["BESC_HERB_SUPPLY"] = Herb_biomass_supply[!,:R_ID]

	println("Herb Biomass Supply Curves Successfully Read!")

	####################################################

	#Read in wood biomass related inputs
    Wood_biomass_supply = DataFrame(CSV.File(string(path,sep,"BESC_Wood_Supply.csv"), header=true), copycols=true)

	# Add Resource IDs after reading to prevent user errors
	Wood_biomass_supply[!,:R_ID] = 1:size(collect(skipmissing(Wood_biomass_supply[!,1])),1)

    # Store DataFrame of resources input data for use in model
	inputs_bio_supply["dfWood"] = Wood_biomass_supply

    # Index of supply resources
	inputs_bio_supply["WOOD_SUPPLY_RES_ALL"] = size(collect(skipmissing(Wood_biomass_supply[!,:R_ID])),1)

	# Name of supply resources
	inputs_bio_supply["WOOD_SUPPLY_NAME"] = collect(skipmissing(Wood_biomass_supply[!,:Biomass_Supply][1:inputs_bio_supply["WOOD_SUPPLY_RES_ALL"]]))

	# Set of supply resources
	inputs_bio_supply["BESC_WOOD_SUPPLY"] = Wood_biomass_supply[!,:R_ID]

	println("Wood Biomass Supply Curves Successfully Read!")

    return inputs_bio_supply

end

