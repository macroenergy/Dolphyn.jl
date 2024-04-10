function piecewise_linear_constraints!(EP::Model, x::AbstractArray{VariableRef}, y::AbstractArray{VariableRef}, x_data::AbstractArray{<:Real}, y_data::AbstractArray{<:Real}, num_sections::Int=0)
    # Check the x_data and y_data are the same length
    data_length = length(x_data)

    @assert(
        data_length == length(y_data), 
        "x_data and y_data must be the same length when making a piecewise linear expression."
    )

    if !((num_sections <= 0) || (num_sections == data_length - 1))
        @error "Number of piecewise sections specified is not equal to the length of the data"
        # @info "Number of piecewise sections specified is not equal to the length of the data - using the specified number of sections."
        # data_length = num_sections + 1
        # x_data, y_data = select_pw_data(x_data, y_data, data_length)
    end

    for i in eachindex(x)
        # Make an anonymous variable lambda to interpolate between the x_data and y_data
        lambda = @variable(EP, [1:data_length], lower_bound=0, upper_bound=1)

        piecewise_linear_constraints!(EP, x[i], y[i], x_data, y_data, lambda)
    end
    return nothing
end

function piecewise_linear_constraints!(EP::Model, x::AbstractArray{AffExpr}, y::AbstractArray{VariableRef}, x_data::AbstractArray{<:Real}, y_data::AbstractArray{<:Real}, num_sections::Int=0)
    # Check the x_data and y_data are the same length
    data_length = length(x_data)

    @assert(
        data_length == length(y_data), 
        "x_data and y_data must be the same length when making a piecewise linear expression."
    )

    if !((num_sections <= 0) || (num_sections == data_length - 1))
        @error "Number of piecewise sections specified is not equal to the length of the data"
        # @info "Number of piecewise sections specified is not equal to the length of the data - using the specified number of sections."
        # data_length = num_sections + 1
        # x_data, y_data = select_pw_data(x_data, y_data, data_length)
    end

    for i in eachindex(x)
        # Make an anonymous variable lambda to interpolate between the x_data and y_data
        lambda = @variable(EP, [1:data_length], lower_bound=0, upper_bound=1)

        piecewise_linear_constraints!(EP, x[i], y[i], x_data, y_data, lambda)
    end
    return nothing
end

function piecewise_linear_constraints!(EP::Model, x::VariableRef, y::VariableRef, x_data::AbstractArray{<:Real}, y_data::AbstractArray{<:Real},  num_sections::Int=0)
    # Check the x_data and y_data are the same length
    data_length = length(x_data)

    @assert(
        data_length == length(y_data), 
        "x_data and y_data must be the same length when making a piecewise linear expression."
    )

    if !((num_sections <= 0) || (num_sections == data_length - 1))
        @error "Number of piecewise sections specified is not equal to the length of the data"
        # @info "Number of piecewise sections specified is not equal to the length of the data - using the specified number of sections."
        # data_length = num_sections + 1
        # x_data, y_data = select_pw_data(x_data, y_data, data_length)
    end
    
    # Make an anonymous variable lambda to interpolate between the x_data and y_data
    lambda = @variable(EP, [1:data_length], lower_bound=0, upper_bound=1)

    piecewise_linear_constraints!(EP, x, y, x_data, y_data, lambda)

    return lambda
end

function piecewise_linear_constraints!(EP::Model, x::VariableRef, y::VariableRef, x_data::AbstractArray{<:Real}, y_data::AbstractArray{<:Real}, lambda::AbstractArray{VariableRef})
    @constraints(EP, begin
        # Constrain the input variable
        x == sum(x_data[i] * lambda[i] for i in eachindex(x_data))
        # Constrain the output variable
        y == sum(y_data[i] * lambda[i] for i in eachindex(y_data))
        # Ensure interpolation is valid
        sum(lambda) == 1 
        # Apply SOS2 constraints
        lambda in SOS2() 
    end)
    return
end

function piecewise_linear_constraints!(EP::Model, x::AffExpr, y::VariableRef, x_data::AbstractArray{<:Real}, y_data::AbstractArray{<:Real}, lambda::AbstractArray{VariableRef})
    @constraints(EP, begin
        # Constrain the input variable
        x == sum(x_data[i] * lambda[i] for i in eachindex(x_data))
        # Constrain the output variable
        y == sum(y_data[i] * lambda[i] for i in eachindex(y_data))
        # Ensure interpolation is valid
        sum(lambda) == 1 
        # Apply SOS2 constraints
        lambda in SOS2() 
    end)
    return
end

function select_pw_data(x_data::Vector{<:Real}, y_data::Vector{<:Real}, target_length::Int)
    # <To do>
    # data_length = length(x_data)
    # # If data_length and target_legnth are the same, return the data
    # if data_length == target_length
    #     return x_data, y_data
    # end
    # # If data_length and target_length are both odd
    # idx = Int[1:2:data_length]

end