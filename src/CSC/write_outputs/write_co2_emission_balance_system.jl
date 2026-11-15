"""
GenX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
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
    write_co2_emission_balance_system(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting CO2 balance of resources across the entire system
"""
function write_co2_emission_balance_system(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## CO2 balance for each type of resources
	dfCO2Balance = Array{Any}
	rowoffset=2

<<<<<<< Updated upstream
    dfTemp1 = Array{Any}(nothing, T+rowoffset, 11)
    dfTemp1[1,1:size(dfTemp1,2)] = ["Power Emissions", "HSC Emissions", "CSC Emissions",  "Biorefinery Emissions", "Biomass Emissions", "Biomass Capture", "Synfuel Production Emissions", "Conventional Fuels", "Synfuels", "Biofuels", "Total"]
=======
    dfTemp1 = Array{Any}(nothing, T+rowoffset, 32)
    dfTemp1[1,1:size(dfTemp1,2)] = ["Power Emissions", "HSC Emissions", "CSC Emissions",  "Bio Elec Plant Emissions", "Biomass CO2 for Bio Elec", "Bio H2 Plant Emissions", "Biomass CO2 for Bio H2", "Bio LF Plant Emissions", "Biomass CO2 for Bio LF", "Bio NG Plant Emissions", "Biomass CO2 for Bio NG", "Bioresource Emissions", "Conventional NG", "Syn NG Plant Emissions", "Syn NG", "Bio NG", "Conventional Liquid Fuels", "Synfuel Plant Emissions" ,"Synfuels", "Biofuels", "NG Reduction from Power CCS", "NG Reduction from H2 CCS", "NG Reduction from DAC CCS", "Ethylene Emissions","Bio Ethanol Plant Emissions","Biomass CO2 for Bio Ethanol","Ethane Supply","Total","Ethylene Combustion","Ethylene CoProd Combustion","Propylene Sypply","Propylene Combustion"]
>>>>>>> Stashed changes
    for t in 1:T
        dfTemp1[t+rowoffset,1] = value(sum(EP[:eEmissionsByZone][z,t] for z in 1:Z))
        
        if setup["ModelH2"] == 1
            dfTemp1[t+rowoffset,2] = value(sum(EP[:eH2EmissionsByZone][z,t] for z in 1:Z))
        else
            dfTemp1[t+rowoffset,2] = 0
        end

        if setup["ModelCSC"] == 1 
            if setup["ModelCO2Pipelines"] == 1 && setup["CO2Pipeline_Loss"] == 1
                dfTemp1[t+rowoffset,3] = value(sum(EP[:eDAC_Emissions_per_zone_per_time][z,t] for z in 1:Z)) + value(sum(EP[:eCO2Loss_Pipes_zt][z,t] for z in 1:Z)) - value(sum(EP[:eDAC_CO2_Captured_per_zone_per_time][z,t] for z in 1:Z))
            else
                dfTemp1[t+rowoffset,3] = value(sum(EP[:eDAC_Emissions_per_zone_per_time][z,t] for z in 1:Z)) - value(sum(EP[:eDAC_CO2_Captured_per_zone_per_time][z,t] for z in 1:Z))
            end
        else
            dfTemp1[t+rowoffset,3] = 0
        end

<<<<<<< Updated upstream
        if setup["ModelBIO"] == 1
            dfTemp1[t+rowoffset,4] = value(sum(EP[:eBiorefinery_CO2_emissions_per_zone_per_time][z,t] for z in 1:Z))
            dfTemp1[t+rowoffset,5] = value(sum(EP[:eHerb_biomass_emission_per_zone_per_time][z,t] for z in 1:Z)) + value(sum(EP[:eWood_biomass_emission_per_zone_per_time][z,t] for z in 1:Z))
            dfTemp1[t+rowoffset,6] = - value(sum(EP[:eBiomass_CO2_captured_per_zone_per_time][z,t] for z in 1:Z))
        else
            dfTemp1[t+rowoffset,4] = 0
            dfTemp1[t+rowoffset,5] = 0
            dfTemp1[t+rowoffset,6] = 0
=======
        dfTemp1[t+rowoffset,4] = 0
        dfTemp1[t+rowoffset,5] = 0
        dfTemp1[t+rowoffset,6] = 0
        dfTemp1[t+rowoffset,7] = 0
        dfTemp1[t+rowoffset,8] = 0
        dfTemp1[t+rowoffset,9] = 0
        dfTemp1[t+rowoffset,10] = 0
        dfTemp1[t+rowoffset,11] = 0
        dfTemp1[t+rowoffset,12] = 0
        dfTemp1[t+rowoffset,25] = 0
        dfTemp1[t+rowoffset,26] = 0
        dfTemp1[t+rowoffset,27] = 0
        dfTemp1[t+rowoffset,28] = 0
        dfTemp1[t+rowoffset,29] = 0
        dfTemp1[t+rowoffset,30] = 0

        if setup["ModelBESC"] == 1

            if setup["Bio_ELEC_On"] == 1
                dfTemp1[t+rowoffset,4] = value(sum(EP[:eBio_ELEC_CO2_emissions_per_zone_per_time][z,t] for z in 1:Z))
                dfTemp1[t+rowoffset,5] = - value(sum(EP[:eBiomass_CO2_per_zone_per_time_ELEC][z,t] for z in 1:Z))
            end

            if setup["ModelH2"] == 1 && setup["Bio_H2_On"] == 1
                dfTemp1[t+rowoffset,6] = value(sum(EP[:eBio_H2_CO2_emissions_per_zone_per_time][z,t] for z in 1:Z))
                dfTemp1[t+rowoffset,7] = - value(sum(EP[:eBiomass_CO2_per_zone_per_time_H2][z,t] for z in 1:Z))
            end

            if setup["ModelLFSC"] == 1 && setup["Bio_LF_On"] == 1
                dfTemp1[t+rowoffset,8] = value(sum(EP[:eBio_LF_Plant_CO2_emissions_per_zone_per_time][z,t] for z in 1:Z))
                dfTemp1[t+rowoffset,9] = - value(sum(EP[:eBiomass_CO2_per_zone_per_time_LF][z,t] for z in 1:Z))
            end

            if setup["ModelNGSC"] == 1 && setup["Bio_NG_On"] == 1
                dfTemp1[t+rowoffset,10] = value(sum(EP[:eBio_NG_Plant_CO2_emissions_per_zone_per_time][z,t] for z in 1:Z))
                dfTemp1[t+rowoffset,11] = - value(sum(EP[:eBiomass_CO2_per_zone_per_time_NG][z,t] for z in 1:Z))
            end

            if setup["ModelEthanol"] == 1 && setup["Bio_Ethanol_On"] == 1
                if setup["ModelExclusiveEmissions"] == 1
                    dfTemp1[t+rowoffset,25] = value(sum(EP[:eEthanol_CO2_Emissions_By_RES2][z,t] for z in 1:Z))
                elseif setup["ModelExclusiveEmissions"] == 0
                    dfTemp1[t+rowoffset,25] = value(sum(EP[:eBio_Ethanol_Plant_CO2_emissions_per_zone_per_time][z,t] for z in 1:Z))
                end
                
                dfTemp1[t+rowoffset,26] = - value(sum(EP[:eBiomass_CO2_per_zone_per_time_Ethanol][z,t] for z in 1:Z))
            end

            if setup["Energy_Crops_Herb_Supply"] == 1
                dfTemp1[t+rowoffset,12] += value(sum(EP[:eHerb_biomass_emission_per_zone_per_time][z,t] for z in 1:Z))
            end

            if setup["Energy_Crops_Wood_Supply"] == 1
                dfTemp1[t+rowoffset,12] += value(sum(EP[:eWood_biomass_emission_per_zone_per_time][z,t] for z in 1:Z))
            end

            if setup["Agri_Res_Supply"] == 1
                dfTemp1[t+rowoffset,12] += value(sum(EP[:eAgri_Res_biomass_emission_per_zone_per_time][z,t] for z in 1:Z))
            end

            if setup["Agri_Process_Waste_Supply"] == 1
                dfTemp1[t+rowoffset,12] += value(sum(EP[:eAgri_Process_Waste_biomass_emission_per_zone_per_time][z,t] for z in 1:Z))
            end

            if setup["Agri_Forest_Supply"] == 1
                dfTemp1[t+rowoffset,12] += value(sum(EP[:eForest_biomass_emission_per_zone_per_time][z,t] for z in 1:Z))
            end


        end

        dfTemp1[t+rowoffset,13] = 0
        dfTemp1[t+rowoffset,14] = 0
        dfTemp1[t+rowoffset,15] = 0
        dfTemp1[t+rowoffset,16] = 0

        if setup["ModelNGSC"] == 1
            #Power sector and HSC NG raw emissions (before CCS) are displayed in "Power Emissions" and "H2 Emissions" columns
            dfTemp1[t+rowoffset,13] = value(sum(EP[:eConv_NG_CO2_Emissions][z,t] for z in 1:Z)) - value(sum(EP[:ePower_NG_CO2_emission_per_zone_per_time][z,t] for z in 1:Z)) - value(sum(EP[:eHydrogen_NG_CO2_emission_per_zone_per_time][z,t] for z in 1:Z))

            if setup["ModelSyntheticNG"] == 1
                dfTemp1[t+rowoffset,14] = value(sum(EP[:eSyn_NG_Production_CO2_Emissions_By_Zone][z,t] for z in 1:Z))
                dfTemp1[t+rowoffset,15] = value(sum(EP[:eSyn_NG_CO2_Emissions_By_Zone][z,t] for z in 1:Z))
            end

            if setup["ModelBESC"] == 1 && setup["Bio_NG_On"] == 1
                dfTemp1[t+rowoffset,16] = value(sum(EP[:eBio_NG_CO2_Emissions_By_Zone][z,t] for z in 1:Z))
            end
        end

        dfTemp1[t+rowoffset,17] = 0
        dfTemp1[t+rowoffset,18] = 0
        dfTemp1[t+rowoffset,19] = 0
        dfTemp1[t+rowoffset,20] = 0
        

        if setup["ModelLFSC"] == 1
            if setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 1
                dfTemp1[t+rowoffset,17] = value(sum(EP[:eConv_Diesel_CO2_Emissions][z,t] for z in 1:Z)) + value(sum(EP[:eConv_Jetfuel_CO2_Emissions][z,t] for z in 1:Z)) + value(sum(EP[:eConv_Gasoline_CO2_Emissions][z,t] for z in 1:Z))
                
            elseif setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 0
                dfTemp1[t+rowoffset,17] = "-"

            elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 1
                dfTemp1[t+rowoffset,17] = value(EP[:eConv_Diesel_CO2_Emissions][t]) + value(EP[:eConv_Jetfuel_CO2_Emissions][t]) + value(EP[:eConv_Gasoline_CO2_Emissions][t])
            
            elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 0
                dfTemp1[t+rowoffset,17] = "-"

            end

            if setup["ModelSyntheticFuels"] == 1 && setup["ModelChemicalProduction"] == 0 
                dfTemp1[t+rowoffset,18] = value(sum(EP[:eSynfuels_Production_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eByProdConsCO2EmissionsByZone][z,t] for z in 1:Z))
                dfTemp1[t+rowoffset,19] = value(sum(EP[:eSyn_Diesel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eSyn_Jetfuel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eSyn_Gasoline_CO2_Emissions_By_Zone][z,t] for z in 1:Z))
            end

            if setup["ModelSyntheticFuels"] == 1 && setup["ModelChemicalProduction"] == 1 
                dfTemp1[t+rowoffset,18] = value(sum(EP[:eSynfuels_Production_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eByProdConsCO2EmissionsByZone][z,t] for z in 1:Z))
                dfTemp1[t+rowoffset,19] = value(sum(EP[:eSyn_Diesel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eSyn_Jetfuel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eSyn_Gasoline_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eCO2_Gasoline_CO2_Emissions_By_Zone][z,t] for z in 1:Z))
            end

            if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
                dfTemp1[t+rowoffset,20] = value(sum(EP[:eBio_Diesel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eBio_Jetfuel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eBio_Gasoline_CO2_Emissions_By_Zone][z,t] for z in 1:Z))
            end
        end

        dfTemp1[t+rowoffset,21] = 0
        dfTemp1[t+rowoffset,22] = 0
        dfTemp1[t+rowoffset,23] = 0
        dfTemp1[t+rowoffset,24] = 0
        dfTemp1[t+rowoffset,32] = 0

        if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthylenePlants"] == 1 && setup["ModelEthyleneEndOfLife"] == 1 && setup["ModelEthyleneRetrofitting"] == 0
            dfTemp1[t+rowoffset,24] = value(sum(EP[:eEthylene_Production_CO2_Emissions_By_Zone_GF][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_Production_CO2_Emissions_By_Zone_EP][z,t] for z in 1:Z))
       	    dfTemp1[t+rowoffset,29] = value(sum(EP[:eEthylene_CO2_Combustion_Emissions_By_Zone_GF][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_CO2_Combustion_Emissions_By_Zone_EP][z,t] for z in 1:Z))
			dfTemp1[t+rowoffset,30] = value(sum(EP[:eEthylene_CoProd_Combustion_Emissions_By_Zone_GF][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_CoProd_Combustion_Emissions_By_Zone_EP][z,t] for z in 1:Z))
			
        end

        if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthylenePlants"] == 1 && setup["ModelPropyleneEndOfLife"] == 1 && setup["ModelEthyleneRetrofitting"] == 1
       	    dfTemp1[t+rowoffset,32] = value(sum(EP[:ePropylene_CO2_Combustion_Emissions_By_Zone_GF][z,t] for z in 1:Z)) + value(sum(EP[:ePropylene_CO2_Combustion_Emissions_By_Zone_EP][z,t] for z in 1:Z)) + value(sum(EP[:eConv_Propylene_CO2_Emissions_EoL][z,t] for z in 1:Z)) + value(sum(EP[:ePropylene_CO2_Combustion_Emissions_By_Zone_Retrofit][z,t] for z in 1:Z))
		
        end

        if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthylenePlants"] == 1 && setup["ModelEthyleneEndOfLife"] == 1 && setup["ModelEthyleneRetrofitting"] == 1
            dfTemp1[t+rowoffset,24] = value(sum(EP[:eEthylene_Production_CO2_Emissions_By_Zone_GF][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_Production_CO2_Emissions_By_Zone_EP][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_Production_CO2_Emissions_By_Zone_Retrofit][z,t] for z in 1:Z))
       	    dfTemp1[t+rowoffset,29] = value(sum(EP[:eEthylene_CO2_Combustion_Emissions_By_Zone_GF][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_CO2_Combustion_Emissions_By_Zone_EP][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_CO2_Combustion_Emissions_By_Zone_Retrofit][z,t] for z in 1:Z))
			dfTemp1[t+rowoffset,30] = value(sum(EP[:eEthylene_CoProd_Combustion_Emissions_By_Zone_GF][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_CoProd_Combustion_Emissions_By_Zone_EP][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_CoProd_Combustion_Emissions_By_Zone_Retrofit][z,t] for z in 1:Z))
			
        end

        if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthylenePlants"] == 1 && setup["ModelEthyleneEndOfLife"] == 0 && setup["ModelEthyleneRetrofitting"] == 0
            dfTemp1[t+rowoffset,24] = value(sum(EP[:eEthylene_Production_CO2_Emissions_By_Zone_GF][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_Production_CO2_Emissions_By_Zone_EP][z,t] for z in 1:Z))
       	    dfTemp1[t+rowoffset,29] = 0
			dfTemp1[t+rowoffset,30] = 0			
        end

        
        if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthylenePlants"] == 1 && setup["ModelEthyleneEndOfLife"] == 0 && setup["ModelEthyleneRetrofitting"] == 1
            dfTemp1[t+rowoffset,24] = value(sum(EP[:eEthylene_Production_CO2_Emissions_By_Zone_GF][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_Production_CO2_Emissions_By_Zone_EP][z,t] for z in 1:Z)) + value(sum(EP[:eEthylene_Production_CO2_Emissions_By_Zone_Retrofit][z,t] for z in 1:Z))
       	    dfTemp1[t+rowoffset,29] = 0
			dfTemp1[t+rowoffset,30] = 0			
        end


        dfTemp1[t+rowoffset,31] = 0


        if setup["ModelEthanePurchase"] == 1
            dfTemp1[t+rowoffset,27] = value(sum(EP[:eConv_ethane_CO2_Emissions][z,t] for z in 1:Z)) 
        end

        if setup["ModelPropylenePurchase"] == 1
            dfTemp1[t+rowoffset,31] = value(sum(EP[:eConv_Propylene_CO2_Emissions][z,t] for z in 1:Z)) 
        end


        if setup["ModelNGSC"] == 1
            dfTemp1[t+rowoffset,21] = -value(sum(EP[:ePower_NG_CO2_captured_per_zone_per_time][z,t] for z in 1:Z))

            if setup["ModelH2"] == 1
                dfTemp1[t+rowoffset,22] = -value(sum(EP[:eHydrogen_NG_CO2_captured_per_zone_per_time][z,t] for z in 1:Z))
            end

            if setup["ModelCSC"] == 1
                dfTemp1[t+rowoffset,23] = -value(sum(EP[:eDAC_NG_CO2_captured_per_zone_per_time][z,t] for z in 1:Z))
            end
>>>>>>> Stashed changes
        end

        if setup["ModelLiquidFuels"] == 1
            dfTemp1[t+rowoffset,7] = value(sum(EP[:eSyn_Fuels_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eByProdConsCO2EmissionsByZone][z,t] for z in 1:Z))
            dfTemp1[t+rowoffset,8] = value(sum(EP[:eLiquid_Fuels_Con_Diesel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eLiquid_Fuels_Con_Jetfuel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eLiquid_Fuels_Con_Gasoline_CO2_Emissions_By_Zone][z,t] for z in 1:Z))
            dfTemp1[t+rowoffset,9] = value(sum(EP[:eSyn_Fuels_Diesel_Cons_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eSyn_Fuels_Jetfuel_Cons_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eSyn_Fuels_Gasoline_Cons_CO2_Emissions_By_Zone][z,t] for z in 1:Z))
        
<<<<<<< Updated upstream
            if setup["ModelBIO"] == 1
                dfTemp1[t+rowoffset,10] = value(sum(EP[:eBio_Fuels_Con_Diesel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eBio_Fuels_Con_Jetfuel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eBio_Fuels_Con_Gasoline_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eBio_Fuels_Con_Ethanol_CO2_Emissions_By_Zone][z,t] for z in 1:Z))
            else
                dfTemp1[t+rowoffset,10] = 0
            end

        else
            dfTemp1[t+rowoffset,7] = 0
            dfTemp1[t+rowoffset,8] = 0
            dfTemp1[t+rowoffset,9] = 0
            dfTemp1[t+rowoffset,10] = 0
        end

        if setup["ParameterScale"] == 1
            dfTemp1[t+rowoffset,1] = dfTemp1[t+rowoffset,1] * ModelScalingFactor
            dfTemp1[t+rowoffset,2] = dfTemp1[t+rowoffset,2] * ModelScalingFactor
            dfTemp1[t+rowoffset,3] = dfTemp1[t+rowoffset,3] * ModelScalingFactor
            dfTemp1[t+rowoffset,4] = dfTemp1[t+rowoffset,4] * ModelScalingFactor
            dfTemp1[t+rowoffset,5] = dfTemp1[t+rowoffset,5] * ModelScalingFactor
            dfTemp1[t+rowoffset,6] = dfTemp1[t+rowoffset,6] * ModelScalingFactor
            dfTemp1[t+rowoffset,7] = dfTemp1[t+rowoffset,7] * ModelScalingFactor
            dfTemp1[t+rowoffset,8] = dfTemp1[t+rowoffset,8] * ModelScalingFactor
            dfTemp1[t+rowoffset,9] = dfTemp1[t+rowoffset,6] * ModelScalingFactor
            dfTemp1[t+rowoffset,10] = dfTemp1[t+rowoffset,7] * ModelScalingFactor
        end
        
        dfTemp1[t+rowoffset,11] =  dfTemp1[t+rowoffset,1] + dfTemp1[t+rowoffset,2] + dfTemp1[t+rowoffset,3] + dfTemp1[t+rowoffset,4] + dfTemp1[t+rowoffset,5] + dfTemp1[t+rowoffset,6] + dfTemp1[t+rowoffset,7] + dfTemp1[t+rowoffset,8] + dfTemp1[t+rowoffset,9] + dfTemp1[t+rowoffset,10]
    end
    
=======
        if setup["ModelLFSC"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 0
            dfTemp1[t+rowoffset,29] =  dfTemp1[t+rowoffset,32] + dfTemp1[t+rowoffset,31] + dfTemp1[t+rowoffset,30] + dfTemp1[t+rowoffset,1] + dfTemp1[t+rowoffset,2] + dfTemp1[t+rowoffset,3] + dfTemp1[t+rowoffset,4] + dfTemp1[t+rowoffset,5] + dfTemp1[t+rowoffset,6] + dfTemp1[t+rowoffset,7] + dfTemp1[t+rowoffset,8] + dfTemp1[t+rowoffset,9] + dfTemp1[t+rowoffset,10] + dfTemp1[t+rowoffset,11] + dfTemp1[t+rowoffset,12] + dfTemp1[t+rowoffset,13] + dfTemp1[t+rowoffset,14] + dfTemp1[t+rowoffset,15] + dfTemp1[t+rowoffset,16] + dfTemp1[t+rowoffset,18] + dfTemp1[t+rowoffset,19] + dfTemp1[t+rowoffset,20] + dfTemp1[t+rowoffset,21] + dfTemp1[t+rowoffset,22] + dfTemp1[t+rowoffset,23] + dfTemp1[t+rowoffset,24] + dfTemp1[t+rowoffset,25] + dfTemp1[t+rowoffset,26] + dfTemp1[t+rowoffset,27] + dfTemp1[t+rowoffset,29]
        else
            dfTemp1[t+rowoffset,29] =  dfTemp1[t+rowoffset,32] + dfTemp1[t+rowoffset,31] + dfTemp1[t+rowoffset,30] + dfTemp1[t+rowoffset,1] + dfTemp1[t+rowoffset,2] + dfTemp1[t+rowoffset,3] + dfTemp1[t+rowoffset,4] + dfTemp1[t+rowoffset,5] + dfTemp1[t+rowoffset,6] + dfTemp1[t+rowoffset,7] + dfTemp1[t+rowoffset,8] + dfTemp1[t+rowoffset,9] + dfTemp1[t+rowoffset,10] + dfTemp1[t+rowoffset,11] + dfTemp1[t+rowoffset,12] + dfTemp1[t+rowoffset,13] + dfTemp1[t+rowoffset,14] + dfTemp1[t+rowoffset,15] + dfTemp1[t+rowoffset,16] + dfTemp1[t+rowoffset,17] + dfTemp1[t+rowoffset,18] + dfTemp1[t+rowoffset,19] + dfTemp1[t+rowoffset,20] + dfTemp1[t+rowoffset,21] + dfTemp1[t+rowoffset,22] + dfTemp1[t+rowoffset,23] + dfTemp1[t+rowoffset,24] + dfTemp1[t+rowoffset,25] + dfTemp1[t+rowoffset,26] + dfTemp1[t+rowoffset,27] + dfTemp1[t+rowoffset,29]
        end

    end

    ##Calculate annual values

    if setup["ModelNGSC"] == 1
        dfTemp1[rowoffset,1] = sum(sum(inputs["omega"].* (value.(EP[:ePower_NG_CO2_emission_per_zone_per_time])[z,:])) for z in 1:Z)
    else
        dfTemp1[rowoffset,1] = sum(sum(inputs["omega"].* (value.(EP[:eEmissionsByZone])[z,:])) for z in 1:Z)
    end

    dfTemp1[rowoffset,2] = 0

    if setup["ModelH2"] == 1
        if setup["ModelNGSC"] == 1
            dfTemp1[rowoffset,2] = sum(sum(inputs["omega"].* (value.(EP[:eHydrogen_NG_CO2_emission_per_zone_per_time])[z,:])) for z in 1:Z)
        else
            dfTemp1[rowoffset,2] = sum(sum(inputs["omega"].* (value.(EP[:eH2EmissionsByZone])[z,:])) for z in 1:Z)
        end
    end
    
    dfTemp1[rowoffset,3] = 0

    if setup["ModelCSC"] == 1 
        if setup["ModelCO2Pipelines"] == 1 && setup["CO2Pipeline_Loss"] == 1
            dfTemp1[rowoffset,3] = sum(sum(inputs["omega"].* (value.(EP[:eDAC_Emissions_per_zone_per_time])[z,:] + value.(EP[:eCO2Loss_Pipes_zt])[z,:] - value.(EP[:eDAC_CO2_Captured_per_zone_per_time])[z,:])) for z in 1:Z)
        else
            dfTemp1[rowoffset,3] = sum(sum(inputs["omega"].* (value.(EP[:eDAC_Emissions_per_zone_per_time])[z,:] - value.(EP[:eDAC_CO2_Captured_per_zone_per_time])[z,:])) for z in 1:Z)
        end
    end

    dfTemp1[rowoffset,4] = 0
    dfTemp1[rowoffset,5] = 0
    dfTemp1[rowoffset,6] = 0
    dfTemp1[rowoffset,7] = 0
    dfTemp1[rowoffset,8] = 0
    dfTemp1[rowoffset,9] = 0
    dfTemp1[rowoffset,10] = 0
    dfTemp1[rowoffset,11] = 0
    dfTemp1[rowoffset,12] = 0
    dfTemp1[rowoffset,25] = 0
    dfTemp1[rowoffset,26] = 0
    dfTemp1[rowoffset,27] = 0
    dfTemp1[rowoffset,28] = 0
    dfTemp1[rowoffset,29] = 0
    dfTemp1[rowoffset,30] = 0

    if setup["ModelBESC"] == 1
        if setup["Bio_ELEC_On"] == 1
            dfTemp1[rowoffset,4] = sum(sum(inputs["omega"].* (value.(EP[:eBio_ELEC_CO2_emissions_per_zone_per_time])[z,:])) for z in 1:Z)
            dfTemp1[rowoffset,5] = - sum(sum(inputs["omega"].* (value.(EP[:eBiomass_CO2_per_zone_per_time_ELEC])[z,:])) for z in 1:Z)
        end

        if setup["ModelH2"] == 1 && setup["Bio_H2_On"] == 1
            dfTemp1[rowoffset,6] = sum(sum(inputs["omega"].* (value.(EP[:eBio_H2_CO2_emissions_per_zone_per_time])[z,:])) for z in 1:Z)
            dfTemp1[rowoffset,7] = - sum(sum(inputs["omega"].* (value.(EP[:eBiomass_CO2_per_zone_per_time_H2])[z,:])) for z in 1:Z)
        end

        if setup["ModelLFSC"] == 1 && setup["Bio_LF_On"] == 1
            dfTemp1[rowoffset,8] = sum(sum(inputs["omega"].* (value.(EP[:eBio_LF_Plant_CO2_emissions_per_zone_per_time])[z,:])) for z in 1:Z)
            dfTemp1[rowoffset,9] = - sum(sum(inputs["omega"].* (value.(EP[:eBiomass_CO2_per_zone_per_time_LF])[z,:])) for z in 1:Z)
        end

        if setup["ModelNGSC"] == 1 && setup["Bio_NG_On"] == 1
            dfTemp1[rowoffset,10] = sum(sum(inputs["omega"].* (value.(EP[:eBio_NG_Plant_CO2_emissions_per_zone_per_time])[z,:])) for z in 1:Z)
            dfTemp1[rowoffset,11] = - sum(sum(inputs["omega"].* (value.(EP[:eBiomass_CO2_per_zone_per_time_NG])[z,:])) for z in 1:Z)
        end

        if setup["ModelEthanol"] == 1 && setup["Bio_Ethanol_On"] == 1
            if setup["ModelExclusiveEmissions"] == 1
                dfTemp1[rowoffset,25] = sum(sum(inputs["omega"].* (value.(EP[:eEthanol_CO2_Emissions_By_RES2])[z,:])) for z in 1:Z)
            elseif setup["ModelExclusiveEmissions"] == 0
                dfTemp1[rowoffset,25] = sum(sum(inputs["omega"].* (value.(EP[:eBio_Ethanol_Plant_CO2_emissions_per_zone_per_time])[z,:])) for z in 1:Z)
            end
            
            dfTemp1[rowoffset,26] = - sum(sum(inputs["omega"].* (value.(EP[:eBiomass_CO2_per_zone_per_time_Ethanol])[z,:])) for z in 1:Z)
        end


        if setup["Energy_Crops_Herb_Supply"] == 1
            dfTemp1[rowoffset,12] += sum(sum(inputs["omega"].* (value.(EP[:eHerb_biomass_emission_per_zone_per_time])[z,:])) for z in 1:Z)
        end

        if setup["Energy_Crops_Wood_Supply"] == 1
            dfTemp1[rowoffset,12] += sum(sum(inputs["omega"].* (value.(EP[:eWood_biomass_emission_per_zone_per_time])[z,:])) for z in 1:Z)
        end

        if setup["Agri_Res_Supply"] == 1
            dfTemp1[rowoffset,12] += sum(sum(inputs["omega"].* (value.(EP[:eAgri_Res_biomass_emission_per_zone_per_time])[z,:])) for z in 1:Z)
        end

        if setup["Agri_Process_Waste_Supply"] == 1
            dfTemp1[rowoffset,12] += sum(sum(inputs["omega"].* (value.(EP[:eAgri_Process_Waste_biomass_emission_per_zone_per_time])[z,:])) for z in 1:Z)
        end

        if setup["Agri_Forest_Supply"] == 1
            dfTemp1[rowoffset,12] += sum(sum(inputs["omega"].* (value.(EP[:eForest_biomass_emission_per_zone_per_time])[z,:])) for z in 1:Z)
        end
    end

    dfTemp1[rowoffset,13] = 0
    dfTemp1[rowoffset,14] = 0
    dfTemp1[rowoffset,15] = 0
    dfTemp1[rowoffset,16] = 0

    if setup["ModelNGSC"] == 1
        #Power sector and HSC NG raw emissions (before CCS) are displayed in "Power Emissions" and "H2 Emissions" columns
        dfTemp1[rowoffset,13] = sum(sum(inputs["omega"].* (value.(EP[:eConv_NG_CO2_Emissions])[z,:])) for z in 1:Z) - sum(sum(inputs["omega"].* (value.(EP[:ePower_NG_CO2_emission_per_zone_per_time])[z,:])) for z in 1:Z) - sum(sum(inputs["omega"].* (value.(EP[:eHydrogen_NG_CO2_emission_per_zone_per_time])[z,:])) for z in 1:Z)

        if setup["ModelSyntheticNG"] == 1
            dfTemp1[rowoffset,14] = sum(sum(inputs["omega"].* value.(EP[:eSyn_NG_Production_CO2_Emissions_By_Zone])[z,:]) for z in 1:Z)
            dfTemp1[rowoffset,15] = sum(sum(inputs["omega"].* value.(EP[:eSyn_NG_CO2_Emissions_By_Zone])[z,:]) for z in 1:Z)
        end

        if setup["ModelBESC"] == 1 && setup["Bio_NG_On"] == 1
          dfTemp1[rowoffset,16] = sum(sum(inputs["omega"].* (value.(EP[:eBio_NG_CO2_Emissions_By_Zone])[z,:])) for z in 1:Z)
        end

    end

    dfTemp1[rowoffset,17] = 0
    dfTemp1[rowoffset,18] = 0
    dfTemp1[rowoffset,19] = 0
    dfTemp1[rowoffset,20] = 0

    if setup["ModelLFSC"] == 1
        if setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 1 
            dfTemp1[rowoffset,17] = sum(sum(inputs["omega"].* (value.(EP[:eConv_Diesel_CO2_Emissions][z,:]) + value.(EP[:eConv_Jetfuel_CO2_Emissions][z,:]) + value.(EP[:eConv_Gasoline_CO2_Emissions][z,:]))) for z in 1:Z)

        elseif setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 0
            dfTemp1[rowoffset,17] = sum(value.(EP[:eConv_Diesel_CO2_Emissions][z]) for z in 1:Z) + sum(value.(EP[:eConv_Jetfuel_CO2_Emissions][z]) for z in 1:Z) + sum(value.(EP[:eConv_Gasoline_CO2_Emissions][z]) for z in 1:Z)

        elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 1
            dfTemp1[rowoffset,17] = sum(inputs["omega"].* value.(EP[:eConv_Diesel_CO2_Emissions][:])) + sum(inputs["omega"].* value.(EP[:eConv_Jetfuel_CO2_Emissions][:])) + sum(inputs["omega"].* value.(EP[:eConv_Gasoline_CO2_Emissions][:]))
       
        elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 0
            dfTemp1[rowoffset,17] = value.(EP[:eConv_Diesel_CO2_Emissions]) + value.(EP[:eConv_Jetfuel_CO2_Emissions]) + value.(EP[:eConv_Gasoline_CO2_Emissions])

        end
        
        if setup["ModelSyntheticFuels"] == 1 && setup["ModelChemicalProduction"] == 0 
            dfTemp1[rowoffset,18] = sum(sum(inputs["omega"].* (value.(EP[:eSynfuels_Production_CO2_Emissions_By_Zone])[z,:] + value.(EP[:eByProdConsCO2EmissionsByZone])[z,:])) for z in 1:Z)
            dfTemp1[rowoffset,19] = sum(sum(inputs["omega"].* (value.(EP[:eSyn_Diesel_CO2_Emissions_By_Zone])[z,:] + value.(EP[:eSyn_Jetfuel_CO2_Emissions_By_Zone])[z,:] + value.(EP[:eSyn_Gasoline_CO2_Emissions_By_Zone])[z,:])) for z in 1:Z)
        end

        if setup["ModelSyntheticFuels"] == 1 && setup["ModelChemicalProduction"] == 1 
            dfTemp1[rowoffset,18] = sum(sum(inputs["omega"].* (value.(EP[:eSynfuels_Production_CO2_Emissions_By_Zone])[z,:] + value.(EP[:eByProdConsCO2EmissionsByZone])[z,:])) for z in 1:Z)
            dfTemp1[rowoffset,19] = sum(sum(inputs["omega"].* (value.(EP[:eSyn_Diesel_CO2_Emissions_By_Zone])[z,:] + value.(EP[:eSyn_Jetfuel_CO2_Emissions_By_Zone])[z,:] + value.(EP[:eSyn_Gasoline_CO2_Emissions_By_Zone])[z,:] + value.(EP[:eCO2_Gasoline_CO2_Emissions_By_Zone])[z,:])) for z in 1:Z)
        end

        if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
            dfTemp1[rowoffset,20] = sum(sum(inputs["omega"].* (value.(EP[:eBio_Diesel_CO2_Emissions_By_Zone])[z,:] + value.(EP[:eBio_Jetfuel_CO2_Emissions_By_Zone])[z,:] + value.(EP[:eBio_Gasoline_CO2_Emissions_By_Zone])[z,:])) for z in 1:Z)
        end
    end

    dfTemp1[rowoffset,21] = 0
    dfTemp1[rowoffset,22] = 0
    dfTemp1[rowoffset,23] = 0
    dfTemp1[rowoffset,24] = 0
    dfTemp1[rowoffset,32] = 0

    if setup["ModelNGSC"] == 1
        dfTemp1[rowoffset,21] = -sum(sum(inputs["omega"].* (value.(EP[:ePower_NG_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)

        if setup["ModelH2"] == 1
            dfTemp1[rowoffset,22] = -sum(sum(inputs["omega"].* (value.(EP[:eHydrogen_NG_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
        end

        if setup["ModelCSC"] == 1
            dfTemp1[rowoffset,23] = -sum(sum(inputs["omega"].* (value.(EP[:eDAC_NG_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
        end
    end

    if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthylenePlants"] == 1 && setup["ModelEthyleneEndOfLife"] == 1 && setup["ModelEthyleneRetrofitting"] == 0
        dfTemp1[rowoffset,24] = sum(sum(inputs["omega"].* value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone_GF])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone_EP])[z,:]) for z in 1:Z)
        dfTemp1[rowoffset,29] = sum(sum(inputs["omega"].* value.(EP[:eEthylene_CO2_Combustion_Emissions_By_Zone_GF])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_CO2_Combustion_Emissions_By_Zone_EP])[z,:]) for z in 1:Z)
        dfTemp1[rowoffset,30] = sum(sum(inputs["omega"].* value.(EP[:eEthylene_CoProd_Combustion_Emissions_By_Zone_GF])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_CoProd_Combustion_Emissions_By_Zone_EP])[z,:]) for z in 1:Z)

    end
   
    if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthylenePlants"] == 1 && setup["ModelPropyleneEndOfLife"] == 1 && setup["ModelEthyleneRetrofitting"] == 1
        dfTemp1[rowoffset,32] = sum(sum(inputs["omega"].* value.(EP[:ePropylene_CO2_Combustion_Emissions_By_Zone_GF])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:ePropylene_CO2_Combustion_Emissions_By_Zone_EP])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eConv_Propylene_CO2_Emissions_EoL])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:ePropylene_CO2_Combustion_Emissions_By_Zone_Retrofit])[z,:]) for z in 1:Z)
  
    end


    if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthylenePlants"] == 1 && setup["ModelEthyleneEndOfLife"] == 1 && setup["ModelEthyleneRetrofitting"] == 1
        dfTemp1[rowoffset,24] = sum(sum(inputs["omega"].* value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone_GF])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone_EP])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone_Retrofit])[z,:]) for z in 1:Z)
        dfTemp1[rowoffset,29] = sum(sum(inputs["omega"].* value.(EP[:eEthylene_CO2_Combustion_Emissions_By_Zone_GF])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_CO2_Combustion_Emissions_By_Zone_EP])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_CO2_Combustion_Emissions_By_Zone_Retrofit])[z,:]) for z in 1:Z)
        dfTemp1[rowoffset,30] = sum(sum(inputs["omega"].* value.(EP[:eEthylene_CoProd_Combustion_Emissions_By_Zone_GF])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_CoProd_Combustion_Emissions_By_Zone_EP])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_CoProd_Combustion_Emissions_By_Zone_Retrofit])[z,:]) for z in 1:Z)

    end

    if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthylenePlants"] == 1 && setup["ModelEthyleneEndOfLife"] == 0 && setup["ModelEthyleneRetrofitting"] == 0
        dfTemp1[rowoffset,24] = sum(sum(inputs["omega"].* value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone_GF])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone_EP])[z,:]) for z in 1:Z)
        dfTemp1[rowoffset,29] = 0
        dfTemp1[rowoffset,30] = 0
    end

    if setup["ModelEthyleneProduction"] == 1 && setup["ModelEthylenePlants"] == 1 && setup["ModelEthyleneEndOfLife"] == 0 && setup["ModelEthyleneRetrofitting"] == 1
        dfTemp1[rowoffset,24] = sum(sum(inputs["omega"].* value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone_GF])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone_EP])[z,:]) for z in 1:Z) + sum(sum(inputs["omega"].* value.(EP[:eEthylene_Production_CO2_Emissions_By_Zone_Retrofit])[z,:]) for z in 1:Z)
        dfTemp1[rowoffset,29] = 0
        dfTemp1[rowoffset,30] = 0
    end

    if setup["ModelEthanePurchase"] == 1
        dfTemp1[rowoffset,27] = sum(sum(inputs["omega"].* value.(EP[:eConv_ethane_CO2_Emissions])[z,:]) for z in 1:Z) 
        # Consumption Emissions: dfTemp1[rowoffset,17] = sum(sum(inputs["omega"].* value.(EP[:eEthylene_CO2_Emissions_By_Zone])[z,:]) for z in 1:Z)
    end
    dfTemp1[rowoffset,31] = 0
    if setup["ModelPropylenePurchase"] == 1
        dfTemp1[rowoffset,31] = sum(sum(inputs["omega"].* value.(EP[:eConv_Propylene_CO2_Emissions])[z,:]) for z in 1:Z) 
        # Consumption Emissions: dfTemp1[rowoffset,17] = sum(sum(inputs["omega"].* value.(EP[:eEthylene_CO2_Emissions_By_Zone])[z,:]) for z in 1:Z)
    end

    
    dfTemp1[rowoffset,28] =  dfTemp1[rowoffset,32] + dfTemp1[rowoffset,31] + dfTemp1[rowoffset,30] + dfTemp1[rowoffset,1] + dfTemp1[rowoffset,2] + dfTemp1[rowoffset,3] + dfTemp1[rowoffset,4] + dfTemp1[rowoffset,5] + dfTemp1[rowoffset,6] + dfTemp1[rowoffset,7] + dfTemp1[rowoffset,8] + dfTemp1[rowoffset,9] + dfTemp1[rowoffset,10] + dfTemp1[rowoffset,11] + dfTemp1[rowoffset,12] + dfTemp1[rowoffset,13] + dfTemp1[rowoffset,14] + dfTemp1[rowoffset,15] + dfTemp1[rowoffset,16] + dfTemp1[rowoffset,17] + dfTemp1[rowoffset,18] + dfTemp1[rowoffset,19] + dfTemp1[rowoffset,20] + dfTemp1[rowoffset,21] + dfTemp1[rowoffset,22] + dfTemp1[rowoffset,23] + dfTemp1[rowoffset,24]+ dfTemp1[rowoffset,25] + dfTemp1[rowoffset,26] + dfTemp1[rowoffset,27] + dfTemp1[rowoffset,29]
    

>>>>>>> Stashed changes
    dfCO2Balance =  hcat(vcat(["", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)

	for c in 2:size(dfCO2Balance,2)
	   	dfCO2Balance[rowoffset,c]=sum(inputs["omega"].*dfCO2Balance[(rowoffset+1):size(dfCO2Balance,1),c])
	end

	dfCO2Balance = DataFrame(dfCO2Balance, :auto)
	CSV.write(joinpath(path,"System_CO2_emission_balance.csv"), dfCO2Balance, writeheader=false)
end
