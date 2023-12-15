"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2023,  Massachusetts Institute of Technology
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

##TO ADD SYNFUEL SETTING IMPORT

# Setup time domain reduction and cluster inputs if necessary
setup_TDR(inputs_path, settings_path, mysetup)

# ### Configure solver
print_and_log("Configuring Solver")

OPTIMIZER = configure_solver(mysetup["Solver"], settings_path)

# #### Running a case

# ### Load inputs
myinputs = Dict() # myinputs dictionary will store read-in data and computed parameters
myinputs = load_inputs(mysetup, inputs_path)

# ### Load H2 inputs if modeling the hydrogen supply chain
if mysetup["ModelH2"] == 1
    myinputs = load_h2_inputs(myinputs, mysetup, inputs_path)
end

# ### Load CO2 inputs if modeling the carbon supply chain
if mysetup["ModelCSC"] == 1
    myinputs = load_co2_inputs(myinputs, mysetup, inputs_path)
end

### Load LF inputs if modeling the synthetic fuels supply chain
if mysetup["ModelLiquidFuels"] == 1
    myinputs = load_liquid_fuels_inputs(myinputs, mysetup, inputs_path)
end

### Load BESC inputs if modeling the bioenergy fuels supply chain
if mysetup["ModelBESC"] == 1
    myinputs = load_bio_inputs(myinputs, mysetup, inputs_path)
end

# ### Generate model
EP = generate_model(mysetup, myinputs, OPTIMIZER)

### Solve model
print_and_log("Solving Model")  
EP, solve_time = solve_model(EP, mysetup)
myinputs["solve_time"] = solve_time # Store the model solve time in myinputs

### Write power system output

print_and_log("Writing Output")
outpath = joinpath(inputs_path,"Results")
outpath_GenX=write_outputs(EP, outpath, mysetup, myinputs)

# Write hydrogen supply chain outputs
if mysetup["ModelH2"] == 1
    write_HSC_outputs(EP, outpath_GenX, mysetup, myinputs)
end

# Write carbon supply chain outputs
if mysetup["ModelCSC"] == 1
    write_CSC_outputs(EP, outpath_GenX, mysetup, myinputs)
end

# Write liquid fuels supply chain outputs
if mysetup["ModelLiquidFuels"] == 1
    write_liquid_fuels_outputs(EP, outpath_GenX, mysetup, myinputs)
end

# Write bioenergy fuels supply chain outputs
if mysetup["ModelBESC"] == 1
    write_bio_outputs(EP, outpath_GenX, mysetup, myinputs)
end

compare_results(outpath_GenX, joinpath(inputs_path, "Results_Example"))


