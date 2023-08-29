"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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

"""

function liquid_fuel_demand(EP::Model, inputs::Dict, setup::Dict)

	#Define sets
    Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)

    #Conventional liquid Fuel Demand
    @variable(EP, vConvLFDieselDemand[t = 1:T, z = 1:Z] >= 0 )
    @variable(EP, vConvLFJetfuelDemand[t = 1:T, z = 1:Z] >= 0 )
    @variable(EP, vConvLFGasolineDemand[t = 1:T, z = 1:Z] >= 0 )

    if setup["AllowConventionalDiesel"] == 1

        if setup["ParameterScale"] ==1
            Conventional_diesel_price_per_mmbtu = inputs["Conventional_diesel_price_per_mmbtu"] / ModelScalingFactor^2 #Change price from $ to $M
        else
            Conventional_diesel_price_per_mmbtu = inputs["Conventional_diesel_price_per_mmbtu"] 
        end

        ### Expressions ###
        #Objective Function Expressions

        #Cost of Conventional Fuel
        @expression(EP, eCLFDieselVar_out[z = 1:Z,t = 1:T], (inputs["omega"][t] * Conventional_diesel_price_per_mmbtu * vConvLFDieselDemand[t,z]))

        ####Constraining amount of syn fuel
        if setup["BIO_Diesel_On"] == 0
            if setup["SpecifySynBioDieselPercentFlag"] == 1

                percent_sbf_diesel = setup["percent_sbf_diesel"]

                #Sum up conventional fuel production
                @expression(EP, eConvLFDieselDemandT[t=1:T], sum(vConvLFDieselDemand[t, z] for z in 1:Z))
                @expression(EP, eConvLFDieselDemandTZ, sum(eConvLFDieselDemandT[t] for t in 1:T))

                #Sum up synfuel fuel production (Synfuel main product is diesel)
                @expression(EP, eSynFuelProd_DieselT[t=1:T], sum(EP[:eSynFuelProd_Diesel][t, z] for z in 1:Z))
                @expression(EP, eSynFuelProd_DieselTZ, sum(eSynFuelProd_DieselT[t] for t in 1:T))
                @constraint(EP, cSynFuelDieselShare, (percent_sbf_diesel - 1) * eSynFuelProd_DieselTZ + percent_sbf_diesel *  eConvLFDieselDemandTZ == 0)
            end
        end 
    else
        @constraint(EP, cNoConvDiesel[t = 1:T, z = 1:Z], vConvLFDieselDemand[t,z] == 0)
        @expression(EP, eCLFDieselVar_out[z = 1:Z,t = 1:T],0)
    end

    #Sum up conventional Fuel Costs
    @expression(EP, eTotalCLFDieselVarOutT[t=1:T], sum(eCLFDieselVar_out[z,t] for z in 1:Z))
    @expression(EP, eTotalCLFDieselVarOut, sum(eTotalCLFDieselVarOutT[t] for t in 1:T))

    #Liquid Fuel Balance
    EP[:eLFDieselBalance] += vConvLFDieselDemand
    EP[:eObj] += eTotalCLFDieselVarOut

    #############################################################################################################################################
    
    if setup["AllowConventionalJetfuel"] == 1

        if setup["ParameterScale"] ==1
            Conventional_jetfuel_price_per_mmbtu = inputs["Conventional_jetfuel_price_per_mmbtu"] / ModelScalingFactor^2 #Change price from $ to $M
        else
            Conventional_jetfuel_price_per_mmbtu = inputs["Conventional_jetfuel_price_per_mmbtu"] 
        end

        ### Expressions ###
        #Objective Function Expressions
    
        #Cost of Conventional Fuel
        @expression(EP, eCLFJetfuelVar_out[z = 1:Z,t = 1:T], (inputs["omega"][t] * Conventional_jetfuel_price_per_mmbtu * vConvLFJetfuelDemand[t,z]))
    
        ####Constraining amount of syn fuel
        if setup["BIO_Jetfuel_On"] == 0
            if setup["SpecifySynBioJetfuelPercentFlag"] == 1
    
                percent_sbf_jetfuel = setup["percent_sbf_jetfuel"]
    
                #Sum up conventional fuel production
                @expression(EP, eConvLFJetfuelDemandT[t=1:T], sum(vConvLFJetfuelDemand[t, z] for z in 1:Z))
                @expression(EP, eConvLFJetfuelDemandTZ, sum(eConvLFJetfuelDemandT[t] for t in 1:T))
    
                #Sum up synfuel fuel production (Synfuel main product is jetfuel)
                @expression(EP, eSynFuelProd_JetfuelT[t=1:T], sum(EP[:eSynFuelProd_Jetfuel][t, z] for z in 1:Z))
                @expression(EP, eSynFuelProd_JetfuelTZ, sum(eSynFuelProd_JetfuelT[t] for t in 1:T))
                @constraint(EP, cSynFuelJetfuelShare, (percent_sbf_jetfuel - 1) * eSynFuelProd_JetfuelTZ + percent_sbf_jetfuel *  eConvLFJetfuelDemandTZ == 0)
            end
        end 
    else
        @constraint(EP, cNoConvJetfuel[t = 1:T, z = 1:Z], vConvLFJetfuelDemand[t,z] == 0)
        @expression(EP, eCLFJetfuelVar_out[z = 1:Z,t = 1:T], 0)
    end

    #Sum up conventional Fuel Costs
    @expression(EP, eTotalCLFJetfuelVarOutT[t=1:T], sum(eCLFJetfuelVar_out[z,t] for z in 1:Z))
    @expression(EP, eTotalCLFJetfuelVarOut, sum(eTotalCLFJetfuelVarOutT[t] for t in 1:T))

    #Liquid Fuel Balance
    EP[:eLFJetfuelBalance] += vConvLFJetfuelDemand
    EP[:eObj] += eTotalCLFJetfuelVarOut

    #############################################################################################################################################
 
    if setup["AllowConventionalGasoline"] == 1

        if setup["ParameterScale"] ==1
            Conventional_gasoline_price_per_mmbtu = inputs["Conventional_gasoline_price_per_mmbtu"] / ModelScalingFactor^2 #Change price from $ to $M
        else
            Conventional_gasoline_price_per_mmbtu = inputs["Conventional_gasoline_price_per_mmbtu"] 
        end

        
        ### Expressions ###
        #Objective Function Expressions
    
        #Cost of Conventional Fuel
        @expression(EP, eCLFGasolineVar_out[z = 1:Z,t = 1:T], (inputs["omega"][t] * Conventional_gasoline_price_per_mmbtu * vConvLFGasolineDemand[t,z]))
    
        ####Constraining amount of syn fuel
        if setup["BIO_Gasoline_On"] == 0
            if setup["SpecifySynBioGasolinePercentFlag"] == 1
    
                percent_sbf_gasoline = setup["percent_sbf_gasoline"]
    
                #Sum up conventional fuel production
                @expression(EP, eConvLFGasolineDemandT[t=1:T], sum(vConvLFGasolineDemand[t, z] for z in 1:Z))
                @expression(EP, eConvLFGasolineDemandTZ, sum(eConvLFGasolineDemandT[t] for t in 1:T))
    
                #Sum up synfuel fuel production (Synfuel main product is gasoline)
                @expression(EP, eSynFuelProd_GasolineT[t=1:T], sum(EP[:eSynFuelProd_Gasoline][t, z] for z in 1:Z))
                @expression(EP, eSynFuelProd_GasolineTZ, sum(eSynFuelProd_GasolineT[t] for t in 1:T))
                @constraint(EP, cSynFuelGasolineShare, (percent_sbf_gasoline - 1) * eSynFuelProd_GasolineTZ + percent_sbf_gasoline *  eConvLFGasolineDemandTZ == 0)
            end
        end 
    else
        @constraint(EP, cNoConvGasoline[t = 1:T, z = 1:Z], vConvLFGasolineDemand[t,z] == 0)
        @expression(EP, eCLFGasolineVar_out[z = 1:Z,t = 1:T], 0)
    end

    #Sum up conventional Fuel Costs
    @expression(EP, eTotalCLFGasolineVarOutT[t=1:T], sum(eCLFGasolineVar_out[z,t] for z in 1:Z))
    @expression(EP, eTotalCLFGasolineVarOut, sum(eTotalCLFGasolineVarOutT[t] for t in 1:T))

    #Liquid Fuel Balance
    EP[:eLFGasolineBalance] += vConvLFGasolineDemand
    EP[:eObj] += eTotalCLFGasolineVarOut

   

	return EP

end
