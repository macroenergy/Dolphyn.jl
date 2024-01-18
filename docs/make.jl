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

push!(LOAD_PATH,joinpath(@__DIR__,"src"))
push!(LOAD_PATH,joinpath(dirname(@__DIR__),"src"))
push!(LOAD_PATH,joinpath(dirname(@__DIR__),"src","GenX","src"))

using Documenter, Dolphyn
import DataStructures: OrderedDict

DocMeta.setdocmeta!(Dolphyn, :DocTestSetup, :(using Dolphyn); recursive = true)

doc_tools_dir = joinpath(@__DIR__, "doc_tools")
include(joinpath(doc_tools_dir, "module_parser.jl"))
include(joinpath(doc_tools_dir, "update_genx_docs.jl"))

pages = OrderedDict(
    "Welcome Page" => "index.md",
    "Solvers" => "solvers.md",
    "Model Introduction" => "dolphyn_model_introduction.md", # Should cover both HSC and GenX model overview
    # Cover Model inputs and outputs documentation
    "Model Inputs/Outputs Documentation" => [
        "global_data_documentation.md",
        "GenX Database Documentation" => [
            "Single-stage Model" => "data_documentation.md",
            "Multi-stage Model" => "multi_stage_model_overview.md",
        ],  
        "hsc_data_documentation.md",
        "csc_data_documentation.md",
        "lfsc_data_documentation.md"
    ],
    "Objective Function" => "objective_function.md", # Should cover both models
    "GenX" => [
        "Model Introduction" => "model_introduction.md",
        "GenX Inputs Functions" => "load_inputs.md",
        "GenX Outputs Functions" => "write_outputs.md",
        "GenX Notation" => "model_notation.md",
        "Power Balance" => "power_balance.md",
        "GenX Function Reference" => [
            "Core" => "core.md",
            "Resources" => [
                "Curtailable Variable Renewable" => "curtailable_variable_renewable.md",
                "Flexible Demand" => "flexible_demand.md",
                "Hydro" => [
                    "Hydro Reservoir" => "hydro_res.md",
                    "Long Duration Hydro" => "hydro_inter_period_linkage.md"
                ],
                "Must Run" => "must_run.md",
                "Storage" => [
                    "Storage" => "storage.md",
                    "Investment Charge" => "investment_charge.md",
                    "Investment Energy" => "investment_energy.md",
                    "Long Duration Storage" => "long_duration_storage.md",
                    "Storage All" => "storage_all.md",
                    "Storage Asymmetric" => "storage_asymmetric.md",
                    "Storage Symmetric" => "storage_symmetric.md"
                ],
                "Thermal" => [
                    "Thermal" => "thermal.md",
                    "Thermal Commit" => "thermal_commit.md",
                    "Thermal No Commit" => "thermal_no_commit.md"
                ],
            ],
            "Multi_stage" => [
                    "Configure multi-stage inputs" => "configure_multi_stage_inputs.md",
                    "Model multi stage: Dual Dynamic Programming Algorithm" => "dual_dynamic_programming.md",
            ],
            "Slack Variables for Policies" => "slack_variables_overview.md",
        ],
        "GenX Inputs Functions" => "load_inputs.md",
        "GenX Outputs Functions" =>"write_outputs.md",
        "Additional Features" => "additional_features.md",
        "Third Party Extensions" => "additional_third_party_extensions.md"
    ],
    "Hydrogen Supply Chain (HSC)" => [
        "HSC Inputs Functions" => "load_h2_inputs.md",
        "HSC Outputs Functions" => "write_h2_outputs.md",
        "HSC Notation" => "hsc_notation.md",
        "HSC Supply-Demand Balance" => "h2_balance.md",
        "HSC Function Reference" => [
            "Hydrogen Core" => "h2_core.md",
            "Hydrogen Flexible Demand" => "h2_flexible_demand.md",
            "Hydrogen to Power" => "g2p.md",
            "Hydrogen Storage" => [
                "Hydrogen Long Duration Storage" => "h2_long_duration_storage.md",
                "Hydrogen Storage ALL" => "h2_storage_all.md",
                "Hydrogen Storage Investment" => "h2_storage_investment.md",
                "Hydrogen Storage" => "h2_storage.md",
            ],
            "Hydrogen Transmission" => "h2_transmission.md",
            "Hydrogen Truck" => [
                "Hydrogen Long Duration Truck" => "h2_long_duration_truck.md",
                "Hydrogen Truck All" => "h2_truck_all.md",
                "Hydrogen Truck Investment" => "h2_truck_investment.md",
                "Hydrogen Truck" => "h2_truck.md",
            ],
            "Hydrogen Production" => [
                "Hydrogen Production All" => "h2_production_all.md",
                "Hydrogen Production Commit" => "h2_production_commit.md",
                "Hydrogen Production No Commit" => "h2_production_no_commit.md",
                "Hydrogen Production" => "h2_production.md",
            ],
        ],
    ],

    "CO2 Supply Chain (CSC)" => [
        "CSC Inputs Functions" => "load_co2_inputs.md",
        "CSC Outputs Functions" => "write_co2_outputs.md",
        "CSC Notation" => "csc_notation.md",

        "CSC Function Reference" => [
            "CSC Core" => "co2_core.md",
            "CO2 Capture" => "co2_capture.md",
            "CO2 Compression" => "co2_compression.md",
            "CO2 Storage" => "co2_storage.md",
            "CO2 Transmission" => "co2_transmission.md",
        ],
    ],

    "Liquid Fuels Supply Chain (LFSC)" => [
        "LFSC Inputs Functions" => "load_liquid_fuels_inputs.md",
        "LFSC Outputs Functions" => "write_liquid_fuels_outputs.md",
        "LFSC Notation" => "lfsc_notation.md",

        "LFSC Function Reference" => [
            "LFSC Core" => "liquid_fuels_core.md",
            "LF Demand" => "liquid_fuels_demand.md",
            "LF Resources" => "liquid_fuels_resources.md",
        ],
    ],

    "Additional Tools" => "additional_tools.md",
    "Solving the Model" => "solve_model.md",
    "Methods" => "methods.md",
)

genx_doc_path = joinpath(dirname(@__DIR__), "src", "GenX", "docs")

# This will add new pages in the GenX docs to the DOLPHYN docs
# It's disabled for now, as it's leading to duplicate pages,
# which Documenter.jl handles by only building the first instance.
# This means we have to manually update the GenX doc tree for now
# insert_new_genx_pages!(pages, genx_doc_path)

update_genx_docs(genx_doc_path)

copy_assets(genx_doc_path)

makedocs(;
    modules = [Dolphyn],
    authors = "Dharik S. Mallapragada, Ruaridh Macdonald, Guannan He, Mary Bennett, Shantanu Chakraborty, Anna Cybulsky, Michael Giovanniello, Jun Wen Law, Youssef Shaker, Nicole Shi and Yuheng Zhang",
    sitename = "Dolphyn.jl",
    format = Documenter.HTML(),
    pages = [p for p in pages],
    doctest=false,
    warnonly=true
)

deploydocs(;
    repo = "https://github.com/macroenergy/Dolphyn.jl.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "main",
    devurl = "dev",
    push_preview=true,
    versions = ["stable" => "v^", "v#.#", "v#.#.#"],
    forcepush = false,
)
