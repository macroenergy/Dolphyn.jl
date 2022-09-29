"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021, Massachusetts Institute of Technology and Peking University
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
    load_spatial_details(setup::Dict, inputs::Dict)

"""
function load_spatial_details(setup::Dict, inputs::Dict)

    println("Loading Spatial Details")

    Zones = setup["Zones"]

    Z = size(Zones, 1)

    if length(Set(Zones)) != Z
        println("There Exists Duplicate Zones in Predefined Spatial Aspect. Please Check.") #!this should be a trigger for exception.
        Zones = collect(Set(Zones))
    end

    println("$Z Zones Modelled: ", Zones)

    inputs["Z"] = Z
    inputs["Zones"] = Zones

    return inputs
end
