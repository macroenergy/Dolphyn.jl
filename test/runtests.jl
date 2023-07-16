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

using Test

## Unit tests for DOLPHYN
println("Test One Zone Case for DOLPHYN")
@test include("../Example_Systems/SmallNewEngland/OneZone/Run.jl") === nothing
println("One Zone Case Test Passed!")

println("Test Three Zones Case for DOLPHYN")
@test include("../Example_Systems/SmallNewEngland/ThreeZones/Run.jl") === nothing
println("Three Zones Case Test Passed!")

# println("Test Three Zones Liquid Case for DOLPHYN")
# @test include("../Example_Systems/SmallNewEngland/ThreeZones_Liquid/Run.jl") === nothing
# println("Three Zones Liquid Case Test Passed!")