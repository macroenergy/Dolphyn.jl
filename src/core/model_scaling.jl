function scale_constraints!(EP::Model, coeff_range::Tuple{Float64, Float64}=(1e-3, 1e6), min_coeff::Float64=1e-6; count_actions::Bool=false)
    con_list = all_constraints(EP; include_variable_in_set_constraints=false)
    action_count = scale_constraint!.(con_list, Ref(coeff_range), Ref(min_coeff));
    if count_actions
        return sum(action_count)
    else
        return nothing
    end
end

function scale_constraints!(constraint_list::Vector{ConstraintRef}, coeff_range::Tuple{Float64, Float64}=(1e-3, 1e6), min_coeff::Float64=1e-6; count_actions::Bool=false)
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
    
function scale_constraint!(con_ref::ConstraintRef, coeff_range::Tuple{Float64, Float64}=(1e-3, 1e6), min_coeff::Float64=1e-6)
    action_count = 0
    coeff_lb, coeff_ub = coeff_range
    con_obj = constraint_object(con_ref)
    coefficients = abs.(append!(con_obj.func.terms.vals, normalized_rhs(con_ref)))
    coefficients[coefficients .< min_coeff] .= 0 # Set any coefficients less than min_coeff
    coefficients = coefficients[coefficients .> 0] # Ignore constraints which equal zero
    if length(coefficients) == 0
        return action_count
    end
    max_ratio = maximum(coefficients) / coeff_ub
    min_ratio = coeff_lb / minimum(coefficients)
    if max_ratio > 1 && min_ratio < 1
        if min_ratio / max_ratio < 1
            for (key, val) in con_obj.func.terms
                set_normalized_coefficient(con_ref, key, val / max_ratio)
            end
            set_normalized_rhs(con_ref, normalized_rhs(con_ref) / max_ratio)
            action_count += 1
        end
    elseif min_ratio > 1 && max_ratio < 1
        if max_ratio * min_ratio < 1
            for (key, val) in con_obj.func.terms
                set_normalized_coefficient(con_ref, key, val * min_ratio)
            end
            set_normalized_rhs(con_ref, normalized_rhs(con_ref) * min_ratio)
            action_count += 1
        end
    end
    return action_count
end