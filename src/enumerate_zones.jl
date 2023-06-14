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
    enumerate_zones(setup::Dict,path::AbstractString)

Loads various data inputs from multiple input .csv files in path directory and parse zonal information.

inputs:
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing updated zonal information
"""
function enumerate_zones(setup::Dict,path::AbstractString)

    print_and_log("Enumerating Zones")

    # if isfile(joinpath(path,"Network.csv"))
    #     network_var = DataFrame(CSV.File(joinpath(path,"Network.csv")))
    #     Zones = unique(union(network_var.Start_Zone, network_var.End_Zone))
    # end

    if setup["ModelH2"] == 1
        if setup["ModelH2Pipelines"] == 1
            if isfile(joinpath(path,"HSC_pipelines.csv"))
                network_var = DataFrame(CSV.File(joinpath(path,"HSC_pipelines.csv")))
                # Zones = unique(union(network_var.Start_Zone, network_var.End_Zone, Zones))
                Zones = unique(union(network_var.Start_Zone, network_var.End_Zone))
            end
        end
        ##TODO: add truck zone filter
    end

    print_and_log("Using Zones $(Zones)")
    return Zones
end
