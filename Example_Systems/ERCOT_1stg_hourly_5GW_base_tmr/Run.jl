"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published bypw
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
using YAML

# The directory containing your input data
inputs_path = @__DIR__

@info("PACKAGE LOADED")

# The directory containing your settings folder and files
settings_path = joinpath(@__DIR__, "Settings")

# Load settings
mysetup = load_settings(settings_path)

# Setup time domain reduction and cluster inputs if necessary
setup_TDR(inputs_path, settings_path, mysetup)

# ### Configure solver
println("Configuring Solver")
OPTIMIZER = configure_solver(mysetup["Solver"], settings_path, Gurobi.Optimizer)

# #### Running a case

# ### Load inputs
# println("Loading Inputs")
myinputs = load_inputs(mysetup, inputs_path)

# ### Load H2 inputs if modeling the hydrogen supply chain
if mysetup["ModelH2"] == 1
    myinputs = load_h2_inputs(myinputs, mysetup, inputs_path)
end

# ### Generate model
# println("Generating the Optimization Model")
EP = generate_model(mysetup, myinputs, OPTIMIZER)

### Solve model
println("Solving Model")
EP, solve_time = solve_model(EP, mysetup)
myinputs["solve_time"] = solve_time # Store the model solve time in myinputs

### Write power system output

println("Writing Output")
outpath = joinpath(inputs_path,"Results")
outpath=write_outputs(EP, outpath, mysetup, myinputs)

# Write hydrogen supply chain outputs
if mysetup["ModelH2"] == 1
    outpath_H2 = "$outpath/Results_HSC"
    write_HSC_outputs(EP, outpath_H2, mysetup, myinputs)
end

# Run MGA if the MGA flag is set to 1 else only save the least cost solution
# Only valid for power system analysis at this point
if mysetup["ModelingToGenerateAlternatives"] == 1
    println("Starting Model to Generate Alternatives (MGA) Iterations")
    mga(EP,inputs_path,mysetup,myinputs,outpath)
end