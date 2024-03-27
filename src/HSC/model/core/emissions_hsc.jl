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

    H = inputs["H2_RES_ALL"]::Int    # Number of resources (generators, storage, flexible demand)
    T = inputs["T"]::Int    # Number of time steps (hours)
    Z = inputs["Z"]::Int     # Number of zones

    eH2EmissionsByPlant, eCO2CaptureByH2Plant = calc_emiss_and_capture_by_plant!(EP, T, H, EP[:vH2Gen], EP[:vH2_CHARGE_STOR], inputs["fuel_CO2"], dfH2Gen[!, :Fuel], dfH2Gen[!, :etaFuel_MMBtu_p_tonne], dfH2Gen[!, :H2Stor_Charge_MMBtu_p_tonne], dfH2Gen[!, :CCS_Rate])
    eH2EmissionsByZone = calc_emiss_by_zone!(EP, Z, T, eH2EmissionsByPlant, dfH2Gen[!, :Zone], dfH2Gen[!, :R_ID])

    # If CO2 price is implemented in HSC balance or Power Balance and SystemCO2 constraint is active (independent or joint), then need to add cost penalty due to CO2 prices
    if (setup["H2CO2Cap"] == 4 && setup["SystemCO2Constraint"] == 1)
        # Use CO2 price for HSC supply chain
        # Emissions penalty by zone - needed to report zonal cost breakdown
        # hsc_emissions_penalty!(EP, T, Z, inputs["H2NCO2Cap"], eH2EmissionsByZone, inputs["dfH2CO2Price"], inputs["dfH2CO2CapZones"], inputs["omega"])
        @expression(
            EP,
            eCH2EmissionsPenaltybyZone[z = 1:Z],
            sum(
                inputs["omega"][t] * sum(
                    eH2EmissionsByZone[z, t] * inputs["dfH2CO2Price"][z, cap] for
                    cap in findall(x -> x == 1, inputs["dfH2CO2CapZones"][z, :])
                ) for t = 1:T
            )
        )
        # Sum over each policy type, each zone and each time step
        @expression(
            EP,
            eCH2EmissionsPenaltybyPolicy[cap = 1:inputs["H2NCO2Cap"]],
            sum(
                inputs["omega"][t] * sum(
                    eH2EmissionsByZone[z, t] * inputs["dfH2CO2Price"][z, cap] for
                    z in findall(x -> x == 1, inputs["dfH2CO2CapZones"][:, cap])
                ) for t = 1:T
            )
        )
        # Total emissions penalty across all policy constraints
        @expression(
            EP,
            eCH2GenTotalEmissionsPenalty,
            sum(eCH2EmissionsPenaltybyPolicy[cap] for cap = 1:inputs["H2NCO2Cap"])
        )

        # Add total emissions penalty associated with direct emissions from H2 generation technologies
        add_similar_to_expression!(EP[:eObj], eCH2GenTotalEmissionsPenalty)


    elseif (setup["CO2Cap"] == 4 && setup["SystemCO2Constraint"] == 2)
        # Use CO2 price for power system as the global CO2 price
        # Emissions penalty by zone - needed to report zonal cost breakdown
        # hsc_emissions_penalty!(EP, T, Z, inputs["NCO2Cap"], eH2EmissionsByZone, inputs["dfCO2Price"], inputs["dfCO2CapZones"], inputs["omega"])
        @expression(
            EP,
            eCH2EmissionsPenaltybyZone[z = 1:Z],
            sum(
                inputs["omega"][t] * sum(
                    eH2EmissionsByZone[z, t] * inputs["dfCO2Price"][z, cap] for
                    cap in findall(x -> x == 1, inputs["dfCO2CapZones"][z, :])
                ) for t = 1:T
            )
        )
        # Sum over each policy type, each zone and each time step
        @expression(
            EP,
            eCH2EmissionsPenaltybyPolicy[cap = 1:inputs["NCO2Cap"]],
            sum(
                inputs["omega"][t] * sum(
                    eH2EmissionsByZone[z, t] * inputs["dfCO2Price"][z, cap] for
                    z in findall(x -> x == 1, inputs["dfCO2CapZones"][:, cap])
                ) for t = 1:T
            )
        )
        @expression(
            EP,
            eCH2GenTotalEmissionsPenalty,
            sum(eCH2EmissionsPenaltybyPolicy[cap] for cap = 1:inputs["NCO2Cap"])
        )

        # Add total emissions penalty associated with direct emissions from H2 generation technologies
        add_similar_to_expression!(EP[:eObj], eCH2GenTotalEmissionsPenalty)

    end

    return EP
end

function calc_emiss_by_plant!(EP::Model, T::Int, H::Int, vH2Gen::AbstractArray{VariableRef}, vH2_CHARGE_STOR::AbstractArray{VariableRef}, fuel_co2::Dict{AbstractString, Float64}, fuel_names::Vector{<:AbstractString}, fuel_eta::Vector{<:Real}, h2_stor_charge::Vector{<:Real}, ccs_rate::Vector{<:Real})
    @expression(
        EP,
        eH2EmissionsByPlant[k = 1:H, t = 1:T],
        if (h2_stor_charge[k] > 0) # IF storage consumes fuel during charging or not - not a default parameter input so hence the use of if condition
            (vH2Gen[k, t] * fuel_eta[k] + vH2_CHARGE_STOR[k, t] * h2_stor_charge[k]) * fuel_co2[fuel_names[k]] * (1 - ccs_rate[k])
        else
            vH2Gen[k, t] * fuel_co2[fuel_names[k]] * fuel_eta[k] * (1 - ccs_rate[k])
        end
    )
    return eH2EmissionsByPlant
end
    
function calc_emiss_capture_by_plant!(EP::Model, T::Int, H::Int, vH2Gen::AbstractArray{VariableRef}, vH2_CHARGE_STOR::AbstractArray{VariableRef}, fuel_co2::Dict{AbstractString, Float64}, fuel_names::Vector{<:AbstractString}, fuel_eta::Vector{<:Real}, h2_stor_charge::Vector{<:Real}, ccs_rate::Vector{<:Real})
    @expression(
        EP,
        eCO2CaptureByH2Plant[k = 1:H, t = 1:T],
        if (h2_stor_charge[k] > 0) # IF storage consumes fuel during charging or not - not a default parameter input so hence the use of if condition
            (vH2Gen[k, t] * fuel_eta[k] + vH2_CHARGE_STOR[k, t] * h2_stor_charge[k]) * fuel_co2[fuel_names[k]] * ccs_rate[k]
        else
            vH2Gen[k, t] * fuel_co2[fuel_names[k]] * fuel_eta[k] * ccs_rate[k]
        end
    )
    return eCO2CaptureByH2Plant
end

function calc_emiss_by_zone!(EP::Model, Z::Int, T::Int, eH2EmissionsByPlant::AbstractArray{AffExpr}, zones::Vector{Int}, r_id::Vector{Int})
    eH2EmissionsByZone = create_empty_expression((Z,T))
    @inbounds for t = 1:T
        @inbounds for z in 1:Z
            eH2EmissionsByZone[z, t] = sum_expression(eH2EmissionsByPlant[y,t] for y in r_id[zones.==z])
        end
    end
    EP[:eH2EmissionsByZone] = eH2EmissionsByZone
    return eH2EmissionsByZone
end

function calc_emiss_and_capture_by_plant!(EP::Model, T::Int, H::Int, vH2Gen::AbstractArray{VariableRef}, vH2_CHARGE_STOR::AbstractArray{VariableRef}, fuel_co2::Dict{AbstractString, Float64}, fuel_names::Vector{<:AbstractString}, fuel_eta::Vector{<:Real}, h2_stor_charge::Vector{<:Real}, ccs_rate::Vector{<:Real})
    eH2EmissionsByPlant = create_empty_expression((H,T))
    eCO2CaptureByH2Plant = create_empty_expression((H,T))

    emiss_coeff = Dict{Int64, Float64}()
    emiss_stor_coeff = Dict{Int64, Float64}()
    capture_coeff = Dict{Int64, Float64}()
    capture_stor_coeff = Dict{Int64, Float64}()
    @inbounds for k = 1:H
        fuel_emiss = fuel_co2[fuel_names[k]]
        emiss_coeff[k] = fuel_emiss * fuel_eta[k] * (1 - ccs_rate[k])
        emiss_stor_coeff[k] = fuel_emiss * h2_stor_charge[k] * (1 - ccs_rate[k])

        capture_coeff[k] = fuel_emiss * fuel_eta[k] * ccs_rate[k]
        capture_stor_coeff[k] = fuel_emiss * h2_stor_charge[k] * ccs_rate[k]
    end

    @inbounds for t = 1:T
        @inbounds for k = 1:H
            eH2EmissionsByPlant[k,t] = vH2Gen[k, t] * emiss_coeff[k]
            eCO2CaptureByH2Plant[k,t] = vH2Gen[k, t] * capture_coeff[k]
            if h2_stor_charge[k] > 0
                add_to_expression!(eH2EmissionsByPlant[k,t], vH2_CHARGE_STOR[k, t], emiss_stor_coeff[k])
                add_to_expression!(eCO2CaptureByH2Plant[k,t], vH2_CHARGE_STOR[k, t], capture_stor_coeff[k])
            end
        end
    end

    EP[:eH2EmissionsByPlant] = eH2EmissionsByPlant
    EP[:eCO2CaptureByH2Plant] = eCO2CaptureByH2Plant

    return eH2EmissionsByPlant, eCO2CaptureByH2Plant
end

function hsc_emissions_penalty!(EP::Model, T::Int, Z::Int, co2_cap::Int, eH2EmissionsByZone::AbstractArray{AffExpr}, co2_price::AbstractArray{Float64,2}, co2_cap_zones::AbstractArray{Int64,2}, omega::AbstractArray{Float64})
    eCH2EmissionsPenaltybyZone = create_empty_expression(Z)
    eCH2EmissionsPenaltybyPolicy = create_empty_expression(co2_cap)

    @inbounds for z = 1:Z
        cap_set = findall(x -> x == 1, co2_cap_zones[z, :])
        eCH2EmissionsPenaltybyZone[z] = sum_expression(
            inputs["omega"][:] .* eH2EmissionsByZone[z, :] * co2_price[z, cap]
            for cap in cap_set
        )
    end

    # Sum over each policy type, each zone and each time step
    @inbounds for cap = 1:co2_cap
        zone_set = z in findall(x -> x == 1, inputs["dfH2CO2CapZones"][:, cap])
        eCH2EmissionsPenaltybyPolicy[cap] = sum_expression(
            inputs["omega"][:] .* eH2EmissionsByZone[z, :] * co2_price[z, cap]
            for z in zone_set
        )
    end
    # Total emissions penalty across all policy constraints
    eCH2GenTotalEmissionsPenalty = sum_expression(eCH2EmissionsPenaltybyPolicy)

    # Add total emissions penalty associated with direct emissions from H2 generation technologies
    add_similar_to_expression!(EP[:eObj], eCH2GenTotalEmissionsPenalty)

    EP[:eCH2EmissionsPenaltybyZone] = eCH2EmissionsPenaltybyZone
    EP[:eCH2EmissionsPenaltybyPolicy] = eCH2EmissionsPenaltybyPolicy
    EP[:eCH2GenTotalEmissionsPenalty] = eCH2GenTotalEmissionsPenalty

    return nothing

end