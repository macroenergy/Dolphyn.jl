@doc raw"""

"""
function write_duals(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    dfDuals = DataFrame(
        Constraint = ["ePowerBalance_$(i)" for i in eachindex(EP[:ePowerBalance])] ∪ 
                     ["eH2Balance_$(i)" for i in eachindex(EP[:eH2Balance])] ∪ 
                     ["eNGBalance_$(i)" for i in eachindex(EP[:eNGBalance])],
        Dual_Value = [-1 * dual(EP[:ePowerBalance][i]) for i in eachindex(EP[:ePowerBalance])] ∪
                     [-1 * dual(EP[:eH2Balance][i]) for i in eachindex(EP[:eH2Balance])] ∪
                     [-1 * dual(EP[:eNGBalance][i]) for i in eachindex(EP[:eNGBalance])]
    )
    

    if setup["ParameterScale"] == 1
        dfDuals.Dual_Value .*= ModelScalingFactor
    end

    CSV.write(joinpath(path, "Dual_Values.csv"), dfDuals)
end
