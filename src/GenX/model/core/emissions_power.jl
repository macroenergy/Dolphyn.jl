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
	emissions(EP::Model, inputs::Dict, UCommit::Int)

This function creates expression to add the CO2 emissions by plants in each zone, which is subsequently added to the total emissions
"""
function emissions_power(EP::Model, inputs::Dict, setup::Dict)

    println("Emissions Module for CO2 Policy modularization")

    dfGen = inputs["dfGen"]

    G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones
    COMMIT = inputs["COMMIT"] # For not, thermal resources are the only ones eligible for Unit Committment
    Power_CCS = inputs["Power_CCS"]

    @expression(
        EP,
        eEmissionsByPlant[y = 1:G, t = 1:T],
        if y in inputs["COMMIT"]
            dfGen[!, :CO2_per_MWh][y] * EP[:vP][y, t] +
            dfGen[!, :CO2_per_Start][y] * EP[:vSTART][y, t]
        else
            dfGen[!, :CO2_per_MWh][y] * EP[:vP][y, t]
        end
    )

    @expression(
        EP,
        eCO2CapturePowerByPlant[y in Power_CCS, t = 1:T],
        dfGen[!, :CCS_Percentage][y] / (1 - dfGen[!, :CCS_Percentage][y]) *
        eEmissionsByPlant[y, t]
    )

    @expression(
        EP,
        eEmissionsByZone[z = 1:Z, t = 1:T],
        sum(eEmissionsByPlant[y, t] for y in dfGen[(dfGen[!, :Zone].==z), :R_ID])
    )

	# This expression is used to denote the amount of CO2 captured by the power plant with CCS
	@expression(
		EP,
		eCO2CapturePowerByZone[z = 1:Z, t = 1:T],
		sum(eCO2CapturePowerByPlant[y, t] for y in dfGen[(dfGen[!, :Zone].==z), :R_ID])
	)

    # If CO2 price is implemented in HSC balance or Power Balance and SystemCO2 constraint is active (independent or joint),
    # then need to add cost penalty due to CO2 prices
    if (setup["CO2Cap"] == 4)
        # Use CO2 price for power system as the global CO2 price
        # Emissions penalty by zone - needed to report zonal cost breakdown
        @expression(
            EP,
            eCEmissionsPenaltybyZone[z = 1:Z],
            sum(
                inputs["omega"][t] * sum(
                    eEmissionsByZone[z, t] * inputs["dfCO2Price"][z, cap] for
                    cap in findall(x -> x == 1, inputs["dfCO2CapZones"][z, :])
                ) for t = 1:T
            )
        )
        # Sum over each policy type, each zone and each time step
        @expression(
            EP,
            eCEmissionsPenaltybyPolicy[cap = 1:inputs["NCO2Cap"]],
            sum(
                inputs["omega"][t] * sum(
                    eEmissionsByZone[z, t] * inputs["dfCO2Price"][z, cap] for
                    z in findall(x -> x == 1, inputs["dfCO2CapZones"][:, cap])
                ) for t = 1:T
            )
        )
        @expression(
            EP,
            eCGenTotalEmissionsPenalty,
            sum(eCEmissionsPenaltybyPolicy[cap] for cap = 1:inputs["NCO2Cap"])
        )

        # Add total emissions penalty associated with direct emissions from power generation technologies
        EP[:eObj] += eCGenTotalEmissionsPenalty

    end

    return EP
end
