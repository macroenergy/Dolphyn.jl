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

@doc raw"""
    co2_storage(EP::Model, inputs::Dict, setup::Dict)

This function contains and maintains all functions related to carbon storage.
"""

function co2_storage(EP::Model, inputs::Dict, setup::Dict)

    println("Carbon Storage Module")

   # investment variables expressions and related constraints for CO2 storage tehcnologies
    EP = co2_storage_investment(EP::Model, inputs::Dict, setup::Dict)

    # Operating variables, expressions and constraints related to CO2 storage
    EP = co2_storage_all(EP, inputs, setup)


    # Include LongDurationStorage only when modeling representative periods and long-duration storage
    if setup["OperationWrapping"] == 1 && !isempty(inputs["CO2_STOR_LONG_DURATION"])
        EP = co2_long_duration_storage(EP, inputs)
    end

    return EP
end
