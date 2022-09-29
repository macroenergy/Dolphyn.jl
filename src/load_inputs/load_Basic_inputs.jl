"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021, Massachusetts Institute of Technology and Peking University
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
    load_basic_inputs(path::AbstractString, setup::Dict)

Load basic inputs for the macro energy system. The external fuels data, time weights used in the time domain reduction method.
"""
function load_basic_inputs(path::AbstractString, setup::Dict)

    inputs = Dict()

    ## Load spatial details from setup
    inputs = load_spatial_details(setup, inputs)

    ## Load temporal details from setup
    inputs = load_temporal_details(setup, inputs, path)

    ## Read input files
    println("Reading Basic Input CSV Files")
    ## Read fuel cost data, including time-varying fuel costs
    inputs = load_fuels_data(setup, inputs, path)

    return inputs
end
