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
    emissions_besc(EP::Model, inputs::Dict, setup::Dict)

This function creates expression to add the CO2 emissions from the biorefinery, negative emissions from the biomass utilization, and add any CO2 captured from the biorefinery to the captured CO2 inventory.
"""
function emissions_besc(EP::Model, inputs::Dict, setup::Dict)

	println("CO2 Capture and Emissions Module for Biorefineries")

	dfbioenergy = inputs["dfbioenergy"]
    BIO_RES_ALL = inputs["BIO_RES_ALL"]

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

    #Bioenergy carbon balance:
    #Biomass CO2 captured = Biorefinery emissions + bioenergy capture to storage + biofuel emissions
    #Biorefinery capture to storage is added to CO2 storage balance
    #Net negative emission = Biorefinery capture to storage

    #####################################################################################################################################
    #Biomass CO2 capture per plant per time
    @expression(EP, eBiomass_CO2_captured_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:Biomass_tonne_CO2_per_tonne][i])

    #Total biomass CO2 capture per zone per time
    @expression(EP, eBiomass_CO2_captured_per_zone_per_time[z in 1:Z, t in 1:T], sum(EP[:eBiomass_CO2_captured_per_plant_per_time][i,t] for i in dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID]))
    
    #####################################################################################################################################
   
    #Biorefinery CO2 emissions per plant per time
    @expression(EP, eBiorefinery_CO2_emissions_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:CO2_emissions_tonne_per_tonne][i])
    #per zone per time (Add to CO2 emissions)
    @expression(EP, eBiorefinery_CO2_emissions_per_zone_per_time[z in 1:Z, t in 1:T], sum(EP[:eBiorefinery_CO2_emissions_per_plant_per_time][i,t] for i in dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID]))

    #####################################################################################################################################
    #Biorefinery CO2 capture to storage per plant per time
    @expression(EP, eBiorefinery_CO2_captured_per_plant_per_time[i in 1:BIO_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time][i,t] * dfbioenergy[!,:CO2_capture_tonne_per_tonne][i])

    #Total CO2 capture to storage per zone per time
    @expression(EP, eBiorefinery_CO2_captured_per_zone_per_time[z in 1:Z, t in 1:T], sum(EP[:eBiorefinery_CO2_captured_per_plant_per_time][i,t] for i in dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID]))
    
    @expression(EP, eBiorefinery_CO2_captured_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBiorefinery_CO2_captured_per_plant_per_time][i,t] for i in dfbioenergy[dfbioenergy[!,:Zone].==z,:][!,:R_ID]))

    #ADD TO CO2 BALANCE
    EP[:eCaptured_CO2_Balance] += EP[:eBiorefinery_CO2_captured_per_time_per_zone]

    return EP
end
