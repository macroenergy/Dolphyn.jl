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

OPTIMIZER = configure_solver(mysetup["Solver"], settings_path)

# #### Running a case

# ### Load inputs
myinputs = load_all_inputs(mysetup, inputs_path)

# ### Generate model
# print_and_log("Generating the Optimization Model")
EP = generate_model(mysetup, myinputs, OPTIMIZER)

### Solve model
print_and_log("Solving Model")
EP, solve_time = solve_model(EP, mysetup)
myinputs["solve_time"] = solve_time # Store the model solve time in myinputs

### Write power system output

print_and_log("Writing Output")
write_all_outputs(EP, mysetup, myinputs, inputs_path)
