

@doc raw"""
    h2_g2p(EP::Model, inputs::Dict, setup::Dict)

This module creates decision variables, expressions, and constraints related to various hydrogen to power technologies as well as carbon emission policy constraints.

This module uses the following 'helper' functions in separate files: ```h2_g2p_commit()``` for thermal resources subject to unit commitment decisions and constraints (if any) and ```h2_g2p_no_commit()``` for thermal resources not subject to unit commitment (if any).
"""
function h2_g2p(EP::Model, inputs::Dict, setup::Dict)

    if !isempty(inputs["H2_G2P"])
        EP = h2_g2p_investment(EP::Model, inputs::Dict, setup::Dict)
        EP = h2_g2p_discharge(EP::Model, inputs::Dict, setup::Dict)
        # expressions, variables and constraints common to all types of hydrogen generation technologies
        EP = h2_g2p_all(EP::Model, inputs::Dict, setup::Dict)
    end

    H2_G2P_COMMIT = inputs["H2_G2P_COMMIT"]::Vector{<:Int}
    H2_G2P_NO_COMMIT = inputs["H2_G2P_NO_COMMIT"]::Vector{<:Int}
    dfH2G2P = inputs["dfH2G2P"]::DataFrame  # Input H2 generation and storage data
    Z = inputs["Z"]::Int  # Model demand zones - assumed to be same for H2 and electricity
    T = inputs["T"]::Int     # Model operating time steps

    if !isempty(H2_G2P_COMMIT)
        EP = h2_g2p_commit(EP::Model, inputs::Dict, setup::Dict)
    end

    if !isempty(H2_G2P_NO_COMMIT)
        EP = h2_g2p_no_commit(EP::Model, inputs::Dict,setup::Dict)
    end

    ## For CO2 Policy constraint right hand side development - H2 Generation by zone and each time step
        @expression(EP, eGenerationByZoneG2P[z=1:Z, t=1:T], # the unit is tonne/hour
        sum(EP[:vPG2P][y,t] for y in intersect(inputs["H2_G2P"], dfH2G2P[dfH2G2P[!,:Zone].==z,:R_ID]))
    )

    @expression(EP, eH2DemandByZoneG2P[z=1:Z, t=1:T], # the unit is tonne/hour
        sum(EP[:vH2G2P][y,t] for y in intersect(inputs["H2_G2P"], dfH2G2P[dfH2G2P[!,:Zone].==z,:R_ID]))
    )

    add_similar_to_expression!(EP[:eGenerationByZone], eGenerationByZoneG2P)

    return EP
end
