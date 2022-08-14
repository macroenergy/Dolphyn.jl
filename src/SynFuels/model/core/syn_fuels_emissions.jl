"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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
	
"""
function emissions_liquid_fuels(EP::Model, inputs::Dict, setup::Dict)

	println("CO2 Emissions Module for Liquid Fuels")

	dfSynFuels = inputs["dfSynFuels"]
    SYN_FUELS_RES_ALL = inputs["SYN_FUELS_RES_ALL"]
    Conventional_fuel_co2_per_mmbtu = inputs["Conventional_fuel_co2_per_mmbtu"]
    Syn_fuel_co2_per_mmbtu = inputs["Syn_fuel_co2_per_mmbtu"]

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
    # If setup["ParameterScale] = 1, emissions expression and constraints are written in ktonnes
    # If setup["ParameterScale] = 0, emissions expression and constraints are written in tonnes
    # Adjustment of Fuel_CO2 units carried out in load_fuels_data.jl

    #CO2 emitted by fuel usage per type of resource "k"
    @expression(EP,eSyn_Fuels_CO2_Emissions_By_Res[k=1:SYN_FUELS_RES_ALL,t=1:T], 
        inputs["fuel_CO2"][dfSynFuels[!,:Fuel][k]] * dfSynFuels[!,:mmbtu_ng_p_tonne_co2][k] * EP[:vSFCO2in][k,t])

    #CO2 Emitted as a result of syn fuel consumption
    @expression(EP,eSyn_Fuels_Cons_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
        Syn_fuel_co2_per_mmbtu * EP[:eSynFuelProdNoCommit][t,z])
    
    #CO2 emitted as a result of conventional fuel consumption
    @expression(EP,eLiquid_Fuels_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
    Conventional_fuel_co2_per_mmbtu * EP[:vConvLFDemand][t,z])

    return EP
end
