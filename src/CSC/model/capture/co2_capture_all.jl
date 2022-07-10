"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Generation Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Generation Public License for more details.
A complete copy of the GNU Generation Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	co2_capture_all(EP::Model, inputs::Dict, setup::Dict)

The co2 capture module creates decision variables, expressions, and constraints related to carbon capture infrastructure
- Investment and FOM cost expression, VOM cost expression, minimum and maximum capacity limits
"""

function co2_capture_all(EP::Model, inputs::Dict, setup::Dict)

	dfCO2Capture = inputs["dfCO2Capture"]

	# Define sets
	CO2_CAPTURE = inputs["CO2_CAPTURE"]

	T = inputs["T"]     # Number of time steps (hours)

	####Variables####
	# Define variables needed across both commit and no commit sets

	# Power required by carbon capture resource k (MW)
	@variable(EP, vPCO2[k in CO2_CAPTURE, t = 1:T] >= 0 )

	### Constratints ###

	## Constraints on new built capacity
	# Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap is >= Max_Cap and lead to infeasabilty
	@constraint(EP, cCO2CaptureMaxCap[k in intersect(dfCO2Capture[dfCO2Capture.Max_Cap_tonne_p_hr.>0,:R_ID], CO2_CAPTURE)],EP[:eCO2CaptureTotalCap][k] <= dfCO2Capture[!,:Max_Cap_tonne_p_hr][k])

	# Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap is <= Min_Cap and lead to infeasabilty
	@constraint(EP, cCO2CaptureMinCap[k in intersect(dfCO2Capture[dfCO2Capture.Min_Cap_tonne_p_hr.>0,:R_ID], CO2_CAPTURE)], EP[:eCO2CaptureTotalCap][k] >= dfCO2Capture[!,:Min_Cap_tonne_p_hr][k])

	return EP

end