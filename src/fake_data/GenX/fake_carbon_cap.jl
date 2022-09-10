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
    fake_carbon_cap()

This function fakes imaginary carbon cap for GenX from nowhere.
"""
function fake_carbon_cap(path::AbstractString, zones::Integer)

    # Construct carbon emission cap
    df_co2_cap = DataFrame(
        Network_Zones = 1:zones,
        Caped = repeat([Int(1)], zones),
        CO2_Max_tons_MWh = rand(zones),
        CO2_Max_Mtons = rand(zones)
    )

    # Write carbon cap dataframe into csv file
    CSV.write(joinpath(path, "CO2_cap.csv"), df_co2_cap)

    return df_co2_cap

end
