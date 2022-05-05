"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
	emissions(EP::Model, inputs::Dict, UCommit::Int)

This function creates expression to add the net CO2 captured by plants in each zone, which is subsequently deducted to the total emissions
"""
function emissions_csc(EP::Model, inputs::Dict, setup::Dict)

	println("CO2 Emissions Module for CO2 Policy modularization")

	dfCO2Capture = inputs["dfCO2Capture"]

	H = inputs["CO2_RES_ALL"]     # Number of resources (generators, storage, flexible demand)
    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
    # If setup["ParameterScale] = 1, emissions expression and constraints are written in ktonnes
    # If setup["ParameterScale] = 0, emissions expression and constraints are written in tonnes
    # Adjustment of Fuel_CO2 units carried out in load_fuels_data.jl

    #DAC Negative CO2 emission = CO2 emitted by fuel usage - Total amount of CO2 captured
	@expression(EP, eCO2NegativeEmissionsByPlant[k=1:H,t=1:T], 
        EP[:vCO2Capture][k,t] * (1 - inputs["fuel_CO2"][dfCO2Capture[!,:Fuel][k]]* dfCO2Capture[!,:etaFuel_MMBtu_p_tonne][k])
    ) 
      
 	@expression(EP, eCO2NegativeEmissionsByZone[z=1:Z, t=1:T], sum(eCO2NegativeEmissionsByPlant[y,t] for y in dfCO2Capture[(dfCO2Capture[!,:Zone].==z),:R_ID]))

    # If CO2 price is implemented in CSC balance or Power Balance and SystemCO2 constraint is active (independent or joint), then need to minus cost penalty due to CO2 prices
    # Also need to deduct away CO2 price offset due to net carbon capture (Negative emissions)
    if (setup["CO2CostOffset"] ==1 && setup["SystemCO2Constraint"] == 1)
        # Use CO2 price for CSC supply chain
        # Emissions offset by zone - needed to report zonal cost breakdown
        @expression(EP,eCCO2EmissionsOffsetbyZone[z=1:Z],
        sum(inputs["omega"][t]*eCO2NegativeEmissionsByZone[z,t]*inputs["dfCO2CO2PriceZone"][z] for t= 1:T)
        )

        # Sum over each  zone
        @expression(EP,eCCO2CaptureTotalEmissionsOffset,
        sum(eCCO2EmissionsOffsetbyZone[z] for z=1:Z))

        # Deduct total emissions offset associated with CO2 capture technologies
    	EP[:eObj] -= eCCO2CaptureTotalEmissionsOffset


    elseif (setup["CO2Cap"] == 4 && setup["SystemCO2Constraint"] == 2) 
        # Use CO2 price for power system as the global CO2 price
        # Emissions offset by zone - needed to report zonal cost breakdown
        @expression(EP,eCCO2EmissionsOffsetbyZone[z=1:Z],
        sum(inputs["omega"][t]*sum(eCO2NegativeEmissionsByZone[z,t]*inputs["dfCO2Price"][z,cap] for cap=findall(x->x==1, inputs["dfCO2CapZones"][z,:])) for t= 1:T)
        )

        # Sum over each  zone
        @expression(EP,eCCO2CaptureTotalEmissionsOffset,
        sum(eCCO2EmissionsOffsetbyZone[z] for z=1:Z))

        # Deduct total emissions offset associated with CO2 capture technologies
    	EP[:eObj] -= eCCO2CaptureTotalEmissionsOffset

    end

    return EP
end
