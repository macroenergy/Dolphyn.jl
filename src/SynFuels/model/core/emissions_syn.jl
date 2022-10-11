"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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
	emissions_syn(EP::Model, inputs::Dict, setup::Dict)

This function creates expression to add the CO2 emissions by plants in each zone, which is subsequently added to the total emissions
"""
function emissions_syn(EP::Model, inputs::Dict, setup::Dict)

    println("Synthesis Fuels Emissions Module for CO2 Policy modularization")

    dfSynGen = inputs["dfSynGen"]

    H = inputs["SYN_RES_ALL"]     # Number of resources (generators, storage, flexible demand)
    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones
    SYN_CCS = inputs["SYN_CCS"]

    # If setup["ParameterScale] = 1, emissions expression and constraints are written in ktonnes
    # If setup["ParameterScale] = 0, emissions expression and constraints are written in tonnes
    # Adjustment of Fuel_CO2 units carried out in load_fuels_data.jl

    @expression(
        EP,
        eSynEmissionsByPlant[k = 1:H, t = 1:T],
        if (dfSynGen[!, :SynStor_Charge_MMBtu_p_tonne][k] > 0) # IF storage consumes fuel during charging or not - not a default parameter input so hence the use of if condition
            inputs["fuel_CO2"][dfSynGen[!, :Fuel][k]] *
            dfSynGen[!, :etaFuel_MMBtu_p_tonne][k] *
            EP[:vSynGen][k, t] +
            inputs["fuel_CO2"][dfSynGen[!, :Fuel][k]] *
            dfSynGen[!, :SynStor_Charge_MMBtu_p_tonne][k] *
            EP[:vSyn_CHARGE_STOR][k, t]
        else
            inputs["fuel_CO2"][dfSynGen[!, :Fuel][k]] *
            dfSynGen[!, :etaFuel_MMBtu_p_tonne][k] *
            EP[:vSynGen][k, t]
        end
    )

    @expression(
        EP,
        eCO2CaptureSynByPlant[y in SYN_CCS, t = 1:T],
        dfSynGen[!, :CCS_Percentage][y] / (1 - dfSynGen[!, :CCS_Percentage][y]) *
        eSynEmissionsByPlant[y, t]
    )

    @expression(
        EP,
        eSynEmissionsByZone[z = 1:Z, t = 1:T],
        sum(eSynEmissionsByPlant[y, t] for y in dfSynGen[(dfSynGen[!, :Zone].==z), :R_ID])
    )

    # This expression is used for hydrogen plant with CCS
    @expression(
		EP,
		eCO2CaptureSynByZone[z = 1:Z, t = 1:T],
		sum(eCO2CaptureSynByPlant[y, t] for y in intersect(dfSynGen[(dfSynGen[!, :Zone].==z), :R_ID], SYN_CCS))
	)

    EP[:eCO2PSCEmissionsByZone] += eSynEmissionsByZone
    EP[:eCO2PSCCaptureByZone] += eCO2CaptureSynByZone

    # If CO2 price is implemented in HSC balance or Power Balance and SystemCO2 constraint is active (independent or joint), then need to add cost penalty due to CO2 prices
    if (setup["SynCO2Cap"] == 4 && setup["SystemCO2Constraint"] == 1)
        # Use CO2 price for HSC supply chain
        # Emissions penalty by zone - needed to report zonal cost breakdown
        @expression(
            EP,
            eCSynEmissionsPenaltybyZone[z = 1:Z],
            sum(
                inputs["omega"][t] * sum(
                    eSynEmissionsByZone[z, t] * inputs["dfH2CO2Price"][z, cap] for
                    cap in findall(x -> x == 1, inputs["dfH2CO2CapZones"][z, :])
                ) for t = 1:T
            )
        )
        # Sum over each policy type, each zone and each time step
        @expression(
            EP,
            eCSynEmissionsPenaltybyPolicy[cap = 1:inputs["H2NCO2Cap"]],
            sum(
                inputs["omega"][t] * sum(
                    eSynEmissionsByZone[z, t] * inputs["dfH2CO2Price"][z, cap] for
                    z in findall(x -> x == 1, inputs["dfH2CO2CapZones"][:, cap])
                ) for t = 1:T
            )
        )
        # Total emissions penalty across all policy constraints
        @expression(
            EP,
            eCSynGenTotalEmissionsPenalty,
            sum(eCSynEmissionsPenaltybyPolicy[cap] for cap = 1:inputs["H2NCO2Cap"])
        )

        # Add total emissions penalty associated with direct emissions from H2 generation technologies
        EP[:eObj] += eCSynGenTotalEmissionsPenalty


    elseif (setup["CO2Cap"] == 4 && setup["SystemCO2Constraint"] == 2)
        # Use CO2 price for power system as the global CO2 price
        # Emissions penalty by zone - needed to report zonal cost breakdown
        @expression(
            EP,
            eCSynEmissionsPenaltybyZone[z = 1:Z],
            sum(
                inputs["omega"][t] * sum(
                    eSynEmissionsByZone[z, t] * inputs["dfCO2Price"][z, cap] for
                    cap in 1:inputs["NCO2Cap"]
                ) for t = 1:T
            )
        )
        # Sum over each policy type, each zone and each time step
        @expression(
            EP,
            eCSynEmissionsPenaltybyPolicy[cap = 1:inputs["NCO2Cap"]],
            sum(
                inputs["omega"][t] * sum(
                    eSynEmissionsByZone[z, t] * inputs["dfCO2Price"][z, cap] for
                    z in findall(x -> x == 1, inputs["dfCO2CapZones"][:, cap])
                ) for t = 1:T
            )
        )
        @expression(
            EP,
            eCSynGenTotalEmissionsPenalty,
            sum(eCSynEmissionsPenaltybyZone[z] for z = 1:Z)
        )

        # Add total emissions penalty associated with direct emissions from H2 generation technologies
        EP[:eObj] += eCSynGenTotalEmissionsPenalty

    end

    return EP
end
