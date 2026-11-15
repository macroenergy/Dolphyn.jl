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
function ethylene_emissions(EP::Model, inputs::Dict, setup::Dict)

	println(" -- CO2 Emissions Module for Ethylene")

    #=
    ConventionalSC_ethylene_co2_per_tonneethylene = inputs["ConventionalSC_ethylene_co2_per_tonneethylene"]
    Consumption_ethylene_co2_per_tonneethylene= inputs["Consumption_ethylene_co2_per_tonneethylene"]
    

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

    if setup["ModelEthylenePurchase"] == 1	
    ##########################################################
    ##CO2 emitted as a result of conventional Ethylene Purchase Consumption
        @expression(EP,eConv_Ethylene_CO2_Emissions[z=1:Z,t=1:T], 
        Consumption_ethylene_co2_per_tonneethylene * EP[:vConv_Ethylene_Demand][t,z])
    end
      
    ######################################################################
    ##CO2 emitted as a result of Ethylene production and consumption

    if setup["ModelEthyleneProduction"] == 1

        dfEthylene = inputs["dfEthylene"]
        Ethylene_RES_ALL = inputs["Ethylene_RES_ALL"]

        tonne_co2_p_tonne_ethylene = dfEthylene[!,:tonne_co2_p_tonne_ethylene] 
        ConventionalSC_ethylene_co2_per_tonneethylene = inputs["ConventionalSC_ethylene_co2_per_tonneethylene"]
        Consumption_ethylene_co2_per_tonneethylene = inputs["Consumption_ethylene_co2_per_tonneethylene"]
        # tonne_co2_p_tonne_ethane = inputs["tonne_co2_p_tonne_ethane"]

        #CO2 emitted as a result of Ethylene Production
        

        #@expression(EP,eEthylene_CO2_Emissions_By_Plant[k=1:Ethylene_RES_ALL,t=1:T], 
        #Consumption_ethylene_co2_per_tonneethylene * EP[:eEthylene_Prod_Plant][k,t])

        ####################################### Old Code  ##################################
        #@expression(EP,eEthylene_CO2_Emissions_By_Plant[k=1:Ethylene_RES_ALL,t=1:T], 
        #tonne_co2_p_tonne_ethane[k] * EP[:vEthylene_ethanein][k,t])
        ############################## ---------------- ###################################

        @expression(EP,eEthylene_CO2_Emissions_By_Plant[k=1:Ethylene_RES_ALL,t=1:T], 
        tonne_co2_p_tonne_ethylene[k] * EP[:eEthylene_Prod_Plant][k,t])

        @expression(EP,eEthylene_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
        sum(eEthylene_CO2_Emissions_By_Plant[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))

        ##########################################################################
        #Plant CO2 emissions per type of resource (Ethylene emissions) --- Before CCS
        @expression(EP,eEthylene_CO2_Production_By_Plant[k=1:Ethylene_RES_ALL,t=1:T], 
        EP[:eEthylene_CO2_Emissions_By_Plant][k,t])

        ##########################################################################
        #Plant CO2 captured per type of resource defined by CCS rate (Add to captured CO2 balance)
        @expression(EP,eEthylene_CO2_Captured_By_Res[k=1:Ethylene_RES_ALL,t=1:T], 
        dfEthylene[!,:CCS_Rate][k] * EP[:eEthylene_CO2_Production_By_Plant][k,t])

        #Total CO2 capture per zone per time
        @expression(EP, eEthylene_CO2_Capture_Per_Zone_Per_Time[z=1:Z, t=1:T], 
        sum(eEthylene_CO2_Captured_By_Res[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))

        @expression(EP, eEthylene_CO2_Capture_Per_Time_Per_Zone[t=1:T, z=1:Z], 
        sum(eEthylene_CO2_Captured_By_Res[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))

        #ADD TO CO2 BALANCE
        EP[:eCaptured_CO2_Balance] += EP[:eEthylene_CO2_Capture_Per_Time_Per_Zone]

        ##########################################################################
        #Plant CO2 emitted per type of resource --- After CCS (Add to CO2 cap policy)
        @expression(EP,eEthylene_CO2_Emissions_By_Res[k=1:Ethylene_RES_ALL,t=1:T], 
        (1 - dfEthylene[!,:CCS_Rate][k]) * EP[:eEthylene_CO2_Production_By_Plant][k,t])

        @expression(EP, eEthylene_Production_CO2_Emissions_By_Zone[z=1:Z, t=1:T], 
        sum(eEthylene_CO2_Emissions_By_Res[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))


    end

    =#

    ###########################################################  VERSION 2 #############################################################
## Step 1: load the saved information
# Greenfield projects:
    dfEthylene = inputs["dfEthylene"]
    Ethylene_RES_ALL = inputs["Ethylene_RES_ALL"]
    tonne_co2_p_tonne_ethylene = dfEthylene[!,:tonne_co2_p_tonne_ethylene]
    CO2_emissions_Combustion_per_tethylene = dfEthylene[!,:CO2_emissions_Combustion_per_tethylene]
    Fractional_combustion = dfEthylene[!,:Fractional_combustion]
    CoProd_CO2_Emissions = dfEthylene[!,:CoProd_CO2_Emissions]
    
# Existing plants:
    dfEthylene_plants = inputs["dfEthylene_plants"]
    Ethylene_Plants_ALL = inputs["Ethylene_Plants_ALL"]
    Plant_tonne_co2_p_tonne_ethylene = dfEthylene_plants[!,:Plant_tonne_co2_p_tonne_ethylene]
    Plants_CO2_emissions_Combustion_per_tethylene = dfEthylene_plants[!,:Plants_CO2_emissions_Combustion_per_tethylene]
    Plants_Fractional_combustion = dfEthylene_plants[!,:Plants_Fractional_combustion]
    Plants_CoProd_CO2_Emissions = dfEthylene_plants[!,:Plants_CoProd_CO2_Emissions]


# Other quantities:
    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones


    if setup["ModelEthyleneProduction"] == 1
        ## Step 2: Estimate the emissions from (a) conventional purchases, (b) green field projects, and (c) existing plants. 
        # Green field projects: Estimation for emissions
        @expression(EP,eEthylene_CO2_Emissions_By_RES[k=1:Ethylene_RES_ALL,t=1:T],tonne_co2_p_tonne_ethylene[k] * EP[:eEthylene_Prod_RES][k,t])
        @expression(EP,eEthylene_CO2_Emissions_By_Zone_GF[z = 1:Z,t=1:T], sum(eEthylene_CO2_Emissions_By_RES[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))


        # Green field projects: Estimation for emissions from combustion
        #@expression(EP,eEthylene_CO2_Combustion_Emissions_By_RES[k=1:Ethylene_RES_ALL,t=1:T],CO2_emissions_Combustion_per_tethylene[k] * Fractional_combustion[k] * EP[:eEthylene_Prod_RES][k,t])
        #@expression(EP,eEthylene_CO2_Combustion_Emissions_By_Zone_GF[z = 1:Z,t=1:T], sum(eEthylene_CO2_Combustion_Emissions_By_RES[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))

        # Green field projects: Co-products combustion
        #@expression(EP,eEthylene_CoProd_Combustion_Emissions_By_RES[k=1:Ethylene_RES_ALL,t=1:T],CoProd_CO2_Emissions[k] * EP[:vEthylene_C3plusout_GF][k,t])
        #@expression(EP,eEthylene_CoProd_Combustion_Emissions_By_Zone_GF[z = 1:Z,t=1:T], sum(eEthylene_CoProd_Combustion_Emissions_By_RES[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))


        # Green field projects: Estimation for CCS
        @expression(EP,eEthylene_CO2_Production_By_RES[k=1:Ethylene_RES_ALL,t=1:T], EP[:eEthylene_CO2_Emissions_By_RES][k,t])
        #@expression(EP,eEthylene_CO2_Captured_By_RES[k=1:Ethylene_RES_ALL,t=1:T], dfEthylene[!,:CCS_Rate][k] * EP[:eEthylene_CO2_Production_By_RES][k,t])
        @expression(EP,eEthylene_CO2_Captured_By_RES[k=1:Ethylene_RES_ALL,t=1:T], dfEthylene[!,:CCS_p_t_ethylene][k] * EP[:eEthylene_Prod_RES][k,t])
        

        @expression(EP, eEthylene_CO2_Capture_Per_Time_Per_Zone_GF[t=1:T, z=1:Z], sum(eEthylene_CO2_Captured_By_RES[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))
        @expression(EP, eEthylene_CO2_Capture_Per_Zone_Per_Time_GF[z=1:Z, t=1:T], sum(eEthylene_CO2_Captured_By_RES[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))
        EP[:eCaptured_CO2_Balance] += EP[:eEthylene_CO2_Capture_Per_Time_Per_Zone_GF]
        

        # Green field projects: Estimation for emissions after CCS
        @expression(EP,eEthylene_CO2_Emissions_By_RES2[k=1:Ethylene_RES_ALL,t=1:T], (1-dfEthylene[!,:CCS_Rate][k]) * EP[:eEthylene_CO2_Production_By_RES][k,t]-dfEthylene[!,:CCS_NG_Adj_p_t_ethylene][k] * EP[:eEthylene_Prod_RES][k,t])
        @expression(EP, eEthylene_Production_CO2_Emissions_By_Zone_GF[z=1:Z, t=1:T], sum(eEthylene_CO2_Emissions_By_RES2[k,t] for k in dfEthylene[(dfEthylene[!,:Zone].==z),:R_ID]))


        if setup["ModelEthylenePlants"] == 1        
        
            # Existing plants: Estimation for emissions
            @expression(EP,eEthylene_CO2_Emissions_By_Plant[k=1:Ethylene_Plants_ALL,t=1:T], Plant_tonne_co2_p_tonne_ethylene[k] * EP[:eEthylene_Prod_Plant][k,t])
            @expression(EP,eEthylene_CO2_Emissions_By_Zone_EP[z = 1:Z,t=1:T], sum(eEthylene_CO2_Emissions_By_Plant[k,t] for k in dfEthylene_plants[(dfEthylene_plants[!,:Plant_Zone].==z),:R_ID]))
  
            # Existing plants: Estimation for CCS
            @expression(EP,eEthylene_CO2_Production_By_Plant[k=1:Ethylene_Plants_ALL,t=1:T], EP[:eEthylene_CO2_Emissions_By_Plant][k,t])
            @expression(EP,eEthylene_CO2_Captured_By_Plant[k=1:Ethylene_Plants_ALL,t=1:T], dfEthylene_plants[!,:Plant_CCS_Rate][k] * EP[:eEthylene_CO2_Production_By_Plant][k,t])
        
            @expression(EP, eEthylene_CO2_Capture_Per_Zone_Per_Time_EP[z=1:Z, t=1:T], sum(eEthylene_CO2_Captured_By_Plant[k,t] for k in dfEthylene_plants[(dfEthylene_plants[!,:Plant_Zone].==z),:R_ID]))
            @expression(EP, eEthylene_CO2_Capture_Per_Time_Per_Zone_EP[t=1:T, z=1:Z], sum(eEthylene_CO2_Captured_By_Plant[k,t] for k in dfEthylene_plants[(dfEthylene_plants[!,:Plant_Zone].==z),:R_ID]))
            EP[:eCaptured_CO2_Balance] += EP[:eEthylene_CO2_Capture_Per_Time_Per_Zone_EP]
            # Existing plants: Estimation for emissions after CCS
            @expression(EP,eEthylene_CO2_Emissions_By_Plant2[k=1:Ethylene_Plants_ALL,t=1:T], (1-dfEthylene_plants[!,:Plant_CCS_Rate][k]) * EP[:eEthylene_CO2_Production_By_Plant][k,t])
            @expression(EP, eEthylene_Production_CO2_Emissions_By_Zone_EP[z=1:Z, t=1:T], sum(eEthylene_CO2_Emissions_By_Plant2[k,t] for k in dfEthylene_plants[(dfEthylene_plants[!,:Plant_Zone].==z),:R_ID]))

        end

        if setup["ModelEthyleneRetrofitting"] == 1  

            dfEthylene_retrofit = inputs["dfEthylene_retrofit"]
            Ethylene_retrofit_ALL = inputs["Ethylene_retrofit_ALL"]
            Retrofit_tonne_co2_p_tonne_ethylene = dfEthylene_retrofit[!,:Retrofit_tonne_co2_p_tonne_ethylene]
            Retrofit_CO2_emissions_Combustion_per_tethylene = dfEthylene_retrofit[!,:Retrofit_CO2_emissions_Combustion_per_tethylene]
            Retrofit_Fractional_combustion = dfEthylene_retrofit[!,:Retrofit_Fractional_combustion]
            Retrofit_CoProd_CO2_Emissions = dfEthylene_retrofit[!,:Retrofit_CoProd_CO2_Emissions]    
        
            # Existing plants: Estimation for emissions
            @expression(EP,eEthylene_CO2_Emissions_By_Retrofit[k=1:Ethylene_retrofit_ALL,t=1:T], Retrofit_tonne_co2_p_tonne_ethylene[k] * EP[:eEthylene_Prod_RetrofitRES][k,t])
            @expression(EP,eEthylene_CO2_Emissions_By_Zone_Retrofit[z = 1:Z,t=1:T], sum(eEthylene_CO2_Emissions_By_Retrofit[k,t] for k in dfEthylene_retrofit[(dfEthylene_retrofit[!,:Retrofit_Zone].==z),:R_ID]))
            
            
             # Existing plants: Estimation for CCS
            @expression(EP,eEthylene_CO2_Production_By_Retrofit[k=1:Ethylene_retrofit_ALL,t=1:T], EP[:eEthylene_CO2_Emissions_By_Retrofit][k,t])
            # @expression(EP,eEthylene_CO2_Captured_By_Retrofit[k=1:Ethylene_retrofit_ALL,t=1:T], dfEthylene_retrofit[!,:Retrofit_CCS_Rate][k] * EP[:eEthylene_CO2_Production_By_Retrofit][k,t])
            #@expression(EP,eEthylene_CO2_Captured_By_RES[k=1:Ethylene_RES_ALL,t=1:T], dfEthylene[!,:CCS_p_t_ethylene][k] * EP[:eEthylene_Prod_RES][k,t])
            @expression(EP,eEthylene_CO2_Captured_By_Retrofit[k=1:Ethylene_retrofit_ALL,t=1:T], dfEthylene_retrofit[!,:Retrofit_CCS_p_t_ethylene][k] * EP[:eEthylene_Prod_RetrofitRES][k,t])


            @expression(EP, eEthylene_CO2_Capture_Per_Zone_Per_Time_Retrofit[z=1:Z, t=1:T], sum(eEthylene_CO2_Captured_By_Retrofit[k,t] for k in dfEthylene_retrofit[(dfEthylene_retrofit[!,:Retrofit_Zone].==z),:R_ID]))
            @expression(EP, eEthylene_CO2_Capture_Per_Time_Per_Zone_Retrofit[t=1:T, z=1:Z], sum(eEthylene_CO2_Captured_By_Retrofit[k,t] for k in dfEthylene_retrofit[(dfEthylene_retrofit[!,:Retrofit_Zone].==z),:R_ID]))
            EP[:eCaptured_CO2_Balance] += EP[:eEthylene_CO2_Capture_Per_Time_Per_Zone_Retrofit]

            # Existing plants: Estimation for emissions after CCS
            #@expression(EP,eEthylene_CO2_Emissions_By_Retrofit2[k=1:Ethylene_retrofit_ALL,t=1:T], (1-dfEthylene_retrofit[!,:Retrofit_CCS_Rate][k]) * EP[:eEthylene_CO2_Production_By_Retrofit][k,t])
            @expression(EP,eEthylene_CO2_Emissions_By_Retrofit2[k=1:Ethylene_retrofit_ALL,t=1:T], (1-dfEthylene_retrofit[!,:Retrofit_CCS_Rate][k]) * EP[:eEthylene_CO2_Production_By_Retrofit][k,t] - dfEthylene_retrofit[!,:Retrofit_CCS_NG_Adj_p_t_ethylene][k]*EP[:eEthylene_Prod_RetrofitRES][k,t]) 
            #@expression(EP,eEthylene_CO2_Emissions_By_RES2[k=1:Ethylene_RES_ALL,t=1:T], (1-dfEthylene[!,:CCS_Rate][k]) * EP[:eEthylene_CO2_Production_By_RES][k,t]-dfEthylene[!,:CCS_NG_Adj_p_t_ethylene][k] * EP[:eEthylene_Prod_RES][k,t])
           
            @expression(EP, eEthylene_Production_CO2_Emissions_By_Zone_Retrofit[z=1:Z, t=1:T], sum(eEthylene_CO2_Emissions_By_Retrofit2[k,t] for k in dfEthylene_retrofit[(dfEthylene_retrofit[!,:Retrofit_Zone].==z),:R_ID]))
            

        end

    end



    return EP
end
