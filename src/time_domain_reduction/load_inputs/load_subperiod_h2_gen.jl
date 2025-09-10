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
load_subperiod_h2_gen(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

Function for reading input parameters related to hourly generation results from subperiod for all h2 generators (plus storage).
"""
function load_subperiod_h2_gen(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

    h2_gen_df = DataFrame(CSV.File(joinpath(path, "ClusterSubPeriod_H2Gen.csv"), header=true), copycols=true)

    # Reorder DataFrame to R_ID order (order provided in ClusterSubPeriod_H2Gen.csv)
    select!(h2_gen_df, [:t; Symbol.(inputs["H2_RESOURCES_NAME"]) ])

    # Maximum power output and variability of each energy resource
    inputs["Subperiod_H2Gen"] = transpose(Matrix{Float64}(h2_gen_df[1:inputs["T"],2:(inputs["H2_RES_ALL"]+1)]))

    print_and_log(" -- ClusterSubPeriod_H2Gen.csv Successfully Read!")
    
    return inputs
end
