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

module DOLPHYN

#export package_activate
export compare_results
export print_and_log
export configure_settings
export configure_solver
export load_inputs
export load_h2_inputs
export generate_model
export solve_model
export write_outputs
export write_HSC_outputs
export cluster_inputs
export mga
export h2_inherit_clusters

using JuMP # used for mathematical programming
using DataFrames #This package allows put together data into a matrix
using MathProgBase #for fix_integers
using CSV
using StatsBase
using LinearAlgebra
using YAML
using Dates
using Clustering
using Distances
using Combinatorics
using Documenter
using Revise
using Glob
using LoggingExtras

using Random
using RecursiveArrayTools
using Statistics

# Uncomment if Gurobi or CPLEX active license and installations are there and the user intends to use either of them
using Gurobi
using HiGHS

using Clp
using Cbc

# Global scaling factor used when ParameterScale is on to shift values from MW to GW
# DO NOT CHANGE THIS (Unless you do so very carefully)
# To translate MW to GW, divide by ModelScalingFactor
# To translate $ to $M, multiply by ModelScalingFactor^2
# To translate $/MWh to $M/GWh, multiply by ModelScalingFactor
const ModelScalingFactor = 1e+3

# Lower heating value of Hydrogen
# LHV is used when defining a system-wide CO2 constraint for the joint hydrogen and electricity infrastructures (SystemCO2Constraint =2)
const H2_LHV = 33.33 # MWh per tonne

# Logging flag
Log = true

# Load GenX
function find_all_to_include(dir::String, file_type::String=".jl", recursive::Bool=false)::Vector{String}
    if recursive
        result = String[]
        for (root, dirs, files) in walkdir(dir)
            append!(result, filter!(f -> occursin(file_type, f), joinpath.(root, files)))
        end
        return result
    else
        search_string = "*$(file_type)"
        return glob(search_string, dir)
    end
end

# We can't easily run GenX.jl because that creates a module
# which doesn't export all the functions we need.
# Instead, we'll include all the GenX functions and then overwrite them
genxsubmod_path = joinpath(@__DIR__,"GenX", "src")
files_to_exclude = [
    joinpath(genxsubmod_path,"GenX.jl"),
    joinpath(genxsubmod_path,"simple_operation.jl"),
    joinpath(genxsubmod_path,"time_domain_reduction","time_domain_reduction.jl"),
    joinpath(genxsubmod_path,"model","solve_model.jl"),
    joinpath(genxsubmod_path,"model","generate_model.jl"),
]
dirs_to_exclude = [
    joinpath(genxsubmod_path,"configure_solver"),
    # joinpath(genxsubmod_path,"configure_settings") # DOLPHYN and GenX are using different approaches, so we need both
]
for dir in dirs_to_exclude
    push!(files_to_exclude, find_all_to_include(dir, ".jl", true)...)
end
# Print a list of files that are not being included from GenX
if length(files_to_exclude) > 0
    println(" --- The following files are not being included from GenX: --- ")
    for file in files_to_exclude
        println("Excluding $file")
    end
    println(" --- End of excluded files --- ")
end
# Get all .jl files in the GenX submodule directory
genx_module_files = find_all_to_include(genxsubmod_path, ".jl", true)
# Filter out all the files we want to exclude
filter!(x -> !(x in files_to_exclude), genx_module_files)
for file in genx_module_files
    include(file)
end

# Load time domain reduction related scripts
tdr_files = find_all_to_include(joinpath(@__DIR__,"time_domain_reduction"), ".jl", true)
for file in tdr_files
    include(file)
end

# Extensions to GenX
genx_ext_files = find_all_to_include(joinpath(@__DIR__,"GenX_extensions"), ".jl", true)
for file in genx_ext_files
    include(file)
end

# Load all .jl files from the HSC directory
HSC_files = find_all_to_include(joinpath(@__DIR__,"HSC"), ".jl", true)
for file in HSC_files
    include(file)
end

# Load all .jl files from the core directory
core_files = find_all_to_include(joinpath(@__DIR__,"core"), ".jl", true)
for file in core_files
    include(file)
end

# Configure settings
settings_files = find_all_to_include(joinpath(@__DIR__,"configure_settings"), ".jl", true)
for file in settings_files
    include(file)
end

# Configure optimizer instance
solver_files = find_all_to_include(joinpath(@__DIR__,"configure_solver"), ".jl", true)
for file in solver_files
    include(file)
end

# Files which involve multiple sectors
multisector_files = find_all_to_include(joinpath(@__DIR__,"multisector"), ".jl", true)
for file in multisector_files
    include(file)
end

# Load model generation and solving scripts
include("generate_model.jl")
include("solve_model.jl")

end
