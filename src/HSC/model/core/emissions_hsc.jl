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
    emissions_hsc(EP::Model, inputs::Dict, setup::Dict)

This function creates expression to add the CO2 emissions for hydrogen supply chain in each zone, which is subsequently added to the total emissions.

**Cost expressions**

```math
\begin{equation*}
    \textrm{C}^{\textrm{H,EMI}} = \omega_t \times \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \textrm{c}_{z}^{\textrm{H,EMI}} x_{z,t}^{\textrm{H,EMI}}
\end{equation*}
```
"""
function emissions_hsc(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("H2 Emissions Module for CO2 Policy modularization")

    dfH2Gen = inputs["dfH2Gen"]

    H = inputs["H2_RES_ALL"]     # Number of resources (generators, storage, flexible demand)
    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones

    # If setup["ParameterScale] = 1, emissions expression and constraints are written in ktonnes
    # If setup["ParameterScale] = 0, emissions expression and constraints are written in tonnes
    # Adjustment of Fuel_CO2 units carried out in load_fuels_data.jl
    @expression(
        EP,
        eH2EmissionsByPlant[k = 1:H, t = 1:T],
        if (dfH2Gen[!, :H2Stor_Charge_MMBtu_p_tonne][k] > 0) # IF storage consumes fuel during charging or not - not a default parameter input so hence the use of if condition
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :etaFuel_MMBtu_p_tonne][k] *
            EP[:vH2Gen][k, t] * (1-dfH2Gen[!, :CCS_Rate][k])+
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :H2Stor_Charge_MMBtu_p_tonne][k] *
            EP[:vH2_CHARGE_STOR][k, t] * (1-dfH2Gen[!, :CCS_Rate][k])
        else
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :etaFuel_MMBtu_p_tonne][k] *
            EP[:vH2Gen][k, t] * (1-dfH2Gen[!, :CCS_Rate][k])
        end
    )

    @expression(
        EP,
        eCO2CaptureByH2Plant[k = 1:H, t = 1:T],
        if (dfH2Gen[!, :H2Stor_Charge_MMBtu_p_tonne][k] > 0) # IF storage consumes fuel during charging or not - not a default parameter input so hence the use of if condition
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :etaFuel_MMBtu_p_tonne][k] *
            EP[:vH2Gen][k, t] * 
            (dfH2Gen[!, :CCS_Rate][k]) +
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :H2Stor_Charge_MMBtu_p_tonne][k] *
            EP[:vH2_CHARGE_STOR][k, t] * 
            (dfH2Gen[!, :CCS_Rate][k])
        else
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :etaFuel_MMBtu_p_tonne][k] *
            EP[:vH2Gen][k, t] * 
            (dfH2Gen[!, :CCS_Rate][k])
        end
    )

    eH2EmissionsByZone = eH2EmissionsByZone!(EP, T, Z, eH2EmissionsByPlant, dfH2Gen)

    # If CO2 price is implemented in HSC balance or Power Balance and SystemCO2 constraint is active (independent or joint), then need to add cost penalty due to CO2 prices
    if (setup["H2CO2Cap"] == 4 && setup["SystemCO2Constraint"] == 1)
        # Use CO2 price for HSC supply chain
        # Emissions penalty by zone - needed to report zonal cost breakdown
        eCH2EmissionsPenaltybyZone!(EP, T, Z, eH2EmissionsByZone, inputs["dfH2CO2Price"], inputs["dfH2CO2CapZones"], inputs["omega"])

        # Sum over each policy type, each zone and each time step
        eCH2EmissionsPenaltybyPolicy = eCH2EmissionsPenaltybyPolicy!(EP, T, Z, eH2EmissionsByZone, inputs["dfH2CO2Price"], inputs["dfH2CO2CapZones"], inputs["omega"])
        
        # Total emissions penalty across all policy constraints
        eCH2GenTotalEmissionsPenalty = sum_expression(eCH2EmissionsPenaltybyPolicy[1:inputs["H2NCO2Cap"]])
        EP[:eCH2GenTotalEmissionsPenalty] = eCH2GenTotalEmissionsPenalty

        # Add total emissions penalty associated with direct emissions from H2 generation technologies
        add_similar_to_expression!(EP[:eObj], eCH2GenTotalEmissionsPenalty)


    elseif (setup["CO2Cap"] == 4 && setup["SystemCO2Constraint"] == 2)
        # Use CO2 price for power system as the global CO2 price
        # Emissions penalty by zone - needed to report zonal cost breakdown
        eCH2EmissionsPenaltybyZone!(EP, T, Z, eH2EmissionsByZone, inputs["dfCO2Price"], inputs["dfH2CO2CapZones"], inputs["omega"])

        # Sum over each policy type, each zone and each time step
        eCH2EmissionsPenaltybyPolicy = eCH2EmissionsPenaltybyPolicy!(EP, T, Z, eH2EmissionsByZone, inputs["dfH2CO2Price"], inputs["dfH2CO2CapZones"], inputs["omega"])

        eCH2GenTotalEmissionsPenalty = sum_expression(eCH2EmissionsPenaltybyPolicy[1:inputs["NCO2Cap"]])
        EP[:eCH2GenTotalEmissionsPenalty] = eCH2GenTotalEmissionsPenalty
        # Add total emissions penalty associated with direct emissions from H2 generation technologies
        add_similar_to_expression!(EP[:eObj], eCH2GenTotalEmissionsPenalty)

    end

    return EP

end

function eH2EmissionsByZone!(EP::Model, T::Int, Z::Int, eH2EmissionsByPlant::AbstractArray{AffExpr}, dfH2Gen::DataFrame)
    eH2EmissionsByZone = create_empty_expression((Z,T))
    @inbounds for t = 1:T
        @inbounds for z = 1:Z
            eH2EmissionsByZone[z,t] = sum_expression(eH2EmissionsByPlant[y,t] for y in dfH2Gen[(dfH2Gen[!,:Zone].==z), :R_ID])
        end
    end
    EP[:eH2EmissionsByZone] = eH2EmissionsByZone
    return eH2EmissionsByZone
end

function eCH2EmissionsPenaltybyZone!(EP::Model, T::Int, Z::Int, eH2EmissionsByZone::AbstractArray{AffExpr}, co2_price::DataFrame, dfCO2CapZones::DataFrame, omega::AbstractArray{Float64})
    eCH2EmissionsPenaltybyZone = create_empty_expression(Z)
    @inbounds for z = 1:Z
        cap_zones = findall(x -> x == 1, dfCO2CapZones[z, :])
        @inbounds for t = 1:T
            eCH2EmissionsPenaltybyZone[z] = sum_expression(
                omega[t] * co2_price[z, cap_zones] * eH2EmissionsByZone[z, t]
            )
        end
    end
    EP[:eCH2EmissionsPenaltybyZone] = eCH2EmissionsPenaltybyZone
    return nothing
end

function eCH2EmissionsPenaltybyPolicy!(EP::Model, T::Int, Z::Int, eH2EmissionsByZone::AbstractArray{AffExpr}, co2_price::DataFrame, dfCO2CapZones::DataFrame, omega::AbstractArray{Float64})
    eCH2EmissionsPenaltybyPolicy = create_empty_expression(H2NCO2Cap)
    @inbounds for cap = 1:H2NCO2Cap
        cap_zones = findall(x -> x == 1, dfCO2CapZones[:, cap])
        @inbounds for t = 1:T
            eCH2EmissionsPenaltybyPolicy[cap] = sum_expression(
                omega[t] .* co2_price[cap_zones, cap] .* eH2EmissionsByZone[cap_zones, t]
            )
        end
    end
    return eCH2EmissionsPenaltybyPolicy
end