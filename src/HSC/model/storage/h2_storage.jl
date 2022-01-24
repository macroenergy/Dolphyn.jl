function h2_storage(EP::Model, inputs::Dict, setup::Dict)

    println("Hydrogen Storage Module")

   # investment variables expressions and related constraints for H2 storage tehcnologies
    EP = h2_storage_investment(EP::Model, inputs::Dict, setup::Dict)

    # Operating variables, expressions and constraints related to H2 storage
    EP = h2_storage_all(EP, inputs, setup)


    # Include LongDurationStorage only when modeling representative periods and long-duration storage
    if setup["OperationWrapping"] == 1 && !isempty(inputs["H2_STOR_LONG_DURATION"])
        EP = h2_long_duration_storage(EP, inputs)
    end

    return EP
end
