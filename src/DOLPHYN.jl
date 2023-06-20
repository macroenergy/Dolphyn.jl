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
# using Gurobi
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
    joinpath(genxsubmod_path,"simplt_operation.jl"),
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
for file in files_to_exclude
    println("Excluding $file")
end
genx_module_files = find_all_to_include(genxsubmod_path, ".jl", true)
filter!(x -> !(x in files_to_exclude), genx_module_files)
for file in genx_module_files
    # println("Including $file")
    include(file)
end

# Load time domain reduction related scripts
include("time_domain_reduction/time_domain_reduction.jl")

# Extensions to GenX
# These should be pushed to the GenX fork
include("write_nw_expansion.jl")

#Load input data - HSC
include("HSC/load_inputs/load_h2_gen.jl")
include("HSC/load_inputs/load_h2_demand.jl")
include("HSC/load_inputs/load_h2_demand_liquid.jl")
include("HSC/load_inputs/load_h2_generators_variability.jl")
include("HSC/load_inputs/load_h2_pipeline_data.jl")
include("HSC/load_inputs/load_h2_truck.jl")
include("HSC/load_inputs/load_H2_inputs.jl")
include("HSC/load_inputs/load_co2_cap_hsc.jl")
include("HSC/load_inputs/load_h2_g2p.jl")
include("HSC/load_inputs/load_h2_g2p_variability.jl")

# Inherit clusters from GenX
include("h2_inherit_clusters.jl")

# Auxiliary logging function
include("print_and_log.jl")

# Results comparison tools
include("compare_results.jl")

# Enumerate zones
include("enumerate_zones.jl")

# Select zones
include("select_zones.jl")

# Configure settings
include("configure_settings/configure_settings.jl")

# Configure optimizer instance
include("configure_solver/configure_gurobi.jl")
include("configure_solver/configure_highs.jl")
include("configure_solver/configure_cplex.jl")
include("configure_solver/configure_clp.jl")
include("configure_solver/configure_cbc.jl")
include("configure_solver/configure_solver.jl")

#Core HSC Modelling Features
include("HSC/model/core/h2_investment.jl")
include("HSC/model/core/h2_outputs.jl")
include("HSC/model/core/h2_non_served.jl")

include("HSC/model/flexible_demand/h2_flexible_demand.jl")
include("HSC/model/core/emissions_hsc.jl")

# H2 production
include("HSC/model/generation/h2_production_commit.jl")
include("HSC/model/generation/h2_production_no_commit.jl")
include("HSC/model/generation/h2_production_all.jl")
include("HSC/model/generation/h2_production.jl")

# H2 pipelines
include("HSC/model/transmission/h2_pipeline.jl")

# H2 trucks
include("HSC/model/truck/h2_truck_investment.jl")
include("HSC/model/truck/h2_truck.jl")
include("HSC/model/truck/h2_truck_all.jl")
include("HSC/model/truck/h2_long_duration_truck.jl")

# H2 storage
include("HSC/model/storage/h2_storage_investment_energy.jl")
include("HSC/model/storage/h2_storage_investment_charge.jl")
include("HSC/model/storage/h2_storage.jl")
include("HSC/model/storage/h2_storage_all.jl")
include("HSC/model/storage/h2_long_duration_storage.jl")

# H2 G2P
include("HSC/model/g2p/h2_g2p_investment.jl")
include("HSC/model/g2p/h2_g2p_discharge.jl")
include("HSC/model/g2p/h2_g2p_all.jl")
include("HSC/model/g2p/h2_g2p_commit.jl")
include("HSC/model/g2p/h2_g2p_no_commit.jl")
include("HSC/model/g2p/h2_g2p.jl")

# Policies
include("HSC/model/policies/co2_cap_hsc.jl")

# Load model generation and solving scripts
include("co2_cap_power_hsc.jl")
include("generate_model.jl")
include("solve_model.jl")

# HSC Write Outputs
include("HSC/write_outputs/write_h2_gen.jl")
include("HSC/write_outputs/write_h2_capacity.jl")
include("HSC/write_outputs/write_h2_nse.jl")
include("HSC/write_outputs/write_h2_costs.jl")
include("HSC/write_outputs/write_h2_balance.jl")
include("HSC/write_outputs/write_h2_pipeline_flow.jl")
include("HSC/write_outputs/write_h2_pipeline_expansion.jl")
include("HSC/write_outputs/write_h2_pipeline_level.jl")
include("HSC/write_outputs/write_h2_emissions.jl")
include("HSC/write_outputs/write_h2_charge.jl")
include("HSC/write_outputs/write_h2_storage.jl")
include("HSC/write_outputs/write_h2_truck_capacity.jl")
include("HSC/write_outputs/write_h2_truck_flow.jl")
include("HSC/write_outputs/write_h2_transmission_flow.jl")
include("HSC/write_outputs/write_HSC_outputs.jl")
include("HSC/write_outputs/write_p_g2p.jl")
include("HSC/write_outputs/write_h2_g2p.jl")
include("HSC/write_outputs/write_g2p_capacity.jl")
include("HSC/write_outputs/choose_h2_output_dir.jl")

include("HSC/write_outputs/write_h2_elec_costs.jl")

end
