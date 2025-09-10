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

@doc raw"""
load_subperiod_power_charge(setup::Dict, path::AbstractString, inputs::Dict)

Function for reading input parameters related to hourly generation results from subperiod for all power generators (plus storage).
"""
function load_subperiod_power_charge(setup::Dict, path::AbstractString, inputs::Dict)

    # Hourly capacity factors
    filename = "ClusterSubPeriod_Charge.csv"
    power_charge_df = DataFrame(CSV.File(joinpath(path, filename), header=true), copycols=true)

    all_resources = inputs["RESOURCES"]

    # Reorder columns: [:Time_Index, <resource symbols in correct order>]
    select!(power_charge_df, [:t; Symbol.(all_resources)])

    # Load generation data into pP_Max (or whatever structure you need)
    inputs["Subperiod_PowerCharge"] = transpose(Matrix{Float64}(power_charge_df[:, 2:end]))

    println(" -- " * filename * " Successfully Read!")

    return inputs
end
