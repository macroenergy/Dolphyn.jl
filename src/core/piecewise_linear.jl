function piecewise_linear_expression(EP::Model, x::VariableRef, y::VariableRef, x_data::AbstractArray{<:Real}, y_data::AbstractArray{<:Real})
    # Check the x_data and y_data are the same length
    @assert(
        length(x_data) == length(y_data), 
        "x_data and y_data must be the same length when making a piecewise linear expression."
    )

    num_sections = length(x_data)
    
    # Make an anonymous variable lambda to interpolate between the x_data and y_data
    lambda = @variable(EP, [1:num_sections], lower_bound=0, upper_bound=1)

    @constraints(EP, begin
        # Constrain the input variable
        x == sum(x_data[i] * lambda[i] for i=1:num_sections)
        # Constrain the output variable
        y == sum(y_data[i] * lambda[i] for i=1:num_sections) 
        # Ensure interpolation is valid
        sum(lambda) == 1 
        # Apply SOS2 constraints
        lambda in SOS2() 
    end)

    return lambda
end