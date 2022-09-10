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
    fake_load()

This function fakes load data of each zone from nowhere.
"""
function fake_load(path::AbstractString, zones::Integer, time_length::Integer)

    # Construct static demand segment dataframe
    df_load_seg = DataFrame(
        Demand_Segment = [1,2,3,4],
        Cost_of_Demand_Curtailment_per_MW = [1, 0.9,0.55,0.2],
        Max_Demand_Curtailment = [1,0.04,0.024,0.003]
    )

    # Construct dynamic demand curve
    # Create time index
    df_load = DataFrame(Time_Index = 1:time_length)

    # Create zonal load identifier as columns
    df_load = hcat(df_load, DataFrame([zone = rand(time_length) .* 10000 for zone in 1:zones], :auto))
    rename!(df_load, vcat(["Time_Index"], ["Load_MW_z$zone" for zone in 1:zones]))

    # Write load segment and time-varying load into csv files
    CSV.write(joinpath(path, "Load_seg.csv"), df_load_seg)
    CSV.write(joinpath(path, "Load_data.csv"), df_load)

    return df_load_seg, df_load

end
