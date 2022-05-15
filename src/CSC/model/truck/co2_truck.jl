function co2_truck(EP::Model, inputs::Dict, setup::Dict)

    println("Carbon Truck Module")

    # investment variables expressions and related constraints for carbon trucks
    EP = co2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

    # Operating variables, expressions and constraints related to carbon trucks
    EP = co2_truck_all(EP, inputs, setup)

    # Include LongDurationTruck only when modeling representative periods and long-duration truck
    if setup["OperationWrapping"] == 1 && !isempty(inputs["CO2_TRUCK_LONG_DURATION"])
        EP = co2_long_duration_truck(EP, inputs)
    end
    
    return EP
end
