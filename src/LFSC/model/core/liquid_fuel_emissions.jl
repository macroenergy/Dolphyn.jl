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
    liquid_fuel_emissions(EP::Model, inputs::Dict, setup::Dict)

This function creates expression to add the CO2 emissions for liquid fuels supply chain in each zone, which is subsequently added to the total emissions. 

These include emissions from synthetic fuels production and by-products (if any), as well as combustion of each type of conventional and synthetic fuels (gasoline, jetfuel and diesel).
"""
function liquid_fuel_emissions(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Liquid Fuels Emissions Module for CO2 Policy modularization")

    if setup["ModelSyntheticFuels"] == 1
        dfSynFuels = inputs["dfSynFuels"]
        SYN_FUELS_RES_ALL = inputs["SYN_FUELS_RES_ALL"]
        NSFByProd = inputs["NSFByProd"] #Number of by products
        dfSynFuelsByProdEmissions = inputs["dfSynFuelsByProdEmissions"]
    end

    Conventional_diesel_co2_per_mmbtu = inputs["Conventional_diesel_co2_per_mmbtu"]
    Syn_diesel_co2_per_mmbtu = inputs["Syn_diesel_co2_per_mmbtu"]
    
    Conventional_jetfuel_co2_per_mmbtu = inputs["Conventional_jetfuel_co2_per_mmbtu"]
    Syn_jetfuel_co2_per_mmbtu = inputs["Syn_jetfuel_co2_per_mmbtu"]

    Conventional_gasoline_co2_per_mmbtu = inputs["Conventional_gasoline_co2_per_mmbtu"]
    Syn_gasoline_co2_per_mmbtu = inputs["Syn_gasoline_co2_per_mmbtu"]

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
    # If setup["ParameterScale] = 1, emissions expression and constraints are written in ktonnes
    # If setup["ParameterScale] = 0, emissions expression and constraints are written in tonnes

    ##########################################################
    ##CO2 emitted as a result of conventional fuel consumption

    if setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 1

        if setup["ParameterScale"] ==1
            #CO2 emitted as a result of conventional diesel consumption
            @expression(EP,eConv_Diesel_CO2_Emissions[z=1:Z,t=1:T], 
            Conventional_diesel_co2_per_mmbtu * EP[:vConvLFDieselDemand][t,z]/ModelScalingFactor)

            #CO2 emitted as a result of conventional jetfuel consumption
            @expression(EP,eConv_Jetfuel_CO2_Emissions[z=1:Z,t=1:T], 
            Conventional_jetfuel_co2_per_mmbtu * EP[:vConvLFJetfuelDemand][t,z]/ModelScalingFactor)

            #CO2 emitted as a result of conventional gasoline consumption
            @expression(EP,eConv_Gasoline_CO2_Emissions[z=1:Z,t=1:T], 
            Conventional_gasoline_co2_per_mmbtu * EP[:vConvLFGasolineDemand][t,z]/ModelScalingFactor)
        else
            #CO2 emitted as a result of conventional diesel consumption
            @expression(EP,eConv_Diesel_CO2_Emissions[z=1:Z,t=1:T], 
            Conventional_diesel_co2_per_mmbtu * EP[:vConvLFDieselDemand][t,z])

            #CO2 emitted as a result of conventional jetfuel consumption
            @expression(EP,eConv_Jetfuel_CO2_Emissions[z=1:Z,t=1:T], 
            Conventional_jetfuel_co2_per_mmbtu * EP[:vConvLFJetfuelDemand][t,z])

            #CO2 emitted as a result of conventional gasoline consumption
            @expression(EP,eConv_Gasoline_CO2_Emissions[z=1:Z,t=1:T], 
            Conventional_gasoline_co2_per_mmbtu * EP[:vConvLFGasolineDemand][t,z])
        end

    elseif setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 0

        if setup["ParameterScale"] ==1
            #CO2 emitted as a result of conventional diesel consumption
            @expression(EP,eConv_Diesel_CO2_Emissions[z=1:Z], 
            Conventional_diesel_co2_per_mmbtu * EP[:vConvLFDieselDemand][z]/ModelScalingFactor)

            #CO2 emitted as a result of conventional jetfuel consumption
            @expression(EP,eConv_Jetfuel_CO2_Emissions[z=1:Z], 
            Conventional_jetfuel_co2_per_mmbtu * EP[:vConvLFJetfuelDemand][z]/ModelScalingFactor)

            #CO2 emitted as a result of conventional gasoline consumption
            @expression(EP,eConv_Gasoline_CO2_Emissions[z=1:Z], 
            Conventional_gasoline_co2_per_mmbtu * EP[:vConvLFGasolineDemand][z]/ModelScalingFactor)
        else
            #CO2 emitted as a result of conventional diesel consumption
            @expression(EP,eConv_Diesel_CO2_Emissions[z=1:Z], 
            Conventional_diesel_co2_per_mmbtu * EP[:vConvLFDieselDemand][z])

            #CO2 emitted as a result of conventional jetfuel consumption
            @expression(EP,eConv_Jetfuel_CO2_Emissions[z=1:Z], 
            Conventional_jetfuel_co2_per_mmbtu * EP[:vConvLFJetfuelDemand][z])

            #CO2 emitted as a result of conventional gasoline consumption
            @expression(EP,eConv_Gasoline_CO2_Emissions[z=1:Z], 
            Conventional_gasoline_co2_per_mmbtu * EP[:vConvLFGasolineDemand][z])
        end

    elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 1

        if setup["ParameterScale"] ==1
            #CO2 emitted as a result of conventional diesel consumption
            @expression(EP,eConv_Diesel_CO2_Emissions[t=1:T], 
            Conventional_diesel_co2_per_mmbtu * EP[:vConvLFDieselDemand][t]/ModelScalingFactor)

            #CO2 emitted as a result of conventional jetfuel consumption
            @expression(EP,eConv_Jetfuel_CO2_Emissions[t=1:T], 
            Conventional_jetfuel_co2_per_mmbtu * EP[:vConvLFJetfuelDemand][t]/ModelScalingFactor)

            #CO2 emitted as a result of conventional gasoline consumption
            @expression(EP,eConv_Gasoline_CO2_Emissions[t=1:T], 
            Conventional_gasoline_co2_per_mmbtu * EP[:vConvLFGasolineDemand][t]/ModelScalingFactor)
        else
            #CO2 emitted as a result of conventional diesel consumption
            @expression(EP,eConv_Diesel_CO2_Emissions[t=1:T], 
            Conventional_diesel_co2_per_mmbtu * EP[:vConvLFDieselDemand][t])

            #CO2 emitted as a result of conventional jetfuel consumption
            @expression(EP,eConv_Jetfuel_CO2_Emissions[t=1:T], 
            Conventional_jetfuel_co2_per_mmbtu * EP[:vConvLFJetfuelDemand][t])

            #CO2 emitted as a result of conventional gasoline consumption
            @expression(EP,eConv_Gasoline_CO2_Emissions[t=1:T], 
            Conventional_gasoline_co2_per_mmbtu * EP[:vConvLFGasolineDemand][t])
        end

    elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 0

        if setup["ParameterScale"] ==1
            #CO2 emitted as a result of conventional diesel consumption
            @expression(EP,eConv_Diesel_CO2_Emissions, 
            Conventional_diesel_co2_per_mmbtu * EP[:vConvLFDieselDemand]/ModelScalingFactor)

            #CO2 emitted as a result of conventional jetfuel consumption
            @expression(EP,eConv_Jetfuel_CO2_Emissions, 
            Conventional_jetfuel_co2_per_mmbtu * EP[:vConvLFJetfuelDemand]/ModelScalingFactor)

            #CO2 emitted as a result of conventional gasoline consumption
            @expression(EP,eConv_Gasoline_CO2_Emissions, 
            Conventional_gasoline_co2_per_mmbtu * EP[:vConvLFGasolineDemand]/ModelScalingFactor)
        else
            #CO2 emitted as a result of conventional diesel consumption
            @expression(EP,eConv_Diesel_CO2_Emissions, 
            Conventional_diesel_co2_per_mmbtu * EP[:vConvLFDieselDemand])

            #CO2 emitted as a result of conventional jetfuel consumption
            @expression(EP,eConv_Jetfuel_CO2_Emissions, 
            Conventional_jetfuel_co2_per_mmbtu * EP[:vConvLFJetfuelDemand])

            #CO2 emitted as a result of conventional gasoline consumption
            @expression(EP,eConv_Gasoline_CO2_Emissions, 
            Conventional_gasoline_co2_per_mmbtu * EP[:vConvLFGasolineDemand])
        end

    end

       
    
    ######################################################################
    ##CO2 emitted as a result of synthetic fuel production and consumption
    
    #Scale each constraint
    if setup["ModelSyntheticFuels"] == 1
        if setup["ParameterScale"] ==1
            #CO2 emitted by fuel usage per type of resource "k"
            #Adjustment of Fuel_CO2 units carried out in load_fuels_data.jl to kton CO2/MMBtu 
            #So we need to scale synfuels fuels utilization (MMBtu/tonne CO2 to MMBtu/kton CO2)
            @expression(EP,eSyn_Fuels_CO2_Emissions_Fuel_By_Res[k=1:SYN_FUELS_RES_ALL,t=1:T], 
                inputs["fuel_CO2"][dfSynFuels[!,:Fuel][k]] * dfSynFuels[!,:mmbtu_ng_p_tonne_co2][k] * EP[:vSFCO2in][k,t] * ModelScalingFactor)

        else
            #CO2 emitted by fuel usage per type of resource "k"
            @expression(EP,eSyn_Fuels_CO2_Emissions_Fuel_By_Res[k=1:SYN_FUELS_RES_ALL,t=1:T], 
                inputs["fuel_CO2"][dfSynFuels[!,:Fuel][k]] * dfSynFuels[!,:mmbtu_ng_p_tonne_co2][k] * EP[:vSFCO2in][k,t])

        end

        #CO2 emitted per type of resource "k" #No need to scale ratio
        @expression(EP,eSyn_Fuels_CO2_Emissions_By_Res[k=1:SYN_FUELS_RES_ALL,t=1:T], 
        dfSynFuels[!,:co2_out_p_co2_in][k] * EP[:vSFCO2in][k,t])

        #CO2 captured per type of resource "k" #No need to scale ratio
        @expression(EP,eSyn_Fuels_CO2_Captured_By_Res[k=1:SYN_FUELS_RES_ALL,t=1:T], 
        dfSynFuels[!,:co2_captured_p_co2_in][k] * EP[:vSFCO2in][k,t])

        #Total CO2 capture per zone per time
        @expression(EP, eSyn_Fuels_CO2_Capture_Per_Zone_Per_Time[z=1:Z, t=1:T], 
            sum(eSyn_Fuels_CO2_Captured_By_Res[k,t] for k in dfSynFuels[(dfSynFuels[!,:Zone].==z),:R_ID]))

        @expression(EP, eSyn_Fuels_CO2_Capture_Per_Time_Per_Zone[t=1:T, z=1:Z], 
            sum(eSyn_Fuels_CO2_Captured_By_Res[k,t] for k in dfSynFuels[(dfSynFuels[!,:Zone].==z),:R_ID]))

        #ADD TO CO2 BALANCE
        EP[:eCaptured_CO2_Balance] += EP[:eSyn_Fuels_CO2_Capture_Per_Time_Per_Zone]

        #CO2 emitted by fuel usage per zone
        @expression(EP, eSynfuels_Production_CO2_Emissions_By_Zone[z=1:Z, t=1:T], 
            sum(eSyn_Fuels_CO2_Emissions_By_Res[k,t] for k in dfSynFuels[(dfSynFuels[!,:Zone].==z),:R_ID]) +
            sum(eSyn_Fuels_CO2_Emissions_Fuel_By_Res[k,t] for k in dfSynFuels[(dfSynFuels[!,:Zone].==z),:R_ID]))

        #CO2 emitted as a result of syn fuel consumption
        if setup["ParameterScale"] ==1
            #CO2 emitted as a result of syn diesel consumption
            @expression(EP,eSyn_Diesel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
            Syn_diesel_co2_per_mmbtu * EP[:eSynFuelProd_Diesel][t,z]/ModelScalingFactor)

            #CO2 emitted as a result of syn jetfuel consumption
            @expression(EP,eSyn_Jetfuel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
            Syn_jetfuel_co2_per_mmbtu * EP[:eSynFuelProd_Jetfuel][t,z]/ModelScalingFactor)

            #CO2 emitted as a result of byproduct fuel consumption
            @expression(EP,eByProdConsCO2Emissions[k in 1:SYN_FUELS_RES_ALL, b in 1:NSFByProd, t = 1:T], 
            EP[:vSFByProd][k,b,t] * dfSynFuelsByProdEmissions[:,b][k]/ModelScalingFactor)

            #CO2 emitted as a result of syn gasoline consumption
            @expression(EP,eSyn_Gasoline_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
            Syn_gasoline_co2_per_mmbtu * EP[:eSynFuelProd_Gasoline][t,z]/ModelScalingFactor)

        else
            #CO2 emitted as a result of syn diesel consumption
            @expression(EP,eSyn_Diesel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
            Syn_diesel_co2_per_mmbtu * EP[:eSynFuelProd_Diesel][t,z])

            #CO2 emitted as a result of syn jetfuel consumption
            @expression(EP,eSyn_Jetfuel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
            Syn_jetfuel_co2_per_mmbtu * EP[:eSynFuelProd_Jetfuel][t,z])

            #CO2 emitted as a result of byproduct fuel consumption
            @expression(EP,eByProdConsCO2Emissions[k in 1:SYN_FUELS_RES_ALL, b in 1:NSFByProd, t = 1:T], 
            EP[:vSFByProd][k,b,t] * dfSynFuelsByProdEmissions[:,b][k])

            #CO2 emitted as a result of syn gasoline consumption
            @expression(EP,eSyn_Gasoline_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], 
            Syn_gasoline_co2_per_mmbtu * EP[:eSynFuelProd_Gasoline][t,z])

        end

        #CO2 emitted as a result of byproduct fuel consumption by zone, by-product, and time
        @expression(EP,eByProdConsCO2EmissionsByZoneB[b in 1:NSFByProd, z = 1:Z, t = 1:T], sum(EP[:eByProdConsCO2Emissions][k,b,t] for k in dfSynFuels[(dfSynFuels[!,:Zone].==z),:R_ID]))

        #CO2 emitted as a result of byproduct fuel consumption by zone and time
        @expression(EP,eByProdConsCO2EmissionsByZone[z = 1:Z, t = 1:T], sum(EP[:eByProdConsCO2EmissionsByZoneB][b,z,t] for b in 1:NSFByProd)) 
    end

    return EP
end
