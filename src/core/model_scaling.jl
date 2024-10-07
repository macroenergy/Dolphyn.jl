function scale_constraints!(EP::Model, coeff_range::Tuple{Float64, Float64}=(1e-3, 1e6), min_coeff::Float64=1e-9; count_actions::Bool=false)
    con_list = all_constraints(EP; include_variable_in_set_constraints=false)
    action_count = scale_constraint!.(con_list, Ref(coeff_range), Ref(min_coeff));
    if count_actions
        return sum(action_count)
    else
        return nothing
    end
end

function scale_constraints!(constraint_list::Vector{ConstraintRef}, coeff_range::Tuple{Float64, Float64}=(1e-3, 1e6), min_coeff::Float64=1e-9; count_actions::Bool=false)
    action_count = 0
    for con_ref in constraint_list
        action_count += scale_constraint!(con_ref, coeff_range, min_coeff)
    end
    if count_actions
        return action_count
    else
        return nothing
    end
end

function parse_name(input::AbstractString)
    # Find the position of the opening bracket '['
    open_bracket_pos = findfirst(isequal('['), input)
    if open_bracket_pos === nothing
        # No brackets found, return the whole string as the name
        return input, nothing
    end
    # Extract the name part
    name = input[1:open_bracket_pos-1]
    # Extract the indexes part
    indexes_part = input[open_bracket_pos+1:end-1]  # Remove the closing bracket ']'
    # Split the indexes part by comma
    indexes = split(indexes_part, ',')
    # Parse the indexes as integers
    parsed_indexes = [parse(Int, index) for index in indexes]
    return name, parsed_indexes
end

function make_constraint(EP::Model, var_coeff_pairs::AbstractDict{VariableRef, Float64}, rhs::MOI.AbstractScalarSet, con_name::AbstractString, rhs_multiplier::Real=1.0)
    expr = AffExpr()
    for (var, coeff) in var_coeff_pairs
        add_to_expression!(expr, var, coeff)
    end
    new_con = @constraint(EP, expr in rhs; base_name=con_name)
    if rhs_multiplier != 1.0
        set_normalized_rhs(new_con, normalized_rhs(new_con) * rhs_multiplier)
    end
    name, indices = parse_name(con_name)
    if indices === nothing
        EP[Symbol(name)] = new_con
    else
        EP[Symbol(name)][indices...] = new_con
    end
    return new_con
end

function replace_constraint!(con_ref::ConstraintRef, var_coeff_pairs=nothing, rhs_multiplier::Real=1.0)
    con_obj = constraint_object(con_ref)
    con_name = name(con_ref)
    model = con_ref.model
    delete(model, con_ref)
    unregister(model, Symbol(con_name))
    if isnothing(var_coeff_pairs)
        _ = make_constraint(model, con_obj.func.terms, con_obj.set, con_name, rhs_multiplier)
    else
        _ = make_constraint(model, var_coeff_pairs, con_obj.set, con_name, rhs_multiplier)
    end
    return nothing
end

function scale_and_remake_constraint(con_ref::ConstraintRef, coeff_lb::Real, coeff_ub::Real, min_coeff::Real, rhs_ub::Real, proxy_var_map::Dict{VariableRef, VariableRef})
    var_coeff_pairs = constraint_object(con_ref).func.terms
    new_var_coeff_pairs = OrderedDict{VariableRef, Float64}()
    
    # First we want to check if we need to scale the RHS constant
    # We'd like to do this without making it impossible to scale some coefficients with proxy variables
    rhs = normalized_rhs(con_ref)
    if abs(rhs) > rhs_ub
        coefficients = abs.(append!(constraint_object(con_ref).func.terms.vals, rhs))
        coefficients = coefficients[coefficients .> 0] # Ignore coefficients which equal zero

        # We're only looking at large RHS, so we can just scale it down
        # That means we want to avoid any coefficients becoming less than coeff_lb / coeff_ub
        rhs_multiplier = maximum([1.0 / rhs, 1.0 / rhs_ub, coeff_lb / coeff_ub / minimum(coefficients)])
    else
        rhs_multiplier = 1.0
    end

    for (var, coeff) in var_coeff_pairs
        abs_coeff = abs(coeff) * rhs_multiplier
        if coeff == 0.0 || (coeff_lb <= abs_coeff <= coeff_ub)
            new_var_coeff_pairs[var] = coeff * rhs_multiplier
            continue
        elseif abs_coeff < coeff_lb
            multiplier = minimum([coeff_ub, 1.0 / abs_coeff]) # We could shift the target value (i.e. 1.0 here)
        elseif abs_coeff > coeff_ub
            multiplier = maximum([coeff_lb, 1.0 / abs_coeff])
        end

        new_coeff = coeff * rhs_multiplier * multiplier
        if abs(new_coeff) < min_coeff
            new_var_coeff_pairs[var] = 0.0
        else
            if new_coeff ≈ 1.0
                new_coeff = 1.0
                multiplier = new_coeff / coeff / rhs_multiplier
            elseif new_coeff ≈ -1.0
                new_coeff = -1.0
                multiplier = new_coeff / coeff / rhs_multiplier
            end
            model = var.model
            proxy_var = @variable(model)
            if has_lower_bound(var)
                set_lower_bound(proxy_var, lower_bound(var) * multiplier )
            end
            if has_upper_bound(var)
                set_upper_bound(proxy_var, upper_bound(var) * multiplier)
            end

            # println("Changing $(coeff) to $(new_coeff), multiplier was $(multiplier)")

            new_var_coeff_pairs[proxy_var] = new_coeff
            @constraint(model, var == proxy_var * multiplier)
        end
    end
    replace_constraint!(con_ref, new_var_coeff_pairs, rhs_multiplier)
end
    
function scale_constraint!(con_ref::ConstraintRef, coeff_range::Tuple{Float64, Float64}=(1e-3, 1e6), min_coeff::Float64=1e-9, rhs_ub::Float64=1e6)
    action_count = 0
    coeff_lb, coeff_ub = coeff_range
    con_obj = constraint_object(con_ref)
    coefficients = abs.(append!(con_obj.func.terms.vals, normalized_rhs(con_ref)))
    coefficients = coefficients[coefficients .> 0] # Ignore coefficients which equal zero

    if length(coefficients) == 0
        return action_count
    end

    # If all the coefficients are within the bounds, we don't need to do anything
    if all(coeff_lb .<= coefficients .<= coeff_ub)
        return action_count
    end

    # Find the ratio of the maximum and minimum coefficients to the bounds
    # A value > 1 for either indicates that the coefficients are too large or too small
    max_ratio = maximum(coefficients) / coeff_ub
    min_ratio = coeff_lb / minimum(coefficients)

    # If some coefficients are too large, and none too small
    # and dividing by max_ratio will not make any coefficients less than coeff_lb
    if max_ratio > 1 && min_ratio < 1 && min_ratio * max_ratio < 1
        for (key, val) in con_obj.func.terms
            set_normalized_coefficient(con_ref, key, val / max_ratio)
        end
        set_normalized_rhs(con_ref, normalized_rhs(con_ref) / max_ratio)
        action_count += 1
    # Else-if some coefficients are too small, and none too large
    # and multiplying by min_ratio will not make any coefficients greater than coeff_ub
    elseif min_ratio > 1 && max_ratio < 1 && max_ratio * min_ratio < 1
        for (key, val) in con_obj.func.terms
            set_normalized_coefficient(con_ref, key, val * min_ratio)
        end
        set_normalized_rhs(con_ref, normalized_rhs(con_ref) * min_ratio)
        action_count += 1
    # Else we'll recreate the constraint with proxy variables to scale the coefficients one-by-one
    else
        scale_and_remake_constraint(con_ref, coeff_lb, coeff_ub, min_coeff, rhs_ub, Dict{VariableRef, VariableRef}())
        action_count += 1
    end
    return action_count
end