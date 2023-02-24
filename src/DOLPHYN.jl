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
# We can't easily run GenX.jl because that creates a module
# which doesn't export all the functions we need.
# Instead, we'll include all the GenX functions and then overwrite them
genxsubmod_path = joinpath("GenX", "src")

# Case runner
include("$(genxsubmod_path)/case_runners/case_runner.jl")

# Configure settings
include("$(genxsubmod_path)/configure_settings/configure_settings.jl")

# Configure optimizer instance
include("$(genxsubmod_path)/configure_solver/configure_highs.jl")
include("$(genxsubmod_path)/configure_solver/configure_gurobi.jl")
include("$(genxsubmod_path)/configure_solver/configure_scip.jl")
include("$(genxsubmod_path)/configure_solver/configure_cplex.jl")
include("$(genxsubmod_path)/configure_solver/configure_clp.jl")
include("$(genxsubmod_path)/configure_solver/configure_cbc.jl")
include("$(genxsubmod_path)/configure_solver/configure_solver.jl")

# Load input data
include("$(genxsubmod_path)/load_inputs/load_generators_data.jl")
include("$(genxsubmod_path)/load_inputs/load_generators_variability.jl")
include("$(genxsubmod_path)/load_inputs/load_network_data.jl")
include("$(genxsubmod_path)/load_inputs/load_reserves.jl")
include("$(genxsubmod_path)/load_inputs/load_cap_reserve_margin.jl")
include("$(genxsubmod_path)/load_inputs/load_energy_share_requirement.jl")
include("$(genxsubmod_path)/load_inputs/load_co2_cap.jl")
include("$(genxsubmod_path)/load_inputs/load_period_map.jl")
include("$(genxsubmod_path)/load_inputs/load_minimum_capacity_requirement.jl")
include("$(genxsubmod_path)/load_inputs/load_load_data.jl")
include("$(genxsubmod_path)/load_inputs/load_fuels_data.jl")
include("$(genxsubmod_path)/load_inputs/load_inputs.jl")

include("$(genxsubmod_path)/time_domain_reduction/time_domain_reduction.jl")

# Core GenX Features
include("$(genxsubmod_path)/model/core/discharge/discharge.jl")
include("$(genxsubmod_path)/model/core/discharge/investment_discharge.jl")

include("$(genxsubmod_path)/model/core/non_served_energy.jl")
include("$(genxsubmod_path)/model/core/ucommit.jl")
include("$(genxsubmod_path)/model/core/emissions.jl")

include("$(genxsubmod_path)/model/core/reserves.jl")

include("$(genxsubmod_path)/model/core/transmission.jl")

include("$(genxsubmod_path)/model/resources/curtailable_variable_renewable/curtailable_variable_renewable.jl")

include("$(genxsubmod_path)/model/resources/flexible_demand/flexible_demand.jl")

include("$(genxsubmod_path)/model/resources/hydro/hydro_res.jl")
include("$(genxsubmod_path)/model/resources/hydro/hydro_inter_period_linkage.jl")

include("$(genxsubmod_path)/model/resources/must_run/must_run.jl")

include("$(genxsubmod_path)/model/resources/storage/storage.jl")
include("$(genxsubmod_path)/model/resources/storage/investment_energy.jl")
include("$(genxsubmod_path)/model/resources/storage/storage_all.jl")
include("$(genxsubmod_path)/model/resources/storage/long_duration_storage.jl")
include("$(genxsubmod_path)/model/resources/storage/investment_charge.jl")
include("$(genxsubmod_path)/model/resources/storage/storage_asymmetric.jl")
include("$(genxsubmod_path)/model/resources/storage/storage_symmetric.jl")

include("$(genxsubmod_path)/model/resources/thermal/thermal.jl")
include("$(genxsubmod_path)/model/resources/thermal/thermal_commit.jl")
include("$(genxsubmod_path)/model/resources/thermal/thermal_no_commit.jl")

include("$(genxsubmod_path)/model/resources/retrofits/retrofits.jl")

include("$(genxsubmod_path)/model/policies/co2_cap.jl")
include("$(genxsubmod_path)/model/policies/energy_share_requirement.jl")
include("$(genxsubmod_path)/model/policies/cap_reserve_margin.jl")
include("$(genxsubmod_path)/model/policies/minimum_capacity_requirement.jl")

# include("$(genxsubmod_path)/model/generate_model.jl")
# include("$(genxsubmod_path)/model/solve_model.jl")

include("$(genxsubmod_path)/write_outputs/dftranspose.jl")
include("$(genxsubmod_path)/write_outputs/write_capacity.jl")
include("$(genxsubmod_path)/write_outputs/write_capacityfactor.jl")
include("$(genxsubmod_path)/write_outputs/write_charge.jl")
include("$(genxsubmod_path)/write_outputs/write_charging_cost.jl")
include("$(genxsubmod_path)/write_outputs/write_costs.jl")
include("$(genxsubmod_path)/write_outputs/write_curtailment.jl")
include("$(genxsubmod_path)/write_outputs/write_emissions.jl")
include("$(genxsubmod_path)/write_outputs/write_energy_revenue.jl")
include("$(genxsubmod_path)/write_outputs/write_net_revenue.jl")
include("$(genxsubmod_path)/write_outputs/write_nse.jl")
include("$(genxsubmod_path)/write_outputs/write_power.jl")
include("$(genxsubmod_path)/write_outputs/write_power_balance.jl")
include("$(genxsubmod_path)/write_outputs/write_price.jl")
include("$(genxsubmod_path)/write_outputs/write_reliability.jl")
include("$(genxsubmod_path)/write_outputs/write_status.jl")
include("$(genxsubmod_path)/write_outputs/write_storage.jl")
include("$(genxsubmod_path)/write_outputs/write_storagedual.jl")
include("$(genxsubmod_path)/write_outputs/write_subsidy_revenue.jl")
include("$(genxsubmod_path)/write_outputs/write_time_weights.jl")
include("$(genxsubmod_path)/write_outputs/choose_output_dir.jl")

include("$(genxsubmod_path)/write_outputs/capacity_reserve_margin/write_capacity_value.jl")
include("$(genxsubmod_path)/write_outputs/capacity_reserve_margin/write_reserve_margin_revenue.jl")
include("$(genxsubmod_path)/write_outputs/capacity_reserve_margin/write_reserve_margin_w.jl")
include("$(genxsubmod_path)/write_outputs/capacity_reserve_margin/write_reserve_margin.jl")

include("$(genxsubmod_path)/write_outputs/energy_share_requirement/write_esr_prices.jl")
include("$(genxsubmod_path)/write_outputs/energy_share_requirement/write_esr_revenue.jl")

include("$(genxsubmod_path)/write_outputs/long_duration_storage/write_opwrap_lds_dstor.jl")
include("$(genxsubmod_path)/write_outputs/long_duration_storage/write_opwrap_lds_stor_init.jl")

include("$(genxsubmod_path)/write_outputs/reserves/write_reg.jl")
include("$(genxsubmod_path)/write_outputs/reserves/write_rsv.jl")

include("$(genxsubmod_path)/write_outputs/transmission/write_nw_expansion.jl")
include("$(genxsubmod_path)/write_outputs/transmission/write_transmission_flows.jl")
include("$(genxsubmod_path)/write_outputs/transmission/write_transmission_losses.jl")

include("$(genxsubmod_path)/write_outputs/ucommit/write_commit.jl")
include("$(genxsubmod_path)/write_outputs/ucommit/write_shutdown.jl")
include("$(genxsubmod_path)/write_outputs/ucommit/write_start.jl")

include("$(genxsubmod_path)/write_outputs/write_outputs.jl")

#Just for unit testing; Under active development
include("$(genxsubmod_path)/simple_operation.jl")

# Multi Stage files
include("$(genxsubmod_path)/multi_stage/write_multi_stage_settings.jl")
include("$(genxsubmod_path)/multi_stage/write_multi_stage_capacities_discharge.jl")
include("$(genxsubmod_path)/multi_stage/write_multi_stage_capacities_charge.jl")
include("$(genxsubmod_path)/multi_stage/write_multi_stage_capacities_energy.jl")
include("$(genxsubmod_path)/multi_stage/write_multi_stage_network_expansion.jl")
include("$(genxsubmod_path)/multi_stage/write_multi_stage_costs.jl")
include("$(genxsubmod_path)/multi_stage/write_multi_stage_stats.jl")
include("$(genxsubmod_path)/multi_stage/dual_dynamic_programming.jl")
include("$(genxsubmod_path)/multi_stage/configure_multi_stage_inputs.jl")
include("$(genxsubmod_path)/multi_stage/endogenous_retirement.jl")

include("$(genxsubmod_path)/additional_tools/modeling_to_generate_alternatives.jl")
include("$(genxsubmod_path)/additional_tools/method_of_morris.jl")

# Load time domain reduction related scripts
# include("time_domain_reduction/time_domain_reduction.jl")

# Extensions to GenX
# These should be pushed to the GenX fork
include("write_nw_expansion.jl")

#Load input data - HSC
include("HSC/load_inputs/load_h2_gen.jl")
include("HSC/load_inputs/load_h2_demand.jl")
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


end
