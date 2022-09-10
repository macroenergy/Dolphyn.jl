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
    fake_network(path::AbstractString, zones::Integer)

This function fakes a imaginary power network from nowhere.
"""
function fake_network(path::AbstractString, zones::Integer)

    # Compute factorial number
    lines = binomial(zones, 2)

    # Generate zone list
    Zones = ["z$z" for z = 1:zones]

    # Lines parameters
    df_lines = DataFrame(
        Network_Lines = 1:lines,
        Line_Name = 1:lines,
        Line_Max_Flow_MW = round.(rand(lines) .* 1000),
        distance_mile = rand(lines) .* 100,
        Line_Loss_Percentage = rand(lines) ./ 100,
        Line_Max_Reinforcement_MW = round.(rand(lines) .* 1000),
        Line_Reinforcement_Cost_per_MWyr = rand(lines) .* 10000,
    )

    # Lines map
    df_lines_map = DataFrame(StartZone = String[], EndZone = String[])
    lines_map = collect(Combinatorics.combinations(Zones, 2))
    for l = 1:lines
        push!(df_lines_map, lines_map[l])
    end

    # Merge lines map into lines parameter dataframe
    df_lines = hcat(df_lines, df_lines_map)

    # Construct static line parameter dataframe
    df_lines_static = DataFrame(
        Line_Voltage_kV = repeat([230], lines),
        Line_Resistance_ohms = repeat([1.234], lines),
        Line_X_ohms = repeat([1.234], lines),
        Line_R_ohms = repeat([1.234], lines),
        Thetha_max = repeat([1.5], lines),
        Peak_Withdrawal_Hours = repeat(["All"], lines),
        Peak_Injection_Hours = repeat(["all"], lines),
        After_Tax_WACC = repeat([0.071], lines),
    )

    # Merge static line parameters dataframe into lines parameters dataframe
    df_lines = hcat(df_lines, df_lines_static)

    # Write lines parameters dataframe into csv file
    CSV.write(joinpath(path, "Network.csv"), df_lines)

end
