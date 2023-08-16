@doc raw"""
    elec_imports(EP::Model, inputs::Dict, setup::Dict)

TO DO
"""
function elec_imports!(EP::Model, inputs::Dict, setup::Dict)
    # No capital equipment is required to import electricity (for now)
    # In the future we could look at requiring transmission or distribution infrastructure

    Z = inputs["Z"] # Number of zones
    T = inputs["T"] # Number of time periods

    # Hourly electricity imports in each zone
    @variable(EP, vElecImports_HSC[t=1:T,z=1:Z] >= 0) 

    if !(inputs["HSC_elec_imports_limits"] === nothing)
        # Limit the hourly imports based on the exogenous capacity limits, if they exist
        @constraint(EP, cElecImportsLimits_HSC[t=1:T,z=1:Z], vElecImports_HSC[t,z] <= inputs["HSC_elec_imports_limits"][t,z])
    end

    # Add to the power balance
    add_similar_to_expression!(EP[:ePowerBalance], vElecImports_HSC)

    # Cost of imports
    @expression(EP, eElecImportsCost_HSC[z=1:Z,t=1:T], vElecImports_HSC[t,z] * inputs["HSC_elec_imports_prices"][t,z])

    # Total import Cost
    @expression(EP, eElecImportsCostTot_HSC, sum_expression(eElecImportsCost_HSC))
    
    # Add cost of imports to the objective function
    add_to_expression!(EP[:eObj], eElecImportsCostTot_HSC)
    
    return nothing
end