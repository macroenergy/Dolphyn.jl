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

    dfSynFuels = inputs["dfSynFuels"]
    Liquid_Fuels_D = inputs["Liquid_Fuels_D"]
    SYN_FUELS_RES_ALL = inputs["SYN_FUELS_RES_ALL"]
    dfSynFuelsByProdExcess = inputs["dfSynFuelsByProdExcess"]

	#Define sets
    Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)
    
    NSFByProd = inputs["NSFByProd"] #Number of by products
    Conventional_fuel_price_per_mmbtu = inputs["Conventional_fuel_price_per_mmbtu"] 

    ## Variables ##
    #Conventional liquid Fuel Demand
	@variable(EP, vConvLFDemand[t = 1:T, z = 1:Z] >= 0 )
    
	### Expressions ###
    #Objective Function Expressions
    #Cost of Conventional Fuel
    if setup["ParameterScale"] ==1
		@expression(EP, eCLFVar_out[z = 1:Z,t = 1:T], 
		(inputs["omega"][t] * Conventional_fuel_price_per_mmbtu * Liquid_Fuels_D[t,z])) / ModelScalingFactor
    else
		@expression(EP, eCLFVar_out[z = 1:Z,t = 1:T], 
		(inputs["omega"][t] * Conventional_fuel_price_per_mmbtu * Liquid_Fuels_D[t,z]))
	end

    #Sum up conventional Fuel Costs
    @expression(EP, eTotalCLFVarOutT[t=1:T], sum(eCLFVar_out[z,t] for z in 1:Z))
	@expression(EP, eTotalCLFVarOut, sum(eTotalCLFVarOutT[t] for t in 1:T))

    #Liquid Fuel Balance
    EP[:eLFBalance] += vConvLFDemand
    EP[:eObj] += eTotalCLFVarOut

    ### Constraints ###
    @constraints(EP, begin [ t=1:T, k in 1:SYN_FUELS_RES_ALL, b in 1:NSFByProd], EP[:vSFByProd][k,b,t] == EP[:vSFCO2in][k,t] * dfSynFuelsByProdExcess[:,b][k]
	end)

	return EP

end
