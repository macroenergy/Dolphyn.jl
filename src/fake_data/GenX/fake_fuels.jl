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
    fake_fuels(path::AbstractString, fuels::Array, time_length::Integer)

This function fakes imaginary fuel prices from nowhere.
"""
function fake_fuels(path::AbstractString, fuels::Array, time_length::Integer)

    # Add None type of fuel
    push!(fuels, "None")

    # Create time index
    df_fuels = DataFrame(Time_Index = vcat([0], 1:time_length))

    # Create fuel types as columns
    df_fuels = hcat(df_fuels, DataFrame([fuel = zeros(time_length + 1) for fuel in fuels], :auto))
    rename!(df_fuels, vcat(["Time_Index"], fuels))

    # Fake fuels emission factor
    fuels_emision = rand(length(fuels) - 1) ./ 100
    df_fuels[1, 2:end] = vcat(fuels_emision, [0]) .* 10

    # Fake fuels prices
    for fuel in fuels[1:end-1]
        df_fuels[2:time_length+1, fuel] = rand(time_length)
    end


    CSV.write(joinpath(path, "Fuels_data.csv"), df_fuels)

    return df_fuels

end
