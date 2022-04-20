function co2_storage(EP::Model, inputs::Dict, setup::Dict)

    println("Carbon Storage Module")

   # investment variables expressions and related constraints for CO2 storage tehcnologies
    EP = co2_storage_investment(EP::Model, inputs::Dict, setup::Dict)

    # Operating variables, expressions and constraints related to CO2 storage
    EP = co2_storage_all(EP, inputs, setup)


    # Include LongDurationStorage only when modeling representative periods and long-duration storage
    if setup["OperationWrapping"] == 1 && !isempty(inputs["CO2_STOR_LONG_DURATION"])
        EP = co2_long_duration_storage(EP, inputs)
    end

    return EP
end
