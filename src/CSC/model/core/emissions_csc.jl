"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
	emissions(EP::Model, inputs::Dict, UCommit::Int)

This function creates expression to add the net CO2 captured by plants in each zone, which is subsequently deducted to the total emissions
"""
function emissions_csc(EP::Model, inputs::Dict, setup::Dict)

	println("CO2 Emissions Module for CO2 Policy modularization")

	dfCO2Capture = inputs["dfCO2Capture"]
    CO2_RES_ALL = inputs["CO2_RES_ALL"]

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
    # If setup["ParameterScale] = 1, emissions expression and constraints are written in ktonnes
    # If setup["ParameterScale] = 0, emissions expression and constraints are written in tonnes
    # Adjustment of Fuel_CO2 units carried out in load_fuels_data.jl

    #CO2 emitted by fuel usage per type of resource "k"
    @expression(EP,eDAC_Fuel_CO2_Production_per_type[k=1:CO2_RES_ALL,t=1:T], 
        inputs["fuel_CO2"][dfCO2Capture[!,:Fuel][k]] * dfCO2Capture[!,:etaFuel_MMBtu_p_tonne][k] * EP[:vDAC_CO2_Captured][k,t])
    
    #Total negative emission = Total amount of CO2 capture - CO2 emitted by fuel usage (per type of resource "k")
	@expression(EP, eDAC_Negative_Emissions_per_type[k=1:CO2_RES_ALL,t=1:T], 
        EP[:vDAC_CO2_Captured][k,t] - EP[:eDAC_Fuel_CO2_Production_per_type][k,t]) 
    
    #Total negative emission per zone
 	@expression(EP, eDAC_Negative_Emissions_per_zone[z=1:Z, t=1:T], sum(eDAC_Negative_Emissions_per_type[k,t] for k in dfCO2Capture[(dfCO2Capture[!,:Zone].==z),:R_ID]))

    return EP
end
