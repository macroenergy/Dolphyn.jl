"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

using Dolphyn
using Gurobi
using JuMP
using YAML

# The directory containing your settings folder and files
settings_path = joinpath(@__DIR__, "Settings")

# The directory containing your input data
inputs_path = @__DIR__

# Load settings
mysetup = load_settings(settings_path)

# Setup logging 
global_logger = setup_logging(mysetup)

### Load DOLPHYN
println("Loading packages")
# push!(LOAD_PATH, src_path)

# Setup time domain reduction and cluster inputs if necessary
setup_TDR(inputs_path, settings_path, mysetup)

# ### Configure solver
print_and_log("Configuring Solver")
print(mysetup["Solver"])

OPTIMIZER = configure_solver(mysetup["Solver"], settings_path, Gurobi.Optimizer)
# #### Running a case

# ### Load inputs
# print_and_log("Loading Inputs")
 myinputs = load_inputs(mysetup, inputs_path)


# ### Load H2 inputs if modeling the hydrogen supply chain
if mysetup["ModelH2"] == 1
    myinputs = load_h2_inputs(myinputs, mysetup, inputs_path)
end

# ### Generate model
# print_and_log("Generating the Optimization Model")
EP = generate_model(mysetup, myinputs, OPTIMIZER)

function scale_constraints!(EP::Model, max_coeff::Float64=1e6, min_coeff::Float64=1e-3)
    con_list = all_constraints(EP; include_variable_in_set_constraints=false)
    scale_constraints!(con_list, max_coeff, min_coeff)
end
function scale_constraints!(constraint_list::Vector{ConstraintRef}, max_coeff::Float64=1e6, min_coeff::Float64=1e-3)
    action_count = 0
    for con_ref in constraint_list
        con_obj = constraint_object(con_ref)
        coefficients = abs.(append!(con_obj.func.terms.vals, normalized_rhs(con_ref)))
        # coefficients[coefficients .< min_coeff / 100] .= 0 # Set any coefficients less than min_coeff / 100 to zero
        coefficients = coefficients[coefficients .> 0] # Ignore constraints which equal zero
        if length(coefficients) == 0
            continue
        end
        max_ratio = maximum(coefficients) / max_coeff
        min_ratio = min_coeff / minimum(coefficients)
        if con_ref ==constraint_by_name(EP,"cESRSharePerPeriod[1,1]")
        println("max_ratio: ", max_ratio)
        println("min_ratio: ", min_ratio)
        println("max_coeff: ", max_coeff)
        println("min_coeff: ", min_coeff)
        println("max to min ratio", min_ratio / max_ratio)
        end
        if max_ratio > 1 && min_ratio < 1
            if min_ratio / max_ratio < 1
                for (key, val) in con_obj.func.terms
                    set_normalized_coefficient(con_ref, key, val / max_ratio)
                end
                set_normalized_rhs(con_ref, normalized_rhs(con_ref) / max_ratio)
                if con_ref ==constraint_by_name(EP,"cESRSharePerPeriod[1,1]")
                    println(normalized_rhs(con_ref) )
                end
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
        # if con_ref ==constraint_by_name(EP,"cESRSharePerPeriod[1,1]")
        #     println(con_ref)
        # end
    end
    return action_count
end
scale_constraints!(EP)




### Solve model
print_and_log("Solving Model")
EP, solve_time = solve_model(EP, mysetup)
myinputs["solve_time"] = solve_time # Store the model solve time in myinputs

### Write power system output

print_and_log("Writing Output")
outpath = joinpath(inputs_path,"Results")
outpath_GenX = write_outputs(EP, outpath, mysetup, myinputs)

# Write hydrogen supply chain outputs
# outpath_H2 = joinpath(outpath_GenX,"Results_HSC")
if mysetup["ModelH2"] == 1
    write_HSC_outputs(EP, outpath_GenX, mysetup, myinputs)
end
