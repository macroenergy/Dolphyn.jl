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

    T = inputs["T"]::Int     # Number of time steps (hours)
	Z = inputs["Z"]::Int     # Number of zones

	## CO2 balance for each type of resources
	dfCO2Balance = Array{Any}
	rowoffset=2

    dfTemp1 = Array{Any}(nothing, T+rowoffset, 11)
    dfTemp1[1,1:size(dfTemp1,2)] = ["Power Emissions", "HSC Emissions", "CSC Emissions",  "Biorefinery Emissions", "Biomass Emissions", "Biomass Capture", "Synfuel Production Emissions", "Conventional Fuels", "Synfuels", "Biofuels", "Total"]
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

        if setup["ModelBIO"] == 1
            dfTemp1[t+rowoffset,4] = value(sum(EP[:eBiorefinery_CO2_emissions_per_zone_per_time][z,t] for z in 1:Z))
            dfTemp1[t+rowoffset,5] = value(sum(EP[:eHerb_biomass_emission_per_zone_per_time][z,t] for z in 1:Z)) + value(sum(EP[:eWood_biomass_emission_per_zone_per_time][z,t] for z in 1:Z))
            dfTemp1[t+rowoffset,6] = - value(sum(EP[:eBiomass_CO2_captured_per_zone_per_time][z,t] for z in 1:Z))
        else
            dfTemp1[t+rowoffset,4] = 0
            dfTemp1[t+rowoffset,5] = 0
            dfTemp1[t+rowoffset,6] = 0
        end

        if setup["ModelLiquidFuels"] == 1
            dfTemp1[t+rowoffset,7] = value(sum(EP[:eSyn_Fuels_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eByProdConsCO2EmissionsByZone][z,t] for z in 1:Z))
            dfTemp1[t+rowoffset,8] = value(sum(EP[:eLiquid_Fuels_Con_Diesel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eLiquid_Fuels_Con_Jetfuel_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eLiquid_Fuels_Con_Gasoline_CO2_Emissions_By_Zone][z,t] for z in 1:Z))
            dfTemp1[t+rowoffset,9] = value(sum(EP[:eSyn_Fuels_Diesel_Cons_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eSyn_Fuels_Jetfuel_Cons_CO2_Emissions_By_Zone][z,t] for z in 1:Z)) + value(sum(EP[:eSyn_Fuels_Gasoline_Cons_CO2_Emissions_By_Zone][z,t] for z in 1:Z))
        
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
    
    dfCO2Balance =  hcat(vcat(["", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)

	for c in 2:size(dfCO2Balance,2)
	   	dfCO2Balance[rowoffset,c]=sum(inputs["omega"].*dfCO2Balance[(rowoffset+1):size(dfCO2Balance,1),c])
	end

	dfCO2Balance = DataFrame(dfCO2Balance, :auto)
	CSV.write(joinpath(path,"System_CO2_emission_balance.csv"), dfCO2Balance, writeheader=false)
end
