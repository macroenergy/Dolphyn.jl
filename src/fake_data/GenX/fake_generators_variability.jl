"""
LTESOM: Spatial-Temporal model complexity analysis based on GenX model in power system.
Copyright (C) 2022, College of Engineering, Peking University, Department of Industry and Engineering
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
    fake_generators_variability(path::AbstractString, zones::Integer, time_length::Integer, generators::Dict{String,Integer})

This function fakes imaginary generators variability from nowhere.
"""
function fake_generators_variability(path::AbstractString, zones::Integer, time_length::Integer, generators::Dict{String,Int64})

    # Generate zone list
    Zones = 1:zones

    # Construct the column names
    columns = replace.(collect("$key-$i-$z" for (key, value) in generators for i in 1:value for z in Zones), "-"=>"_")

    # Construct dataframe with time index
    df_generators_variability = DataFrame(
        Time_Index = 1:time_length
    )

    # Construct dataframe with initial variabilities of generators
    df_generators_variability = hcat(df_generators_variability, DataFrame(ones((time_length, length(columns))), :auto))

    # Rename dataframe
    auxnames = [Symbol("Time_Index"); [Symbol("$column") for column in columns]]
    rename!(df_generators_variability, auxnames)

    # Candidate generator list
    THERM_set = ["Nuclear", "CCGT", "CCGT_CCS", "OCGT_F"]
    VRE_set = ["PV", "Wind"]
    CCS_set = ["CCGT_CCS"]
    STO_set = ["Storage_bat"]
    candidates = union(THERM_set, VRE_set, CCS_set, STO_set)

    for column in columns
        resource_type = split(column, "_")[1]
        if resource_type in candidates
            if resource_type in VRE_set
                if resource_type == "Wind"
                    df_generators_variability[:, Cols(startswith("Wind"))] .= rand(Float64, (time_length, generators["Wind"]*zones))
                elseif resource_type == "PV"
                    df_generators_variability[
                        (0 .<= df_generators_variability.Time_Index .% 24 .<= 7) .|| (18 .<= df_generators_variability.Time_Index .% 24 .<= 23),
                        Cols(startswith("PV"))
                    ] .= 0
                    df_generators_variability[
                        (8 .<= df_generators_variability.Time_Index .% 24 .<= 17),
                        Cols(startswith("PV"))
                    ] .= rand(Float64, (Int(time_length*10/24), generators["PV"]*zones))
                end
            end
        end
    end

    CSV.write(joinpath(path, "Generators_variability.csv"), df_generators_variability)

end
