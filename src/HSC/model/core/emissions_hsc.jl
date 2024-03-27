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
function emissions_hsc!(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("H2 emissions module for CO2 policy modularization")

    dfH2Gen = inputs["dfH2Gen"]::DataFrame

    H = inputs["H2_RES_ALL"]::Int    # Number of resources (generators, storage, flexible demand)
    T = inputs["T"]::Int    # Number of time steps (hours)
    Z = inputs["Z"]::Int     # Number of zones

    eH2EmissionsByPlant, eCO2CaptureByH2Plant = calc_emiss_and_capture_by_plant!(EP, T, H, EP[:vH2Gen], EP[:vH2_CHARGE_STOR], inputs["fuel_CO2"], dfH2Gen[!, :Fuel], dfH2Gen[!, :etaFuel_MMBtu_p_tonne], dfH2Gen[!, :H2Stor_Charge_MMBtu_p_tonne], dfH2Gen[!, :CCS_Rate])
    eH2EmissionsByZone = calc_emiss_by_zone!(EP, Z, T, eH2EmissionsByPlant, dfH2Gen[!, :Zone], dfH2Gen[!, :R_ID])

    # If CO2 price is implemented in HSC balance or Power Balance and SystemCO2 constraint is active (independent or joint), then need to add cost penalty due to CO2 prices
    if (setup["H2CO2Cap"] == 4 && setup["SystemCO2Constraint"] == 1)
        # Use CO2 price for HSC supply chain
        # Emissions penalty by zone - needed to report zonal cost breakdown
        hsc_calc_emiss_penalty!(EP, Z, T, eH2EmissionsByZone, inputs["H2NCO2Cap"], inputs["omega"], inputs["dfH2CO2Price"], inputs["dfH2CO2CapZones"])
    elseif (setup["CO2Cap"] == 4 && setup["SystemCO2Constraint"] == 2)
        # Use CO2 price for power system as the global CO2 price
        # Emissions penalty by zone - needed to report zonal cost breakdown
        hsc_calc_emiss_penalty!(EP, Z, T, eH2EmissionsByZone, inputs["H2NCO2Cap"], inputs["omega"], inputs["dfCO2Price"], inputs["dfH2CO2CapZones"])
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

# function hsc_calc_emiss_penalty!(EP::Model, Z::Int, T::Int, eH2EmissionsByZone::AbstractArray{AffExpr}, H2NCO2Cap::Int, omega::Vector{<:Real}, co2_price::AbstractArray{<:Real}, dfH2CO2CapZones::AbstractArray{<:Real})
#     eCH2EmissionsPenaltybyZone = create_zeros_expression(Z)
#     eCH2EmissionsPenaltybyPolicy = create_zeros_expression(H2NCO2Cap)

#     zones_for_cap = Dict{Int, Vector{Int}}()
#     @inbounds for cap in 1:H2NCO2Cap
#         zones_for_cap[cap] = findall(x -> x == 1, dfH2CO2CapZones[:, cap])
#     end

#     @inbounds for z in 1:Z
#         caps_for_zone = findall(x -> x == 1, dfH2CO2CapZones[z, :])
#         zone_sum = sum_expression(omega .* eH2EmissionsByZone[z, :])
#         if !isempty(caps_for_zone)
#             zone_co2_price = sum(co2_price[z,caps_for_zone])
#             eCH2EmissionsPenaltybyZone[z] = sum_expression(zone_co2_price * zone_sum)
#         end
#         @inbounds for cap in 1:H2NCO2Cap
#             if z in zones_for_cap[cap]
#                 eCH2EmissionsPenaltybyPolicy[cap] = sum_expression(co2_price[z, cap] * zone_sum)
#             end
#         end
#     end

#     eCH2GenTotalEmissionsPenalty = sum_expression(eCH2EmissionsPenaltybyPolicy)

#     # Add total emissions penalty associated with direct emissions from H2 generation technologies
#     add_similar_to_expression!(EP[:eObj], eCH2GenTotalEmissionsPenalty)

#     EP[:eCH2EmissionsPenaltybyZone] = eCH2EmissionsPenaltybyZone
#     EP[:eCH2EmissionsPenaltybyPolicy] = eCH2EmissionsPenaltybyPolicy
#     EP[:eCH2GenTotalEmissionsPenalty] = eCH2GenTotalEmissionsPenalty

#     return eCH2EmissionsPenaltybyZone, eCH2EmissionsPenaltybyPolicy, eCH2GenTotalEmissionsPenalty
# end

function hsc_calc_emiss_penalty!(EP::Model, Z::Int, T::Int, eH2EmissionsByZone::AbstractArray{AffExpr}, H2NCO2Cap::Int, omega::Vector{<:Real}, co2_price::AbstractArray{<:Real}, dfH2CO2CapZones::AbstractArray{<:Real})
    eCH2EmissionsPenaltybyZone = create_zeros_expression(Z)
    eCH2EmissionsPenaltybyPolicy = create_zeros_expression(H2NCO2Cap)

    @inbounds for cap in 1:H2NCO2Cap
        zones_for_cap = findall(x -> x == 1, dfH2CO2CapZones[:, cap])
        @inbounds for z in 1:Z
            caps_for_zone = findall(x -> x == 1, dfH2CO2CapZones[z, :])
            zone_co2_price = sum(co2_price[z,caps_for_zone], init=0.0)
            if !isempty(caps_for_zone) && (z in zones_for_cap)
                @inbounds for t in 1:T
                    add_to_expression!(eCH2EmissionsPenaltybyZone[z], eH2EmissionsByZone[z,t], omega[t] * zone_co2_price)
                    add_to_expression!(eCH2EmissionsPenaltybyPolicy[cap], eH2EmissionsByZone[z,t], omega[t] * co2_price[z, cap])
                end
            elseif isempty(caps_for_zone) && (z in zones_for_cap)
                @inbounds for t in 1:T
                    add_to_expression!(eCH2EmissionsPenaltybyPolicy[cap], eH2EmissionsByZone[z,t], omega[t] * co2_price[z, cap])
                end
            elseif !isempty(caps_for_zone) && !(z in zones_for_cap)
                @inbounds for t in 1:T
                    add_to_expression!(eCH2EmissionsPenaltybyZone[z], eH2EmissionsByZone[z,t], omega[t] * zone_co2_price)
                end
            else
                error("Problem occured in calc_emiss_penalty!")
            end
        end
    end

    eCH2GenTotalEmissionsPenalty = sum_expression(eCH2EmissionsPenaltybyPolicy)

    # Add total emissions penalty associated with direct emissions from H2 generation technologies
    add_similar_to_expression!(EP[:eObj], eCH2GenTotalEmissionsPenalty)

    EP[:eCH2EmissionsPenaltybyZone] = eCH2EmissionsPenaltybyZone
    EP[:eCH2EmissionsPenaltybyPolicy] = eCH2EmissionsPenaltybyPolicy
    EP[:eCH2GenTotalEmissionsPenalty] = eCH2GenTotalEmissionsPenalty

    return eCH2EmissionsPenaltybyZone, eCH2EmissionsPenaltybyPolicy, eCH2GenTotalEmissionsPenalty
end