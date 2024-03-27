@doc raw"""
    h2_storage(EP::Model, inputs::Dict, setup::Dict)
    
A wide range of energy storage devices (all $s \in \mathcal{S}$) can be modeled in DOLPHYN, using one of two generic storage formulations: 
(1) storage technologies with symmetric charge and discharge capacity (all $s \in \mathcal{S}^{sym}$), such as Lithium-ion batteries and most other electrochemical storage devices that use the same components for both charge and discharge; and 
(2) storage technologies that employ distinct and potentially asymmetric charge and discharge capacities (all $s \in \mathcal{S}^{asym}$), such as most thermal storage technologies or hydrogen electrolysis/storage/fuel cell or combustion turbine systems.
"""
function h2_storage(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("Hydrogen Storage Module")

    if !isempty(inputs["H2_STOR_ALL"])
        # investment variables expressions and related constraints for H2 storage tehcnologies
        EP = h2_storage_investment_energy(EP, inputs, setup)

        #  Investment corresponding to charging component of storage (e.g. Liquefier, compressor)
        EP = h2_storage_investment_charge(EP, inputs, setup)

        # Operating variables, expressions and constraints related to H2 storage
        # Applies to all H2 storage resources
        EP = h2_storage_all(EP, inputs, setup)

        # DEV NOTE: add if conditions here for other types of storage technologies

        # Include LongDurationStorage only when modeling representative periods and long-duration storage
        if setup["OperationWrapping"] == 1 && !isempty(inputs["H2_STOR_LONG_DURATION"])
            EP = h2_long_duration_storage(EP, inputs)
        end
    end

    return EP
end
