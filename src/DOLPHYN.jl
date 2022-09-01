"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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

module DOLPHYN

export check_TDR_data
export cluster_inputs
export configure_settings
export configure_solver
export load_basic_inputs
export load_power_inputs
export load_h2_inputs
export load_co2_inputs
export generate_model
export solve_model
export write_basic_outputs
export write_power_outputs
export write_HSC_outputs
export write_CSC_outputs
export mga


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
using Gurobi

using Clp
using Cbc

# Global scaling factor used when ParameterScale is on to shift values from MW to GW
# DO NOT CHANGE THIS (Unless you do so very carefully)
# To translate MW to GW, divide by ModelScalingFactor
# To translate $ to $M, multiply by ModelScalingFactor^2
# To translate $/MWh to $M/GWh, multiply by ModelScalingFactor
ModelScalingFactor = 1e+3

# Lower heating value of Hydrogen
# LHV is used when defining a system-wide CO2 constraint for the joint hydrogen and electricity infrastructures (SystemCO2Constraint =2)
H2_LHV = 33.33 # MWh per tonne

# Configure settings
include("configure_settings/configure_settings.jl")

# Configure optimizer instance
include("configure_solver/configure_gurobi.jl")
include("configure_solver/configure_cplex.jl")
include("configure_solver/configure_clp.jl")
include("configure_solver/configure_cbc.jl")
include("configure_solver/configure_solver.jl")

# Load global input data
include("load_inputs/load_spatial_details.jl")
include("load_inputs/load_temporal_details.jl")
include("load_inputs/load_fuels_data.jl")

include("load_inputs/load_Basic_inputs.jl")

# Load input data - GenX
include("GenX/load_inputs/load_generators_data.jl")
include("GenX/load_inputs/load_generators_variability.jl")
include("GenX/load_inputs/load_network_data.jl")
include("GenX/load_inputs/load_reserves.jl")
include("GenX/load_inputs/load_cap_reserve_margin.jl")
include("GenX/load_inputs/load_energy_share_requirement.jl")
include("GenX/load_inputs/load_co2_cap.jl")
include("GenX/load_inputs/load_minimum_capacity_requirement.jl")
include("GenX/load_inputs/load_load_data.jl")
include("GenX/load_inputs/load_Power_inputs.jl")

# Load time domain reduction related scripts
include("time_domain_reduction/check_TDR_data.jl")
include("time_domain_reduction/time_domain_reduction.jl")
# include("time_domain_reduction/PreCluster.jl")

# Load input data - HSC
include("HSC/load_inputs/load_h2_gen.jl")
include("HSC/load_inputs/load_h2_demand.jl")
include("HSC/load_inputs/load_h2_generators_variability.jl")
include("HSC/load_inputs/load_h2_pipeline.jl")
include("HSC/load_inputs/load_h2_truck.jl")
include("HSC/load_inputs/load_co2_cap_hsc.jl")
include("HSC/load_inputs/load_h2_g2p.jl")
include("HSC/load_inputs/load_h2_g2p_variability.jl")

include("HSC/load_inputs/load_H2_inputs.jl")

# Load input data - CSC
include("CSC/load_inputs/load_co2_demand.jl")
include("CSC/load_inputs/load_co2_capture.jl")
include("CSC/load_inputs/load_co2_capture_variability.jl")
include("CSC/load_inputs/load_co2_price_csc.jl")
include("CSC/load_inputs/load_co2_storage.jl")
include("CSC/load_inputs/load_co2_pipeline.jl")
include("CSC/load_inputs/load_co2_truck.jl")

include("CSC/load_inputs/load_CO2_inputs.jl")

# Core GenX features
include("GenX/model/core/discharge/discharge.jl")
include("GenX/model/core/discharge/investment_discharge.jl")
include("GenX/model/core/non_served_energy.jl")
include("GenX/model/core/ucommit.jl")
include("GenX/model/core/reserves.jl")
include("GenX/model/core/transmission.jl")
include("GenX/model/core/emissions_power.jl")
include("GenX/model/resources/curtailable_variable_renewable/curtailable_variable_renewable.jl")
include("GenX/model/resources/flexible_demand/flexible_demand.jl")
include("GenX/model/resources/hydro/hydro_res.jl")
include("GenX/model/resources/must_run/must_run.jl")
include("GenX/model/resources/storage/storage.jl")
include("GenX/model/resources/storage/investment_energy.jl")
include("GenX/model/resources/storage/storage_all.jl")
include("GenX/model/resources/storage/long_duration_storage.jl")
include("GenX/model/resources/storage/investment_charge.jl")
include("GenX/model/resources/storage/storage_asymmetric.jl")
include("GenX/model/resources/storage/storage_symmetric.jl")

include("GenX/model/resources/thermal/thermal.jl")
include("GenX/model/resources/thermal/thermal_commit.jl")
include("GenX/model/resources/thermal/thermal_no_commit.jl")

include("GenX/model/policies/co2_cap_power.jl")
include("GenX/model/policies/energy_share_requirement.jl")
include("GenX/model/policies/cap_reserve_margin.jl")
include("GenX/model/policies/minimum_capacity_requirement.jl")

# Core HSC modelling features
include("HSC/model/core/h2_investment.jl")
include("HSC/model/core/h2_outputs.jl")
include("HSC/model/core/h2_non_served_energy.jl")
include("HSC/model/flexible_demand/h2_flexible_demand.jl")
include("HSC/model/core/emissions_hsc.jl")

# H2 production
include("HSC/model/generation/h2_production.jl")
include("HSC/model/generation/h2_production_all.jl")
include("HSC/model/generation/h2_production_commit.jl")
include("HSC/model/generation/h2_production_no_commit.jl")

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
include("HSC/model/storage/h2_storage_symmetric.jl")
include("HSC/model/storage/h2_storage_asymmetric.jl")
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

# Core CSC modelling features
include("CSC/model/core/co2_investment.jl")
include("CSC/model/core/co2_outputs.jl")
include("CSC/model/core/co2_non_served.jl")
include("CSC/model/core/emissions_csc.jl")

# CO2 capture
include("CSC/model/capture/co2_capture.jl")
include("CSC/model/capture/co2_capture_all.jl")
include("CSC/model/capture/co2_capture_commit.jl")
include("CSC/model/capture/co2_capture_no_commit.jl")

# CO2 storage
include("CSC/model/storage/co2_storage_investment.jl")
include("CSC/model/storage/co2_storage.jl")
include("CSC/model/storage/co2_storage_all.jl")
include("CSC/model/storage/co2_long_duration_storage.jl")

# CO2 pipelines
include("CSC/model/transmission/co2_pipeline.jl")

# CO2 trucks
include("CSC/model/truck/co2_truck_investment.jl")
include("CSC/model/truck/co2_truck.jl")
include("CSC/model/truck/co2_truck_all.jl")
include("CSC/model/truck/co2_long_duration_truck.jl")

# Load model generation and solving scripts
include("co2_cap_power_hsc.jl")
include("co2_cap_power_csc.jl")
include("co2_cap_power_hsc_csc.jl")
include("generate_model.jl")
include("solve_model.jl")

# Write global outputs
include("write_outputs/dftranspose.jl")
include("write_outputs/choose_output_dir.jl")
include("write_outputs/write_status.jl")
include("write_outputs/write_time_weights.jl")

include("write_outputs/write_Basic_outputs.jl")

# Write GenX outputs
include("GenX/write_outputs/write_capacity.jl")
include("GenX/write_outputs/write_charge.jl")
include("GenX/write_outputs/write_charging_cost.jl")
include("GenX/write_outputs/write_costs.jl")
include("GenX/write_outputs/write_curtailment.jl")
include("GenX/write_outputs/write_emissions.jl")
include("GenX/write_outputs/write_energy_revenue.jl")
include("GenX/write_outputs/write_net_revenue.jl")
include("GenX/write_outputs/write_nse.jl")
include("GenX/write_outputs/write_power.jl")
include("GenX/write_outputs/write_power_balance.jl")
include("GenX/write_outputs/write_price.jl")
include("GenX/write_outputs/write_reliability.jl")
include("GenX/write_outputs/write_storage.jl")
include("GenX/write_outputs/write_storagedual.jl")
include("GenX/write_outputs/write_subsidy_revenue.jl")

include("GenX/write_outputs/capacity_reserve_margin/write_capacity_value.jl")
include("GenX/write_outputs/capacity_reserve_margin/write_reserve_margin_revenue.jl")
include("GenX/write_outputs/capacity_reserve_margin/write_reserve_margin_w.jl")
include("GenX/write_outputs/capacity_reserve_margin/write_reserve_margin.jl")

include("GenX/write_outputs/energy_share_requirement/write_esr_prices.jl")
include("GenX/write_outputs/energy_share_requirement/write_esr_revenue.jl")

include("GenX/write_outputs/long_duration_storage/write_opwrap_lds_dstor.jl")
include("GenX/write_outputs/long_duration_storage/write_opwrap_lds_stor_init.jl")

include("GenX/write_outputs/reserves/write_reg.jl")
include("GenX/write_outputs/reserves/write_rsv.jl")

include("GenX/write_outputs/transmission/write_nw_expansion.jl")
include("GenX/write_outputs/transmission/write_transmission_flows.jl")
include("GenX/write_outputs/transmission/write_transmission_losses.jl")

include("GenX/write_outputs/ucommit/write_commit.jl")
include("GenX/write_outputs/ucommit/write_shutdown.jl")
include("GenX/write_outputs/ucommit/write_start.jl")

include("GenX/write_outputs/write_Power_outputs.jl")

# Write HSC outputs
include("HSC/write_outputs/write_h2_gen.jl")
include("HSC/write_outputs/write_h2_capacity.jl")
include("HSC/write_outputs/write_h2_nse.jl")
include("HSC/write_outputs/write_h2_costs.jl")
include("HSC/write_outputs/write_h2_balance.jl")
include("HSC/write_outputs/write_h2_pipeline_flow.jl")
include("HSC/write_outputs/write_h2_pipeline_level.jl")
include("HSC/write_outputs/write_h2_pipeline_expansion.jl")
include("HSC/write_outputs/write_h2_emissions.jl")
include("HSC/write_outputs/write_h2_charge.jl")
include("HSC/write_outputs/write_h2_storage.jl")
include("HSC/write_outputs/write_h2_truck_capacity.jl")
include("HSC/write_outputs/write_h2_truck_flow.jl")
include("HSC/write_outputs/write_HSC_outputs.jl")
include("HSC/write_outputs/write_p_g2p.jl")
include("HSC/write_outputs/write_h2_g2p.jl")
include("HSC/write_outputs/write_g2p_capacity.jl")

# Write CSC outputs
include("CSC/write_outputs/write_co2_capture.jl")
include("CSC/write_outputs/write_co2_capacity.jl")
include("CSC/write_outputs/write_co2_costs.jl")
include("CSC/write_outputs/write_co2_balance.jl")
include("CSC/write_outputs/write_co2_pipeline_flow.jl")
include("CSC/write_outputs/write_co2_pipeline_level.jl")
include("CSC/write_outputs/write_co2_pipeline_expansion.jl")
include("CSC/write_outputs/write_co2_emissions.jl")
include("CSC/write_outputs/write_co2_storage_capacity.jl")
include("CSC/write_outputs/write_co2_storage_costs.jl")
include("CSC/write_outputs/write_co2_storage.jl")
include("CSC/write_outputs/write_co2_truck_capacity.jl")
include("CSC/write_outputs/write_co2_truck_flow.jl")
include("CSC/write_outputs/write_CSC_outputs.jl")

# Modeling to generate alternatives
include("modeling_to_generate_alternatives/modeling_to_generate_alternatives.jl")

end
