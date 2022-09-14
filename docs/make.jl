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

push!(LOAD_PATH,"../src/")
push!(LOAD_PATH,"docs/src")
import DataStructures: OrderedDict
using DOLPHYN
using Documenter
DocMeta.setdocmeta!(DOLPHYN, :DocTestSetup, :(using DOLPHYN); recursive = true)
println(pwd())
pages = OrderedDict(
    "Welcome Page" => "index.md",
    "Solvers" => "solvers.md",
    "GenX" => [
        "GenX Introduction" => "model_introduction.md",
        "Model Inputs/Outputs Documentation" => "data_documentation.md",
        "GenX Inputs Functions" => "load_inputs.md",
        "GenX Outputs Functions" => "write_outputs.md",
        "GenX Notation" => "genx_notation.md",
        "Objective Function" => "objective_function.md",
        "Power Balance" => "power_balance.md",
        "GenX Function Reference" => [
            "Core" => "core.md",
            "Resources" => [
                "Curtailable Variable Renewable" => "curtailable_variable_renewable.md",
                "Flexible Demand" => "flexible_demand.md",
                "Hydro" => "hydro_res.md",
                "Must Run" => "must_run.md",
                "Storage" => "storage.md",
                "Investment Charge" => "investment_charge.md",
                "Investment Energy" => "investment_energy.md",
                "Long Duration Storage" => "long_duration_storage.md",
                "Storage All" => "storage_all.md",
                "Storage Asymmetric" => "storage_asymmetric.md",
                "Storage Symmetric" => "storage_symmetric.md",
                "Thermal" => "thermal.md",
                "Thermal Commit" => "thermal_commit.md",
                "Thermal No Commit" => "thermal_no_commit.md",
            ],
            "Policies" => "policies.md",
        ],
    ],
    "HSC" => [
        "HSC Inputs Functions" => "load_h2_inputs.md",
        "HSC Outputs Functions" => "write_h2_outputs.md",
        "Hydrogen Notation" => "hsc_notation.md",
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
            "Hydrogen Transimission" => "h2_transmission.md",
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
    "Additional Tools" => "additional_tools.md",
    "Solving the Model" => "solve_model.md",
    "Methods" => "methods.md",
)

makedocs(;
    modules = [DOLPHYN],
    authors = "Dharik Mallapragada, Guannan He, Yuheng Zhang",
    sitename = "DOLPHYN",
    format = Documenter.HTML(),
    pages = [p for p in pages],
)

deploydocs(;
    repo = "github.com/MacroEnergyProject/DOLPHYN-dev.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "main",
    devurl = "dev",
    push_preview=true,
    versions = ["stable" => "v^", "v#.#"],
    forcepush = false,
)
