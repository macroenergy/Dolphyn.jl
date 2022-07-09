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

The co2_capture module creates decision variables, expressions, and constraints related to various carbon capture technologies (electrolyzers, natural gas reforming etc.)

This module uses the following 'helper' functions in separate files: ```co2_capture_commit()``` for resources subject to unit commitment decisions and constraints (if any) and ```co2_capture_no_commit()``` for resources not subject to unit commitment (if any).
"""
function co2_capture(EP::Model, inputs::Dict, setup::Dict)

	if !isempty(inputs["CO2_CAPTURE"])
	# expressions, variables and constraints common to all types of carbon capture technologies
		EP = co2_capture_all(EP::Model, inputs::Dict, setup::Dict)
	end

    CO2_CAPTURE_COMMIT = inputs["CO2_CAPTURE_COMMIT"]
	CO2_CAPTURE_NO_COMMIT = inputs["CO2_CAPTURE_NO_COMMIT"]
	dfCO2Capture = inputs["dfCO2Capture"]  # Input CO2 capture and storage data
	Z = inputs["Z"]  # Model demand zones - assumed to be same for CO2, H2 and electricity
	T = inputs["T"]	 # Model operating time steps

	if !isempty(CO2_CAPTURE_COMMIT)
		EP = co2_capture_commit(EP::Model, inputs::Dict, setup::Dict)
	end

	if !isempty(CO2_CAPTURE_NO_COMMIT)
		EP = co2_capture_no_commit(EP::Model, inputs::Dict,setup::Dict)
	end

	## CO2 Capture by zone and each time step
	@expression(EP, eCO2CaptureByZone[z=1:Z, t=1:T], # the unit is tonne/hour
		sum(EP[:vCO2Capture][y,t] for y in intersect(inputs["CO2_CAPTURE"], dfCO2Capture[dfCO2Capture[!,:Zone].==z,:R_ID]))
	)

	return EP
end
