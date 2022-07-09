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
    co2_capture_no_commit(EP::Model, inputs::Dict, setup::Dict)

The co2_capture_no_commit module creates decision variables, expressions, and constraints related to various carbon capture technologies (electrolyzers, natural gas reforming etc.) without unit commitment constraints

"""

function co2_capture_no_commit(EP::Model, inputs::Dict, setup::Dict)

	println("Carbon Capture (Unit Commitment) Module")

	# Rename CO2Capture dataframe
	dfCO2Capture = inputs["dfCO2Capture"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	H = inputs["CO2_CAPTURE"]		#NUmber of carbon capture units 
	
	CO2_CAPTURE_NO_COMMIT = inputs["CO2_CAPTURE_NO_COMMIT"]
	
	# Define start subperiods and interior subperiods
	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"]

	###Expressions###
	# CO2 Balance expressions
	@expression(EP, eCO2CaptureNoCommit[t=1:T, z=1:Z],
	sum(EP[:vCO2Capture][k,t] for k in intersect(CO2_CAPTURE_NO_COMMIT, dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID])))

	EP[:eCO2Balance] += eCO2CaptureNoCommit

	# Power Consumption for CO2 Capture
	if setup["ParameterScale"] == 1
		@expression(EP, ePowerBalanceCO2CaptureNoCommit[t=1:T, z=1:Z],
		sum(EP[:vPCO2][k,t]/ModelScalingFactor for k in intersect(CO2_CAPTURE_NO_COMMIT, dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID]))) 
	else
		@expression(EP, ePowerBalanceCO2CaptureNoCommit[t=1:T, z=1:Z],
		sum(EP[:vPCO2][k,t] for k in intersect(CO2_CAPTURE_NO_COMMIT, dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID]))) 
	end

	EP[:ePowerBalance] += -ePowerBalanceCO2CaptureNoCommit

	## For CO2 Policy constraint right hand side development - power consumption by zone and each time step
	EP[:eCO2NetpowerConsumptionByAll] += ePowerBalanceCO2CaptureNoCommit
	
	# Power and natural gas consumption associated with CO2 generation in each time step
	@constraints(EP, begin
		#Power Balance
		[k in CO2_CAPTURE_NO_COMMIT, t = 1:T], EP[:vPCO2][k,t] == EP[:vCO2Capture][k,t] * dfCO2Capture[!,:etaPCO2_MWh_p_tonne][k]
	end)

	@constraints(EP, begin
		# Maximum carbon capture per technology "k" at hour "t"
		[k in CO2_CAPTURE_NO_COMMIT, t=1:T], EP[:vCO2Capture][k,t] <= EP[:eCO2CaptureTotalCap][k]* inputs["pCO2_Max"][k,t]

		# Minimum carbon capture per technology "k" at hour "t"
		[k in CO2_CAPTURE_NO_COMMIT, t=1:T], EP[:vCO2Capture][k,t] >= EP[:eCO2CaptureTotalCap][k]* dfCO2Capture[!, :CO2Capture_min_output][k]
	end)

	# Ramping cosntraints 
	@constraints(EP, begin
		## Maximum ramp up between consecutive hours
		# Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
		# NOTE: We should make wrap-around a configurable option
		[k in CO2_CAPTURE_NO_COMMIT, t in START_SUBPERIODS], EP[:vCO2Capture][k,t]-EP[:vCO2Capture][k,(t + hours_per_subperiod-1)] <= dfCO2Capture[!,:Ramp_Up_Percentage][k] * EP[:eCO2CaptureTotalCap][k]

		# Interior Hours
		[k in CO2_CAPTURE_NO_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vCO2Capture][k,t]-EP[:vCO2Capture][k,t-1] <= dfCO2Capture[!,:Ramp_Up_Percentage][k]*EP[:eCO2CaptureTotalCap][k]

		## Maximum ramp down between consecutive hours
		# Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
		[k in CO2_CAPTURE_NO_COMMIT, t in START_SUBPERIODS], EP[:vCO2Capture][k,(t+hours_per_subperiod-1)] - EP[:vCO2Capture][k,t] <= dfCO2Capture[!,:Ramp_Down_Percentage][k] * EP[:eCO2CaptureTotalCap][k]

		# Interior Hours
		[k in CO2_CAPTURE_NO_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vCO2Capture][k,t-1] - EP[:vCO2Capture][k,t] <= dfCO2Capture[!,:Ramp_Down_Percentage][k] * EP[:eCO2CaptureTotalCap][k]
	
	end)

	return EP
	
end




