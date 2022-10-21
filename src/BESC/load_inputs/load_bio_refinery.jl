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


function load_bio_refinery(setup::Dict, path::AbstractString, sep::AbstractString, inputs_biorefinery::Dict)

	biorefinery = DataFrame(CSV.File(string(path,sep,"BESC_Biorefinery.csv"), header=true), copycols=true)

	# Add Resource IDs after reading to prevent user errors
	biorefinery[!,:R_ID] = 1:size(collect(skipmissing(biorefinery[!,1])),1)

	# Store DataFrame of capture units/resources input data for use
	inputs_biorefinery["dfbiorefinery"] = biorefinery

	# Index of BIO resources - can be either commit, no_commit capture technologies, demand side, G2P, or storage resources
	inputs_biorefinery["BIO_RES_ALL"] = size(collect(skipmissing(biorefinery[!,:R_ID])),1)

	inputs_biorefinery["BIO_H2"] = biorefinery[biorefinery.BioH2_Production.== 1 ,:R_ID]

	inputs_biorefinery["BIO_E"] = biorefinery[biorefinery.BioElectricity_Production.== 1 ,:R_ID]

	# Name of CO2 capture resources
	inputs_biorefinery["BIO_RESOURCES_NAME"] = collect(skipmissing(biorefinery[!,:Biorefinery][1:inputs_biorefinery["BIO_RES_ALL"]]))

	# Resource identifiers by zone (just zones in resource order + resource and zone concatenated)
	bio_zones = collect(skipmissing(biorefinery[!,:Zone][1:inputs_biorefinery["BIO_RES_ALL"]]))
	inputs_biorefinery["BIO_R_ZONES"] = bio_zones
	inputs_biorefinery["BIO_RESOURCE_ZONES"] = inputs_biorefinery["BIO_RESOURCES_NAME"] .* "_z" .* string.(bio_zones)

	##############################################################################################################################################

	# Set of plants accepting herbaceous biomass
	inputs_biorefinery["BIO_HERB"] = biorefinery[biorefinery.Biomass_type.== 1 ,:R_ID]

	# Set of plants accepting woody biomass
	inputs_biorefinery["BIO_WOOD"] = biorefinery[biorefinery.Biomass_type.== 2 ,:R_ID]

	println("BESC_Biorefinery.csv Successfully Read!")

    return inputs_biorefinery

end

