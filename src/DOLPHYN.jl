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
export load_co2_inputs
export load_syn_fuels_inputs
export load_bio_inputs
export generate_model
export solve_model
export write_outputs
export write_HSC_outputs
export write_CSC_outputs
export write_synfuel_outputs
export write_BESC_outputs
export cluster_inputs
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
#using Documenter
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
ModelScalingFactor = 1e+3

# Lower heating value of Hydrogen
# LHV is used when defining a system-wide CO2 constraint for the joint hydrogen and electricity infrastructures (SystemCO2Constraint =2)
H2_LHV = 33.33 # MWh per tonne

# Logging flag
Log = true

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

# Load input data - GenX
include("GenX/load_inputs/load_generators_data.jl")
include("GenX/load_inputs/load_generators_variability.jl")
include("GenX/load_inputs/load_network_data.jl")
include("GenX/load_inputs/load_reserves.jl")
include("GenX/load_inputs/load_cap_reserve_margin.jl")
include("GenX/load_inputs/load_energy_share_requirement.jl")
include("GenX/load_inputs/load_co2_cap.jl")
include("GenX/load_inputs/load_period_map.jl")
include("GenX/load_inputs/load_minimum_capacity_requirement.jl")
include("GenX/load_inputs/load_load_data.jl")
include("GenX/load_inputs/load_fuels_data.jl")
include("GenX/load_inputs/load_inputs.jl")

# Load time domain reduction related scripts
include("time_domain_reduction/time_domain_reduction.jl")

#Load input data - HSC
include("HSC/load_inputs/load_h2_gen.jl")
include("HSC/load_inputs/load_h2_demand.jl")
include("HSC/load_inputs/load_h2_generators_variability.jl")
include("HSC/load_inputs/load_h2_pipeline_data.jl")
include("HSC/load_inputs/load_h2_truck.jl")
include("HSC/load_inputs/load_h2_inputs.jl")
include("HSC/load_inputs/load_co2_cap_hsc.jl")
include("HSC/load_inputs/load_h2_g2p.jl")
include("HSC/load_inputs/load_h2_g2p_variability.jl")

#Load input data - CSC
include("CSC/load_inputs/load_co2_inputs.jl")
include("CSC/load_inputs/load_co2_capture.jl")
include("CSC/load_inputs/load_co2_capture_variability.jl")
include("CSC/load_inputs/load_co2_storage.jl")
include("CSC/load_inputs/load_co2_capture_compression.jl")
include("CSC/load_inputs/load_co2_pipeline_data.jl")

#Load input data - syn fuels
include("SynFuels/load_inputs/load_syn_fuels_inputs.jl")
include("SynFuels/load_inputs/load_syn_fuels_resources.jl")
include("SynFuels/load_inputs/load_liquid_fuel_demand.jl")

#Load input data - BESC
include("BESC/load_inputs/load_bio_inputs.jl")
include("BESC/load_inputs/load_bio_refinery.jl")
include("BESC/load_inputs/load_bio_supply.jl")
include("BESC/load_inputs/load_bio_ethanol_demand.jl")


#Core GenX Features
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
include("GenX/model/resources/hydro/hydro_inter_period_linkage.jl")
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


#Core CSC Modelling Features
include("CSC/model/core/co2_capture_investment.jl")
include("CSC/model/core/co2_capture_var_cost.jl")
include("CSC/model/core/emissions_csc.jl")

# CO2 Capture
include("CSC/model/capture/co2_capture.jl")
include("CSC/model/capture/co2_capture_non_uc.jl")
include("CSC/model/capture/co2_capture_uc.jl")

# CO2 Storage
include("CSC/model/storage/co2_injection_investment.jl")
include("CSC/model/storage/co2_injection.jl")

# CO2 Compression
include("CSC/model/compression/co2_capture_compression_investment.jl")
include("CSC/model/compression/co2_capture_compression.jl")

# CO2 Pipeline
include("CSC/model/transmission/co2_pipeline.jl")

#Syn Fuels
include("SynFuels/model/core/syn_fuel_investment.jl")
include("SynFuels/model/core/liquid_fuel_emissions.jl")
include("SynFuels/model/core/syn_fuel_outputs.jl")

include("SynFuels/model/demand/liquid_fuel_demand.jl")

include("SynFuels/model/resources/syn_fuel_res_all.jl")
include("SynFuels/model/resources/syn_fuel_resources.jl")
include("SynFuels/model/resources/syn_fuels_res_no_commit.jl")

#Core BESC Modelling Features
include("BESC/model/core/biorefinery_investment.jl")
include("BESC/model/core/biorefinery.jl")
include("BESC/model/core/biorefinery_var_cost.jl")
include("BESC/model/core/emissions_besc.jl")

#Biomass Supplies
include("BESC/model/supply/bio_herb_supply.jl")
include("BESC/model/supply/bio_wood_supply.jl")

# Load model generation and solving scripts
include("co2_cap_power_hsc.jl")
include("generate_model.jl")
include("solve_model.jl")


# Write GenX Outputs
include("GenX/write_outputs/dftranspose.jl")
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
include("GenX/write_outputs/write_status.jl")
include("GenX/write_outputs/write_storage.jl")
include("GenX/write_outputs/write_storagedual.jl")
include("GenX/write_outputs/write_subsidy_revenue.jl")
include("GenX/write_outputs/write_time_weights.jl")
include("GenX/write_outputs/choose_output_dir.jl")

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

include("GenX/write_outputs/write_costs_system.jl")

include("GenX/write_outputs/write_outputs.jl")

# HSC Write Outputs
include("HSC/write_outputs/write_h2_gen.jl")
include("HSC/write_outputs/write_h2_capacity.jl")
include("HSC/write_outputs/write_h2_nse.jl")
include("HSC/write_outputs/write_h2_costs.jl")
include("HSC/write_outputs/write_h2_balance.jl")
include("HSC/write_outputs/write_h2_balance_dual.jl")
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

# CSC Write Outputs
include("CSC/write_outputs/write_co2_capture_capacity.jl")
include("CSC/write_outputs/write_CSC_outputs.jl")
include("CSC/write_outputs/write_CSC_costs.jl")
include("CSC/write_outputs/write_co2_storage_injection_capacity.jl")
include("CSC/write_outputs/write_co2_pipeline_flow.jl")
include("CSC/write_outputs/write_co2_pipeline_expansion.jl")
include("CSC/write_outputs/write_co2_emission_balance_zone.jl")
include("CSC/write_outputs/write_co2_storage_balance.jl")
include("CSC/write_outputs/write_co2_emission_balance_system.jl")
include("CSC/write_outputs/write_co2_balance_dual.jl")

#Write SynFuel Outputs
include("SynFuels/write_outputs/write_synfuel_outputs.jl")
include("SynFuels/write_outputs/write_liquid_fuel_demand_balance.jl")
include("SynFuels/write_outputs/write_liquid_fuel_balance_dual.jl")
include("SynFuels/write_outputs/write_synfuel_balance.jl")
include("SynFuels/write_outputs/write_synfuel_capacity.jl")
include("SynFuels/write_outputs/write_synfuel_costs.jl")
include("SynFuels/write_outputs/write_synfuel_gen.jl")
include("SynFuels/write_outputs/write_synfuel_emissions.jl")

# BESC Write Outputs
include("BESC/write_outputs/write_BESC_outputs.jl")
include("BESC/write_outputs/write_BESC_costs.jl")
include("BESC/write_outputs/write_bio_plant_capacity.jl")
include("BESC/write_outputs/write_bio_zone_bioelectricity_produced.jl")
include("BESC/write_outputs/write_bio_zone_biohydrogen_produced.jl")
include("BESC/write_outputs/write_bio_zone_biodiesel_produced.jl")
include("BESC/write_outputs/write_bio_zone_biogasoline_produced.jl")
include("BESC/write_outputs/write_bio_zone_bioethanol_produced.jl")
include("BESC/write_outputs/write_bio_zone_herb_consumed.jl")
include("BESC/write_outputs/write_bio_zone_wood_consumed.jl")

end
