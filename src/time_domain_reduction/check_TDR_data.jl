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

@doc """
    check_TDR_data(path::AbstractString, setup::Dict)

This function is used to check whether time domain reduction data exists when ```TimeDomainReduction``` is set to true.
"""
function check_TDR_data(path::AbstractString, setup::Dict)
    
    println("Using Time Domain Reduction. Checking TDR Data...")
    
    flag = (!isfile(joinpath(path, "Fuels_data.csv")))

    if setup["ModelPower"] == 1
        flag = flag || (!isfile(joinpath(path, "Power", "Load_data.csv"))) || (!isfile(joinpath(path, "Power", "Generators_variability.csv")))
    end

    if setup["ModelH2"] == 1
        flag = flag || (!isfile(joinpath(path, "HSC", "HSC_load_data.csv"))) || (!isfile(joinpath(path, "HSC", "HSC_generators_variability.csv")))
    end

    if setup["ModelCO2"] == 1
        flag = flag || (!isfile(joinpath(path, "CSC", "CSC_load_data.csv"))) || (!isfile(joinpath(path, "CSC", "CSC_capture_variability.csv")))
    end

    return flag
end