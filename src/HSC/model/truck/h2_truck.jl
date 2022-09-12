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
    h2_truck(EP::Model, inputs::Dict, setup::Dict)

This function includes three parts of the Truck Model.The details can be found seperately in "h2\_truck\_investment.jl" "h2\_long\_duration_truck.jl" and "h2\_truck\_all.jl".
   
"""
function h2_truck(EP::Model, inputs::Dict, setup::Dict)

    println("Hydrogen Truck Module")

    # investment variables expressions and related constraints for H2 trucks
    EP = h2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

     # Operating variables, expressions and constraints related to H2 trucks
    EP = h2_truck_all(EP, inputs, setup)

    # Include LongDurationTruck only when modeling representative periods and long-duration truck
    if setup["OperationWrapping"] == 1 && !isempty(inputs["H2_TRUCK_LONG_DURATION"])
        EP = h2_long_duration_truck(EP, inputs)
    end
    
    return EP
end
