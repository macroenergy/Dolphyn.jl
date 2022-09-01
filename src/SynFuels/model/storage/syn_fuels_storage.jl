function hsyn_fuels_storage(EP::Model, inputs::Dict, setup::Dict)

    println("Synthesis Fuels Storage Module")

    if !isempty(inputs["SYN_STOR_ALL"])
        # investment variables expressions and related constraints for H2 storage tehcnologies
        EP = syn_fuels_storage_investment_energy(EP, inputs, setup)

        # Operating variables, expressions and constraints related to H2 storage
        EP = syn_fuels_storage_all(EP, inputs, setup)

        # Include LongDurationStorage only when modeling representative periods and long-duration storage
        if setup["OperationWrapping"] == 1 && !isempty(inputs["SYN_STOR_LONG_DURATION"])
            EP = syn_fuels_long_duration_storage(EP, inputs)
        end
    end

    if !isempty(inputs["H2_STOR_ASYMMETRIC"])
        EP = syn_fuels_storage_investment_charge(EP, inputs, setup)
        EP = syn_fuels_storage_asymmetric(EP, inputs)
    end

    if !isempty(inputs["SYN_STOR_SYMMETRIC"])
        EP = syn_fuels_storage_symmetric(EP, inputs)
    end

    return EP

end
