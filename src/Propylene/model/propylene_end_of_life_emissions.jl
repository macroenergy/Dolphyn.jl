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

"""
function propylene_end_of_life_emissions(EP::Model, inputs::Dict, setup::Dict)

	println(" -- CO2 Emissions Module for Propylene end of life")



    ###########################################################  VERSION 1 #############################################################
## Step 1: load the saved information

    Propylene_EoL_co2_per_tonne = inputs["Propylene_EoL_co2_per_tonne"]
    # Propylene_EoL_co2_per_tonne = 22/7 #inputs["Propylene_EoL_co2_per_tonne"]
    # Conventional_Propylene_co2_per_tonne = inputs["Propylene_co2_per_tonne"]
# Greenfield projects:
    dfEthylene = inputs["dfEthylene"]
    Ethylene_RES_ALL = inputs["Ethylene_RES_ALL"]
    #tonne_co2_p_tonne_ethylene = dfEthylene[!,:tonne_co2_p_tonne_ethylene]
    #CO2_emissions_Combustion_per_tethylene = dfEthylene[!,:CO2_emissions_Combustion_per_tethylene]
    #Fractional_combustion = dfEthylene[!,:Fractional_combustion]
    #CoProd_CO2_Emissions = dfEthylene[!,:CoProd_CO2_Emissions]
    
# Existing plants:
    dfEthylene_plants = inputs["dfEthylene_plants"]
    Ethylene_Plants_ALL = inputs["Ethylene_Plants_ALL"]
    #Plant_tonne_co2_p_tonne_ethylene = dfEthylene_plants[!,:Plant_tonne_co2_p_tonne_ethylene]
    #Plants_CO2_emissions_Combustion_per_tethylene = dfEthylene_plants[!,:Plants_CO2_emissions_Combustion_per_tethylene]
    #Plants_Fractional_combustion = dfEthylene_plants[!,:Plants_Fractional_combustion]
    #Plants_CoProd_CO2_Emissions = dfEthylene_plants[!,:Plants_CoProd_CO2_Emissions]

# Other quantities:
    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones

    # FCC Purchase
    #@expression(EP,ePropylene_CO2_Combustion_Emissions_By_Conv[k=1:Ethylene_RES_ALL,t=1:T],Propylene_EoL_co2_per_tonne * EP[:eEthylene_Propylene_RES][k,t])
    #@expression(EP,ePropylene_CO2_Combustion_Emissions_By_Zone_GF[z = 1:Z,t=1:T], sum(ePropylene_CO2_Combustion_Emissions_By_RES[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))
    
    #@expression(EP,eConv_Propylene_CO2_Emissions[z=1:Z,t=1:T], Conventional_Propylene_co2_per_tonne * EP[:vConv_Propylene_Demand][t,z])
    
    if setup["ModelEthyleneProduction"] == 1

        # Green field projects: Estimation for emissions from combustion
        @expression(EP,ePropylene_CO2_Combustion_Emissions_By_RES[k=1:Ethylene_RES_ALL,t=1:T],Propylene_EoL_co2_per_tonne * EP[:vEthylene_Propylene_GF][k,t])
        @expression(EP,ePropylene_CO2_Combustion_Emissions_By_Zone_GF[z = 1:Z,t=1:T], sum(ePropylene_CO2_Combustion_Emissions_By_RES[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))

        # @expression(EP,eEthylene_CO2_Combustion_Emissions_By_RES[k=1:Ethylene_RES_ALL,t=1:T],CO2_emissions_Combustion_per_tethylene[k] * Fractional_combustion[k] * EP[:eEthylene_Prod_RES][k,t])

        if setup["ModelEthylenePlants"] == 1

            # Green field projects: Estimation for emissions from combustion
            @expression(EP,ePropylene_CO2_Combustion_Emissions_By_Plant[k=1:Ethylene_Plants_ALL,t=1:T],Propylene_EoL_co2_per_tonne * EP[:vEthylene_Propylene_EP][k,t])
            @expression(EP,ePropylene_CO2_Combustion_Emissions_By_Zone_EP[z = 1:Z,t=1:T], sum(ePropylene_CO2_Combustion_Emissions_By_Plant[k,t] for k in dfEthylene_plants[(dfEthylene_plants[!,:Plant_Zone].==z),:R_ID]))

        end


        if setup["ModelEthyleneRetrofitting"] == 1  

            dfEthylene_retrofit = inputs["dfEthylene_retrofit"]
            Ethylene_retrofit_ALL = inputs["Ethylene_retrofit_ALL"]
            #Retrofit_tonne_co2_p_tonne_ethylene = dfEthylene_retrofit[!,:Retrofit_tonne_co2_p_tonne_ethylene]
            #Retrofit_CO2_emissions_Combustion_per_tethylene = dfEthylene_retrofit[!,:Retrofit_CO2_emissions_Combustion_per_tethylene]
            #Retrofit_Fractional_combustion = dfEthylene_retrofit[!,:Retrofit_Fractional_combustion]
            #Retrofit_CoProd_CO2_Emissions = dfEthylene_retrofit[!,:Retrofit_CoProd_CO2_Emissions]

            # Retrofits projects: Estimation for emissions from combustion
            @expression(EP,ePropylene_CO2_Combustion_Emissions_By_Retrofit[k=1:Ethylene_retrofit_ALL,t=1:T],Propylene_EoL_co2_per_tonne * EP[:vEthylene_Propylene_Retrofit][k,t])
            @expression(EP,ePropylene_CO2_Combustion_Emissions_By_Zone_Retrofit[z = 1:Z,t=1:T], sum(ePropylene_CO2_Combustion_Emissions_By_Retrofit[k,t] for k in dfEthylene_retrofit[(dfEthylene_retrofit[!,:Retrofit_Zone].==z),:R_ID]))

            
        end

        

    end



    return EP
end
