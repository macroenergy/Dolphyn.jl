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

# Walk into current directory
cd(dirname(@__FILE__))

# Loading settings
using YAML

settings_path = joinpath(pwd(), "Settings")

genx_settings = joinpath(settings_path, "genx_settings.yml") #Settings YAML file path for GenX
hsc_settings = joinpath(settings_path, "hsc_settings.yml") #Settings YAML file path for HSC modelgrated model
mysetup_genx = YAML.load(open(genx_settings)) # mysetup dictionary stores GenX-specific parameters
mysetup_hsc = YAML.load(open(hsc_settings)) # mysetup dictionary stores H2 supply chain-specific parameters
global_settings = joinpath(settings_path, "global_model_settings.yml") # Global settings for inte
mysetup_global = YAML.load(open(global_settings)) # mysetup dictionary stores global settings
mysetup = Dict()
mysetup = merge(mysetup_hsc, mysetup_genx, mysetup_global) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings

# Start logging
using LoggingExtras

global Log = mysetup["Log"]

if Log
    logger = FileLogger(mysetup["LogFile"])
    global_logger(logger)
end

# Activate environment
environment_path = "../../../package_activate.jl"
if !occursin("DOLPHYNJulEnv", Base.active_project())
    include(environment_path) #Run this line to activate the Julia virtual environment for GenX; skip it, if the appropriate package versions are installed
end

### Set relevant directory paths
src_path = "../../../src/"

inpath = pwd()

### Load DOLPHYN
println("Loading packages")
push!(LOAD_PATH, src_path)

using DOLPHYN

outpath = joinpath(inpath, "Results")

summary_path = joinpath(inpath, "summary.txt")
example_path = joinpath(inpath, "Results_Example")
println("Comparing $(example_path) and $(outpath)")
println("Writing summary to $(summary_path)")
compare_results(example_path, outpath, summary_path)