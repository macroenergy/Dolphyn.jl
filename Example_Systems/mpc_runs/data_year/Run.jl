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


using GenX
using JuMP
using CSV, DataFrames

# Walk into current directory
case_dir = @__DIR__

settings_path = joinpath(case_dir, "Settings")
inputs_path = case_dir

# Loading settings
genx_settings = joinpath(settings_path, "genx_settings.yml") #Settings YAML file path for GenX
mysetup_genx = configure_settings(genx_settings) # mysetup dictionary stores GenX-specific parameters


mysetup = Dict()
mysetup = merge(mysetup_genx) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings
mysetup = configure_settings(mysetup)

# Start logging
global Log = mysetup["Log"]

if Log
    logger = FileLogger(mysetup["LogFile"])
    global_logger(logger)
end

### Load DOLPHYN
println("Loading packages")
# push!(LOAD_PATH, src_path)


# ### Configure solver
print_and_log("Configuring Solver")
OPTIMIZER = configure_solver(mysetup["Solver"], settings_path)

# #### Running a case

# ### Load inputs
# print_and_log("Loading Inputs")
 myinputs = Dict() # myinputs dictionary will store read-in data and computed parameters
 myinputs = load_inputs(mysetup, inputs_path)


# ### Generate model
# print_and_log("Generating the Optimization Model")
EP = generate_model(mysetup, myinputs, OPTIMIZER)

### Solve model
print_and_log("Solving Model")
EP, solve_time = solve_model(EP, mysetup)
myinputs["solve_time"] = solve_time # Store the model solve time in myinputs

### Write power system output

print_and_log("Writing Output")
outpath = joinpath(inputs_path,"Results")
outpath_GenX = write_outputs(EP, outpath, mysetup, myinputs)


