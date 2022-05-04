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

push!(LOAD_PATH,"../src/HSC")
#=cd("../")
include(joinpath(pwd(), "package_activate.jl"))
DOLPHYN_path = joinpath(pwd(), "src")
push!(LOAD_PATH, DOLPHYN_path)=#
import DataStructures: OrderedDict
using DOLPHYN
using Documenter
DocMeta.setdocmeta!(DOLPHYN, :DocTestSetup, :(using DOLPHYN); recursive=true)
println(pwd())
DOLPHYN_docpath = joinpath(pwd(), "src/HSC")
push!(LOAD_PATH, DOLPHYN_docpath)
pages = OrderedDict(
    "Model Function Reference" => [
        "Core" => "core.md",
        "Flexible Demand" => "flexible_demand.md",
        "G2P" => "g2p.md",
        "Generation" => "generation.md",
        "Policies" => "policies.md",
        "Storage" => [
            "Long Duration"=> "h2_long_duration_storage.md",
            "Storage ALL" => "h2_storage_all.md",
            "Storage Investment" => "h2_storage_investment.md",
            "Storage" => "h2_storage.md"
        ],
        "Transimission" => "transmission.md",
        "Truck" => [
            "Long Duration Truck" => "h2_long_duration_truck.md",
            "Truck All" => "h2_truck_all.md",
            "Truck Investment" => "h2_truck_investment.md",
            "Truck" => "h2_truck.md"
        ],
        "Generation" => [
            "Production All" => "h2_production_all.md",
            "Production Commit" => "h2_production_commit.md"
            "Production No Commit" => "h2_production_no_commit.md",
            "Production" => "h2_production.md"
        ],
        "Policies" => "policies.md"
    ],
    "DOLPHYN Inputs Functions" => "load_inputs.md",
    "DOLPHYN Outputs Functions" => "write_outputs.md",
    #"Unit Testing (Under Development)" => "unit_testing.md"
)
makedocs(;
    modules=[DOLPHYN],
    authors="Jesse Jenkins, Nestor Sepulveda, Dharik Mallapragada, Aaron Schwartz, Neha Patankar, Qingyu Xu, Jack Morris, Sambuddha Chakrabarti",
    #repo="https://github.com/sambuddhac/DOLPHYN.jl/blob/{commit}{path}#{line}",
    sitename="DOLPHYN",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        assets=String[],
    ),
    pages=[p for p in pages]
)

deploydocs(;
    repo="github.com/gn-he/DOLPHYN-dev.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "main",
    push_preview = true,
)
