"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
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

cd(dirname(@__FILE__))

### Set relevant directory paths
src_path = "../../src/"
### Load DOLPHYN
println("Loading packages")
push!(LOAD_PATH, src_path)

### Load packages
using YAML
using Pkg
using DOLPHYN

### Run this line to initialize the Julia virtual environment for DOLPHYN;
### Skip it, if the appropriate package versions are installed.
environment_path = "../../env.jl"
# include(environment_path)
println("Activating the Julia virtual environment")
Pkg.activate("DOLPHYNJulEnv")
Pkg.status()

## Store the path of the current working directory
root_path = pwd()
settings_path = joinpath(root_path, "Settings")
inputs_path = joinpath(root_path, "Inputs")

### Starters Settings
starters_settings_path = joinpath(settings_path, "Starters")
## Global settings for model
global_settings = joinpath(starters_settings_path, "global_model_settings.yml")
## Setup dictionary stores global settings
setup_global = YAML.load(open(global_settings))

### Sector Specific Settings
sectors_settings_path = joinpath(settings_path, "Sectors")
## Settings YAML file path for GenX of power sector
genx_settings = joinpath(sectors_settings_path, "genx_settings.yml")
## Settings YAML file path for HSC modelgrated model
hsc_settings = joinpath(sectors_settings_path, "hsc_settings.yml")
## Settings YAML file path for CSC modelgrated model
csc_settings = joinpath(sectors_settings_path, "csc_settings.yml")

## Setup dictionary stores GenX-specific parameters
setup_genx = YAML.load(open(genx_settings))
## Setup dictionary stores H2 supply chain-specific parameters
setup_hsc = YAML.load(open(hsc_settings))
## Setup dictionary stores CO2 supply chain-specific parameters
setup_csc = YAML.load(open(csc_settings))

## Merge dictionary - value of common keys will be overwritten by value in global_model_settings
setup = merge(setup_global, setup_genx, setup_hsc, setup_csc)

### Cluster time series inputs if necessary and if specified by the user
if setup["TimeDomainReduction"] == 1
    if (check_TDR_data(inputs_path, setup))
        println("Clustering Time Series Data...")
        cluster_inputs(inputs_path, settings_path, setup) #!this function needs more test and efforts.
    else
        println("Time Series Data Already Clustered.")
    end
end

### Configure solver
solver_settings_path = joinpath(settings_path, "Solvers")
OPTIMIZER = configure_solver(solver_settings_path, setup["Solver"])

### Running a case
### Load inputs
println("Loading Inputs")

## Load basic inputs and decide spatial and temporal details
inputs = load_basic_inputs(inputs_path, setup)

## Load GenX inputs
if setup["ModelPower"] == 1
    power_inputs_path = joinpath(inputs_path, "Power")
    inputs = load_power_inputs(power_inputs_path, setup, inputs)
end

## Load H2 inputs if modeling the hydrogen supply chain
if setup["ModelH2"] == 1
    h2_inputs_path = joinpath(inputs_path, "HSC")
    inputs = load_h2_inputs(h2_inputs_path, setup, inpath)
end

## Load CO2 inputs if modeling the carbon supply chain
if setup["ModelCO2"] == 1
    co2_inputs_path = joinpath(inputs_path, "CSC")
    inputs = load_co2_inputs(co2_inputs_path, setup, inpath)
end

### Generate model
println("Generating the Optimization Model")
EP = generate_model(setup, inputs, OPTIMIZER)

### Solve model
println("Solving Model")
EP, solve_time = solve_model(EP, setup)
inputs["solve_time"] = solve_time # Store the model solve time in inputs

### Writing output
println("Writing Output")
output_path = "$root_path/Results"
write_basic_outputs(EP, output_path, setup, inputs)

## Write power system output
outpath_Power = "$output_path/Results_Power"
write_power_outputs(EP, outpath_Power, setup, inputs)

## Write hydrogen supply chain outputs
if setup["ModelH2"] == 1
    outpath_H2 = "$output_path/Results_HSC"
    write_HSC_outputs(EP, outpath_H2, setup, inputs)
end

## Write carbon supply chain outputs
if setup["ModelCO2"] == 1
    outpath_CO2 = "$output_path/Results_CSC"
    write_CSC_outputs(EP, outpath_CO2, setup, inputs)
end

# ### Run MGA if the MGA flag is set to 1 else only save the least cost solution
# ### Only valid for power system analysis at this point
# if setup["ModelingToGenerateAlternatives"] == 1
#     println("Starting Model to Generate Alternatives (MGA) Iterations")
#     mga(EP, inpath, setup, inputs, outpath)
# end
