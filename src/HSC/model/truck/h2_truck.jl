

@doc raw"""
    h2_truck(EP::Model, inputs::Dict, setup::Dict)

This function includes three parts of the Truck Model.The details can be found seperately in "h2\_truck\_investment.jl" "h2\_long\_duration\_truck.jl" and "h2\_truck\_all.jl".
"""
function h2_truck(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("Hydrogen Truck Module")

    # investment variables expressions and related constraints for H2 trucks
    EP = h2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

    # Operating variables, expressions and constraints related to H2 trucks
    EP = h2_truck_all(EP, inputs, setup)

    # Include LongDurationTruck only when modeling representative periods and long-duration truck
    if setup["OperationWrapping"] == 1 && !isempty(inputs["H2_TRUCK_LONG_DURATION"])
        EP = h2_long_duration_truck(EP, inputs)
    end

    return EP
end
