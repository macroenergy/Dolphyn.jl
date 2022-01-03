function h2_truck(EP::Model, inputs::Dict, setup::Dict)

    println("Hydrogen Truck Module")

    # investment variables expressions and related constraints for H2 trucks
    EP = h2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

     # Operating variables, expressions and constraints related to H2 trucks
    EP = h2_truck_all(EP, inputs, setup)

    # Include LongDurationtruck only when modeling representative periods
    if setup["OperationWrapping"] == 1
        EP = h2_long_duration_truck(EP, inputs)
    end
    
    return EP
end
