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
    co2_capture(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module uses the following 'helper' functions in separate files: ```co2_capture_solid()``` for solid DAC resources subject to unit commitment decisions and constraints (if any) and ```co2_capture_liquid()``` for liquid DAC resources not subject to unit commitment (if any).
"""
function co2_capture(EP::Model, inputs::Dict, setup::Dict)

    CO2_CAPTURE_SOLID = inputs["CO2_CAPTURE_SOLID"]
	CO2_CAPTURE_LIQUID = inputs["CO2_CAPTURE_LIQUID"]

	dfCO2Capture = inputs["dfCO2Capture"]  # Input CO2 capture data
	Z = inputs["Z"]  # Model demand zones - assumed to be same for CO2, H2 and electricity
	T = inputs["T"]	 # Model operating time steps

	if !isempty(CO2_CAPTURE_SOLID)
		EP = co2_capture_solid(EP::Model, inputs::Dict, setup::Dict)
	end
	
	if !isempty(CO2_CAPTURE_LIQUID)
		EP = co2_capture_liquid(EP::Model, inputs::Dict,setup::Dict)
	end

	return EP
end
