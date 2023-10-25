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

using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()

using Documenter
import DataStructures: OrderedDict
using DOLPHYN

DocMeta.setdocmeta!(DOLPHYN, :DocTestSetup, :(using DOLPHYN); recursive = true)

include(joinpath(@__DIR__, "module_parser.jl"))

# DocMeta.setdocmeta!(DOLPHYN, :DocTestSetup, :(using DOLPHYN); recursive = true)

pages = OrderedDict(
    "Welcome Page" => "index.md",
    "Solvers" => "solvers.md",
    "Model Introduction" => "model_introduction.md", # Should cover both HSC and GenX model overview
    # Cover Model inputs and outputs documentation
    "Model Inputs/Outputs Documentation" => [
        "global_data_documentation.md",
        "GenX Database Documentation" => [
            "Single-stage Model" => "data_documentation.md",
            "Multi-stage Model" => "multi_stage_model_overview.md",
        ],  
        "hsc_data_documentation.md"
    ],
    "Objective Function" => "objective_function.md", # Should cover both models
    "GenX" => [
        "GenX Inputs Functions" => "load_inputs.md",
        "GenX Outputs Functions" => "write_outputs.md",
        "GenX Notation" => "genx_notation.md",
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
        "Solver Configurations" => "solver_configuration.md",
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

function insert_new_genx_pages!(pages::OrderedDict, genx_doc_path::String)
# Try to insert GenX pages if they exist
    if isdir(genx_doc_path)
        genx_pages = get_pages_dict(joinpath(genx_doc_path, "make.jl"))
        if haskey(genx_pages, "Model Inputs/Outputs Documentation")
            pages["Model Inputs/Outputs Documentation"][2] = "GenX Database Documentation" => genx_pages["Model Inputs/Outputs Documentation"]
        end
        if haskey(genx_pages, "Model Function Reference")
            pages["GenX"][5] = "GenX Function Reference" => genx_pages["Model Function Reference"]
        end
        if haskey(genx_pages, "Notation")
            pages["GenX"][3] = "Genx Notation" => genx_pages["Notation"]
        end
    end
end

genx_doc_path = joinpath(dirname(@__DIR__), "src", "GenX", "docs")
insert_new_genx_pages!(pages, genx_doc_path)

function change_module_to_dolphyn(filepath::String)
    # Read a file line by line
    # If the line contains Modules = [GenX], replace it with Modules = [DOLPHYN]
    # Save the lines as arrays.
    lines = []
    open(filepath) do file
        for line in eachline(file)
            if contains(line, "Modules = [GenX]")
                line = "Modules = [DOLPHYN]"
            end
            push!(lines, line)
        end
    end
    return lines
end
    
function update_genx_docs(genx_doc_path::String)
    # List all the genx and dolphyn doc files
    genx_docs = readdir(joinpath(genx_doc_path, "src"))
    dolphyn_docs = readdir(joinpath(@__DIR__, "src"))
    # For each doc in genx_docs, copy or replace it in dolphyn_docs
    for doc in genx_docs
        if !contains(doc, ".md")
            continue
        end
        if !(doc in dolphyn_docs)
            updated_file = change_module_to_dolphyn(joinpath(genx_doc_path, "src", doc))
            open(joinpath(@__DIR__, "src", doc), "w") do file
                for line in updated_file
                    println(file, line)
                end
            end
        end
    end
end

update_genx_docs(genx_doc_path)

# Copy all assets from GenX to DOLPHYN
function copy_assets(genx_doc_path::String)
    genx_assets = readdir(joinpath(genx_doc_path, "src", "assets"))
    for asset in genx_assets
        if !contains(asset, ".")
            continue
        end
        if !isfile(joinpath(@__DIR__, "src", "assets", asset))
            cp(joinpath(genx_doc_path, "src", "assets", asset), joinpath(@__DIR__, "src", "assets", asset))
        end
    end
end

copy_assets(genx_doc_path)

makedocs(;
    modules = [DOLPHYN],
    authors = "Guannan He, Dharik Mallapragada, Mary Bennett, Shantanu Chakraborty, Anna Cybulsky, Michael Giovanniello, Jun Wen Law, Youssef Shaker, Nicole Shi and Yuheng Zhang",
    sitename = "DOLPHYN",
    format = Documenter.HTML(),
    pages = [p for p in pages],
    doctest = false,
    warnonly = true
)

deploydocs(;
    repo = "github.com/macroenergy/DOLPHYN.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "main",
    devurl = "dev",
    push_preview=true,
    versions = ["stable" => "v^", "v#.#"],
    forcepush = false,
)
