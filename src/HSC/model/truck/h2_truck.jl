"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
    h2_truck(EP::Model, inputs::Dict, setup::Dict)

"""
function h2_truck(EP::Model, inputs::Dict, setup::Dict)

    println("Hydrogen Truck Module")

    # investment variables expressions and related constraints for H2 trucks
    EP = h2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

     # Operating variables, expressions and constraints related to H2 trucks
    EP = h2_truck_all(EP, inputs, setup)

    # Include LongDurationtruck only when modeling representative periods
    if setup["OperationWrapping"] == 1
        EP = h2_long_duration_truck(EP, inputs)
    end
    
    return EP
end
