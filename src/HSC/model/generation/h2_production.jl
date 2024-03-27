

@doc raw"""
    h2_production(EP::Model, inputs::Dict, setup::Dict)

This module creates decision variables, expressions, and constraints related to various hydrogen generation technologies (electrolyzers, natural gas reforming etc.)

This module uses the following 'helper' functions in separate files: ```h2_production_commit()``` for thermal resources subject to unit commitment decisions and constraints (if any) and ```h2_production_no_commit()``` for thermal hydrogen generation resources not subject to unit commitment (if any).
"""
function h2_production(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("Hydrogen Production Module")
    
    if !isempty(inputs["H2_GEN"])
    # expressions, variables and constraints common to all types of hydrogen generation technologies
        EP = h2_production_all(EP::Model, inputs::Dict, setup::Dict)
    end

    if setup["ModelH2Liquid"] ==1
        H2_GEN_COMMIT = union(inputs["H2_GEN_COMMIT"], inputs["H2_LIQ_COMMIT"], inputs["H2_EVAP_COMMIT"])
        H2_GEN_NO_COMMIT = union(inputs["H2_GEN_NO_COMMIT"], inputs["H2_LIQ_NO_COMMIT"], inputs["H2_EVAP_NO_COMMIT"])
    else
        H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]::Vector{<:Int}
        H2_GEN_NO_COMMIT = inputs["H2_GEN_NO_COMMIT"]
    end
    dfH2Gen = inputs["dfH2Gen"]::DataFrame  # Input H2 generation and storage data
    Z = inputs["Z"]::Int  # Model demand zones - assumed to be same for H2 and electricity
    T = inputs["T"]::Int     # Model operating time steps

    if !isempty(H2_GEN_COMMIT)
        EP = h2_production_commit(EP::Model, inputs::Dict, setup::Dict)
    end

    if !isempty(H2_GEN_NO_COMMIT)
        EP = h2_production_no_commit(EP::Model, inputs::Dict,setup::Dict)
    end

    ## For CO2 Policy constraint right hand side development - H2 Generation by zone and each time step
    @expression(EP, eH2GenerationByZone[z=1:Z, t=1:T], # the unit is tonne/hour
    sum(EP[:vH2Gen][y,t] for y in intersect(inputs["H2_GEN"], dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID]))
    )


    add_similar_to_expression!(EP[:eH2GenerationByZone], eH2GenerationByZone)

    return EP
end
