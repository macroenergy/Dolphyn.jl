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
	emissions(EP::Model, inputs::Dict, UCommit::Int)

This function creates expression to add the CO2 capture and emissions by biorefineries in each zone
"""
function emissions_besc(EP::Model, inputs::Dict, setup::Dict)

	println("CO2 Capture and Emissions Module for Biorefineries")

	dfbiorefinery = inputs["dfbiorefinery"]
    BIO_RES_ALL = inputs["BIO_RES_ALL"]

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
    #CO2 emissions per plant per time
    @expression(EP, eBiorefinery_CO2_emissions_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbiorefinery[!,:CO2_emissions_tonne_per_tonne][i])
    #per zone per time (Add to CO2 emissions)
    @expression(EP, eBiorefinery_CO2_emissions_per_zone_per_time[z in 1:Z, t in 1:T], sum(EP[:eBiorefinery_CO2_emissions_per_plant_per_time][i,t] for i in dfbiorefinery[dfbiorefinery[!,:Zone].==z,:][!,:R_ID]))

    @expression(EP, eBIO_CO2_emissions_per_zone_per_time[z in 1:Z, t in 1:T], EP[:eBiorefinery_CO2_emissions_per_zone_per_time][z,t] + EP[:eHerb_biomass_emission_per_zone_per_time][z,t] + EP[:eWood_biomass_emission_per_zone_per_time][z,t])

    #####################################################################################################################################
    #CO2 capture per plant per time
    @expression(EP, eBIO_CO2_captured_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbiorefinery[!,:CO2_capture_tonne_per_tonne][i])

    #Total CO2 capture per zone per time
    @expression(EP, eBIO_CO2_captured_per_zone_per_time[z in 1:Z, t in 1:T], sum(EP[:eBIO_CO2_captured_per_plant_per_time][i,t] for i in dfbiorefinery[dfbiorefinery[!,:Zone].==z,:][!,:R_ID]))
    
    @expression(EP, eBIO_CO2_captured_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBIO_CO2_captured_per_plant_per_time][i,t] for i in dfbiorefinery[dfbiorefinery[!,:Zone].==z,:][!,:R_ID]))

    #ADD TO CO2 BALANCE
    EP[:eCaptured_CO2_Balance] += EP[:eBIO_CO2_captured_per_time_per_zone]

    return EP
end
