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

    liquid_fuel_demand(EP::Model, inputs::Dict, setup::Dict)

This module defines the conventional gasoline, jetfuel, and diesel production decision variables $x_{z,t}^{\textrm{Gasoline,Conv}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$, $x_{z,t}^{\textrm{Jetfuel,Conv}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$, $x_{z,t}^{\textrm{Diesel,Conv}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$ representing  conventional gasoline, jetfuel, and diesel purchased in zone $z$ at time period $t$.

The variables defined in this file named after ```vConvLFGasolineDemand``` cover variable $x_{z,t}^{Gasoline,Conv}$, ```vConvLFJetfuelDemand``` cover variable $x_{z,t}^{Jetfuel,Conv}$, and ```vConvLFDieselDemand``` cover variable $x_{z,t}^{Diesel,Conv}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of  conventional fuel purchase over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{Gasoline,Conv,o}} = \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{z}^{\textrm{Gasoline,Conv,VOM}} \times x_{z,t}^{\textrm{Gasoline,Conv}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{Jetfuel,Conv,o}} = \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{z}^{\textrm{Jetfuel,Conv,VOM}} \times x_{z,t}^{\textrm{Jetfuel,Conv}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{Diesel,Conv,o}} = \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{z}^{\textrm{Diesel,Conv,VOM}} \times x_{z,t}^{\textrm{Diesel,Conv}}
\end{equation*}
```

This module also constraints the amount of each type of non conventional fuels deployment based on user specifications (if any).
"""
function liquid_fuel_demand(EP::Model, inputs::Dict, setup::Dict)

	#Define sets
    Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)
    
    if setup["AllowConventionalDiesel"] == 1

        if setup["ParameterScale"] ==1
            Conventional_diesel_price_per_mmbtu = inputs["Conventional_diesel_price_per_mmbtu"] / ModelScalingFactor^2 #Change price from $ to $M
        else
            Conventional_diesel_price_per_mmbtu = inputs["Conventional_diesel_price_per_mmbtu"] 
        end

        #Conventional liquid Fuel Demand
        @variable(EP, vConvLFDieselDemand[t = 1:T, z = 1:Z] >= 0 )
        
        ### Expressions ###
        #Objective Function Expressions

        #Cost of Conventional Fuel
        @expression(EP, eCLFDieselVar_out[z = 1:Z,t = 1:T], (inputs["omega"][t] * Conventional_diesel_price_per_mmbtu * vConvLFDieselDemand[t,z]))

        #Sum up conventional Fuel Costs
        @expression(EP, eTotalCLFDieselVarOutT[t=1:T], sum(eCLFDieselVar_out[z,t] for z in 1:Z))
        @expression(EP, eTotalCLFDieselVarOut, sum(eTotalCLFDieselVarOutT[t] for t in 1:T))

        #Liquid Fuel Balance
        EP[:eLFDieselBalance] += vConvLFDieselDemand
        EP[:eObj] += eTotalCLFDieselVarOut

        ####Constraining amount of syn fuel
        
        if setup["SpecifySynDieselPercentFlag"] == 1

            percent_sf_diesel = setup["percent_sf_diesel"]

            #Sum up conventional fuel production
            @expression(EP, eConvLFDieselDemandT[t=1:T], sum(vConvLFDieselDemand[t, z] for z in 1:Z))
            @expression(EP, eConvLFDieselDemandTZ, sum(eConvLFDieselDemandT[t] for t in 1:T))

            #Sum up synfuel fuel production (Synfuel main product is diesel)
            @expression(EP, eSynFuelProd_DieselT[t=1:T], sum(EP[:eSynFuelProd_Diesel][t, z] for z in 1:Z))
            @expression(EP, eSynFuelProd_DieselTZ, sum(eSynFuelProd_DieselT[t] for t in 1:T))
            @constraint(EP, cSynFuelDieselShare, (percent_sf_diesel - 1) * eSynFuelProd_DieselTZ + percent_sf_diesel *  eConvLFDieselDemandTZ == 0)
        end

    end

    #############################################################################################################################################
    
    if setup["AllowConventionalJetfuel"] == 1

        if setup["ParameterScale"] ==1
            Conventional_jetfuel_price_per_mmbtu = inputs["Conventional_jetfuel_price_per_mmbtu"] / ModelScalingFactor^2 #Change price from $ to $M
        else
            Conventional_jetfuel_price_per_mmbtu = inputs["Conventional_jetfuel_price_per_mmbtu"] 
        end
    
        #Conventional liquid Fuel Demand
        @variable(EP, vConvLFJetfuelDemand[t = 1:T, z = 1:Z] >= 0 )
        
        ### Expressions ###
        #Objective Function Expressions
    
        #Cost of Conventional Fuel
        @expression(EP, eCLFJetfuelVar_out[z = 1:Z,t = 1:T], (inputs["omega"][t] * Conventional_jetfuel_price_per_mmbtu * vConvLFJetfuelDemand[t,z]))
    
        #Sum up conventional Fuel Costs
        @expression(EP, eTotalCLFJetfuelVarOutT[t=1:T], sum(eCLFJetfuelVar_out[z,t] for z in 1:Z))
        @expression(EP, eTotalCLFJetfuelVarOut, sum(eTotalCLFJetfuelVarOutT[t] for t in 1:T))
    
        #Liquid Fuel Balance
        EP[:eLFJetfuelBalance] += vConvLFJetfuelDemand
        EP[:eObj] += eTotalCLFJetfuelVarOut
    
        ####Constraining amount of syn fuel
        
        if setup["SpecifySynJetfuelPercentFlag"] == 1

            percent_sf_jetfuel = setup["percent_sf_jetfuel"]

            #Sum up conventional fuel production
            @expression(EP, eConvLFJetfuelDemandT[t=1:T], sum(vConvLFJetfuelDemand[t, z] for z in 1:Z))
            @expression(EP, eConvLFJetfuelDemandTZ, sum(eConvLFJetfuelDemandT[t] for t in 1:T))

            #Sum up synfuel fuel production (Synfuel main product is jetfuel)
            @expression(EP, eSynFuelProd_JetfuelT[t=1:T], sum(EP[:eSynFuelProd_Jetfuel][t, z] for z in 1:Z))
            @expression(EP, eSynFuelProd_JetfuelTZ, sum(eSynFuelProd_JetfuelT[t] for t in 1:T))
            @constraint(EP, cSynFuelJetfuelShare, (percent_sf_jetfuel - 1) * eSynFuelProd_JetfuelTZ + percent_sf_jetfuel *  eConvLFJetfuelDemandTZ == 0)
        end
    end

    #############################################################################################################################################
 
    if setup["AllowConventionalGasoline"] == 1

        if setup["ParameterScale"] ==1
            Conventional_gasoline_price_per_mmbtu = inputs["Conventional_gasoline_price_per_mmbtu"] / ModelScalingFactor^2 #Change price from $ to $M
        else
            Conventional_gasoline_price_per_mmbtu = inputs["Conventional_gasoline_price_per_mmbtu"] 
        end
    
        #Conventional liquid Fuel Demand
        @variable(EP, vConvLFGasolineDemand[t = 1:T, z = 1:Z] >= 0 )
        
        ### Expressions ###
        #Objective Function Expressions
    
        #Cost of Conventional Fuel
        @expression(EP, eCLFGasolineVar_out[z = 1:Z,t = 1:T], (inputs["omega"][t] * Conventional_gasoline_price_per_mmbtu * vConvLFGasolineDemand[t,z]))
    
        #Sum up conventional Fuel Costs
        @expression(EP, eTotalCLFGasolineVarOutT[t=1:T], sum(eCLFGasolineVar_out[z,t] for z in 1:Z))
        @expression(EP, eTotalCLFGasolineVarOut, sum(eTotalCLFGasolineVarOutT[t] for t in 1:T))
    
        #Liquid Fuel Balance
        EP[:eLFGasolineBalance] += vConvLFGasolineDemand
        EP[:eObj] += eTotalCLFGasolineVarOut
    
        ####Constraining amount of syn fuel
        
        if setup["SpecifySynGasolinePercentFlag"] == 1

            percent_sf_gasoline = setup["percent_sf_gasoline"]

            #Sum up conventional fuel production
            @expression(EP, eConvLFGasolineDemandT[t=1:T], sum(vConvLFGasolineDemand[t, z] for z in 1:Z))
            @expression(EP, eConvLFGasolineDemandTZ, sum(eConvLFGasolineDemandT[t] for t in 1:T))

            #Sum up synfuel fuel production (Synfuel main product is gasoline)
            @expression(EP, eSynFuelProd_GasolineT[t=1:T], sum(EP[:eSynFuelProd_Gasoline][t, z] for z in 1:Z))
            @expression(EP, eSynFuelProd_GasolineTZ, sum(eSynFuelProd_GasolineT[t] for t in 1:T))
            @constraint(EP, cSynFuelGasolineShare, (percent_sf_gasoline - 1) * eSynFuelProd_GasolineTZ + percent_sf_gasoline *  eConvLFGasolineDemandTZ == 0)
        end
    end
	return EP

end
