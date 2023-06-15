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


function load_bio_supply(setup::Dict, path::AbstractString, sep::AbstractString, inputs_bio_supply::Dict)

	if setup["BIO_Nonlinear_Supply"] == 1

		Herb_biomass_quantity_df = DataFrame(CSV.File(string(path,sep,"BESC_Herb_Supply_Quantity.csv"), header=true), copycols=true)
		Herb_biomass_cost_df = DataFrame(CSV.File(string(path,sep,"BESC_Herb_Supply_Cost.csv"), header=true), copycols=true)
		Herb_biomass_emission_df = DataFrame(CSV.File(string(path,sep,"BESC_Herb_Supply_Emission.csv"), header=true), copycols=true)

		inputs_bio_supply["Herb_biomass_quantity_df"] = Herb_biomass_quantity_df
		inputs_bio_supply["Herb_biomass_cost_df"] = Herb_biomass_cost_df
		inputs_bio_supply["Herb_biomass_emission_df"] = Herb_biomass_emission_df
	
		Herb_quantity_start = findall(s -> s == "Quantity_tonne_per_hr_z1", names(Herb_biomass_quantity_df))[1]
		Herb_cost_start = findall(s -> s == "Biomass_cost_z1", names(Herb_biomass_cost_df))[1]
		Herb_emission_start = findall(s -> s == "Emission_tonne_per_hr_z1", names(Herb_biomass_emission_df))[1]
	
		inputs_bio_supply["Herb_biomass_quantity_per_h"] = Matrix(Herb_biomass_quantity_df[:,Herb_quantity_start:Herb_quantity_start-1+inputs_bio_supply["Z"]])
		inputs_bio_supply["Herb_biomass_cost_per_h"] = Matrix(Herb_biomass_cost_df[:,Herb_cost_start:Herb_cost_start-1+inputs_bio_supply["Z"]])
		inputs_bio_supply["Herb_biomass_emission_per_h"] = Matrix(Herb_biomass_emission_df[:,Herb_emission_start:Herb_emission_start-1+inputs_bio_supply["Z"]])
	
		println("Herb Biomass Supply Curves Successfully Read!")
	
		##############################################################################################################################################
	
		Wood_biomass_quantity_df = DataFrame(CSV.File(string(path,sep,"BESC_Wood_Supply_Quantity.csv"), header=true), copycols=true)
		Wood_biomass_cost_df = DataFrame(CSV.File(string(path,sep,"BESC_Wood_Supply_Cost.csv"), header=true), copycols=true)
		Wood_biomass_emission_df = DataFrame(CSV.File(string(path,sep,"BESC_Wood_Supply_Emission.csv"), header=true), copycols=true)
	
		inputs_bio_supply["Wood_biomass_quantity_df"] = Wood_biomass_quantity_df
		inputs_bio_supply["Wood_biomass_cost_df"] = Wood_biomass_cost_df
		inputs_bio_supply["Wood_biomass_emission_df"] = Wood_biomass_emission_df
	
		Wood_quantity_start = findall(s -> s == "Quantity_tonne_per_hr_z1", names(Wood_biomass_quantity_df))[1]
		Wood_cost_start = findall(s -> s == "Biomass_cost_z1", names(Wood_biomass_cost_df))[1]
		Wood_emission_start = findall(s -> s == "Emission_tonne_per_hr_z1", names(Wood_biomass_emission_df))[1]
	
		inputs_bio_supply["Wood_biomass_quantity_per_h"] = Matrix(Wood_biomass_quantity_df[:,Wood_quantity_start:Wood_quantity_start-1+inputs_bio_supply["Z"]])
		inputs_bio_supply["Wood_biomass_cost_per_h"] = Matrix(Wood_biomass_cost_df[:,Wood_cost_start:Wood_cost_start-1+inputs_bio_supply["Z"]])
		inputs_bio_supply["Wood_biomass_emission_per_h"] = Matrix(Wood_biomass_emission_df[:,Wood_emission_start:Wood_emission_start-1+inputs_bio_supply["Z"]])
	
		println("Wood Biomass Supply Curves Successfully Read!")
	
	else
		inputs_bio_supply["Herb_biomass_supply_df"] = DataFrame(CSV.File(string(path,sep,"BESC_Herb_Linear_Supply.csv"), header=true), copycols=true)
		println("Herb Biomass Supply Curves Successfully Read!")

		inputs_bio_supply["Wood_biomass_supply_df"] = DataFrame(CSV.File(string(path,sep,"BESC_Wood_Linear_Supply.csv"), header=true), copycols=true)
		println("Wood Biomass Supply Curves Successfully Read!")
	end

    return inputs_bio_supply

end

