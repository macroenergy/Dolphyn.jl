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
    ng_emissions(EP::Model, inputs::Dict, setup::Dict)

This function creates expression to add the CO2 emissions for natural gas supply chain in each zone, which is subsequently added to the total emissions. 

These include emissions from synthetic natural gas production (if any), as well as combustion of each type of conventional and synthetic natural gas.
"""
function ng_emissions(EP::Model, inputs::Dict, setup::Dict)

	println(" -- CO2 Emissions Module for Natural Gas")

    Conventional_ng_co2_per_mmbtu = inputs["Conventional_ng_co2_per_mmbtu"]

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
    ##########################################################
    ##CO2 emitted as a result of conventional natural gas consumption
    @expression(EP,eConv_NG_CO2_Emissions[z=1:Z,t=1:T], 
    Conventional_ng_co2_per_mmbtu * EP[:vConv_NG_Demand][t,z])
       
    ######################################################################
    ##CO2 emitted as a result of synthetic ng production and consumption

    #if setup["ModelSyntheticNG"] == 1
    #    dfSNG = inputs["dfSNG"]
    #    SYN_NG_RES_ALL = inputs["SYN_NG_RES_ALL"]
    #end

    #Syn_ng_co2_per_mmbtu = inputs["Syn_ng_co2_per_mmbtu"]

    #if setup["ModelSyntheticNG"] == 1

        #CO2 emitted per type of resource "k"
        #@expression(EP,eSyn_NG_CO2_Emissions_By_Res[k=1:SYN_NG_RES_ALL,t=1:T], 
        #dfSNG[!,:co2_out_p_co2_in][k] * EP[:vSNGCO2in][k,t])

        #CO2 captured per type of resource "k"
        #@expression(EP,eSyn_NG_CO2_Captured_By_Res[k=1:SYN_NG_RES_ALL,t=1:T], 
        #dfSNG[!,:co2_captured_p_co2_in][k] * EP[:vSNGCO2in][k,t])

        #Total CO2 capture per zone per time
        #@expression(EP, eSyn_NG_CO2_Capture_Per_Zone_Per_Time[z=1:Z, t=1:T], 
        #sum(eSyn_NG_CO2_Captured_By_Res[k,t] for k in dfSNG[(dfSNG[!,:Zone].==z),:R_ID]))

        #@expression(EP, eSyn_NG_CO2_Capture_Per_Time_Per_Zone[t=1:T, z=1:Z], 
        #sum(eSyn_NG_CO2_Captured_By_Res[k,t] for k in dfSNG[(dfSNG[!,:Zone].==z),:R_ID]))

        #ADD TO CO2 BALANCE
        #EP[:eCaptured_CO2_Balance] += EP[:eSyn_NG_CO2_Capture_Per_Time_Per_Zone]

        #CO2 emitted by syn ng production per zone
        #@expression(EP, eSyn_NG_Production_CO2_Emissions_By_Zone[z=1:Z, t=1:T], 
        #sum(eSyn_NG_CO2_Emissions_By_Res[k,t] for k in dfSNG[(dfSNG[!,:Zone].==z),:R_ID]))

        #CO2 emitted as a result of syn ng consumption
        #@expression(EP,eSyn_NG_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
        #Syn_ng_co2_per_mmbtu * EP[:eSynFuelProd_NG][t,z])

    #end

    return EP
end
