function h2_storage(EP::Model, inputs::Dict, setup::Dict)

    println("Hydrogen Storage Module")

    if !isempty(inputs["H2_STOR_ALL"])
        # investment variables expressions and related constraints for H2 storage tehcnologies
        EP = h2_storage_investment_energy(EP, inputs, setup)

        # Operating variables, expressions and constraints related to H2 storage
        EP = h2_storage_all(EP, inputs, setup)

        # Include LongDurationStorage only when modeling representative periods and long-duration storage
        if setup["OperationWrapping"] == 1 && !isempty(inputs["H2_STOR_LONG_DURATION"])
            EP = h2_long_duration_storage(EP, inputs)
        end
    end

    if !isempty(inputs["H2_STOR_ASYMMETRIC"])
        EP = h2_storage_investment_charge(EP, inputs, setup)
        EP = h2_storage_asymmetric(EP, inputs)
    end

    if !isempty(inputs["H2_STOR_SYMMETRIC"])
        EP = h2_storage_symmetric(EP, inputs)
    end

    return EP
end
