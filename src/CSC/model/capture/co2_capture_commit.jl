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
	co2_capture_commit(EP::Model, inputs::Dict, setup::Dict)

The co2_capture_commit module creates decision variables, expressions, and constraints related to various hydrogen generation technologies with unit commitment constraints (e.g. natural gas reforming etc.)

Documentation to follow ******
"""
function co2_capture_commit(EP::Model, inputs::Dict, setup::Dict)

	println("Carbon Capture (Unit Commitment) Module")

	# Rename CO2Capture dataframe
	dfCO2Capture = inputs["dfCO2Capture"]
	CO2CaptureCommit = setup["CO2CaptureCommit"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
	CO2_CAPTURE_COMMIT = inputs["CO2_CAPTURE_COMMIT"]
	
	# Define start subperiods and interior subperiods
	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"]
    
	###Variables###
	# Commitment state variable
	@variable(EP, vCO2CaptureCommit[k in CO2_CAPTURE_COMMIT, t=1:T] >= 0)
	# Start up variable
	@variable(EP, vCO2CaptureStart[k in CO2_CAPTURE_COMMIT, t=1:T] >= 0)
	# Shutdown Variable
	@variable(EP, vCO2CaptureShut[k in CO2_CAPTURE_COMMIT, t=1:T] >= 0)

	###Expressions###

	#Objective function expressions
	# Startup costs of "generation" for resource "y" during hour "t"
	#  ParameterScale = 1 --> objective function is in million $
	#  ParameterScale = 0 --> objective function is in $
	if setup["ParameterScale"] == 1 
		@expression(EP, eCO2CaptureCStart[k in CO2_CAPTURE_COMMIT, t=1:T],(inputs["omega"][t]*inputs["C_CO2_Start"][k]*vCO2CaptureStart[k,t]/ModelScalingFactor^2))
	else
		@expression(EP, eCO2CaptureCStart[k in CO2_CAPTURE_COMMIT, t=1:T],(inputs["omega"][t]*inputs["C_CO2_Start"][k]*vCO2CaptureStart[k,t]))
	end

	@expression(EP, eTotalCO2CaptureCStartT[t=1:T], sum(eCO2CaptureCStart[k,t] for k in CO2_CAPTURE_COMMIT))
	@expression(EP, eTotalCO2CaptureCStart, sum(eTotalCO2CaptureCStartT[t] for t=1:T))

	EP[:eObj] += eTotalCO2CaptureCStart

	# CO2 Balance expressions
	@expression(EP, eCO2CaptureCommit[t=1:T, z=1:Z],
	sum(EP[:vCO2Capture][k,t] for k in intersect(CO2_CAPTURE_COMMIT, dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID])))

	EP[:eCO2Balance] += eCO2CaptureCommit

	# Power Balance
	@constraints(EP, begin
		[k in CO2_CAPTURE_COMMIT, t = 1:T], EP[:vPCO2][k,t] == EP[:vCO2Capture][k,t] * dfCO2Capture[!,:etaPCO2_MWh_p_tonne][k]
	end)
	
	# Power Consumption for CO2 Capture
	if setup["ParameterScale"] ==1
		@expression(EP, ePowerBalanceCO2CaptureCommit[t=1:T, z=1:Z],
		sum(EP[:vPCO2][k,t]/ModelScalingFactor for k in intersect(CO2_CAPTURE_COMMIT, dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID]))) 
	else
		@expression(EP, ePowerBalanceCO2CaptureCommit[t=1:T, z=1:Z],
		sum(EP[:vPCO2][k,t] for k in intersect(CO2_CAPTURE_COMMIT, dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID]))) 
	end

	EP[:ePowerBalance] += -ePowerBalanceCO2CaptureCommit

	## For CO2 Policy constraint right hand side development - power consumption by zone and each time step
	EP[:eCO2NetpowerConsumptionByAll] += ePowerBalanceCO2CaptureCommit

	### Constraints ###
	## Declaration of integer/binary variables
	if CO2CaptureCommit == 1 # Integer UC constraints
		for k in CO2_CAPTURE_COMMIT
			set_integer.(vCO2CaptureCommit[k,:])
			set_integer.(vCO2CaptureStart[k,:])
			set_integer.(vCO2CaptureShut[k,:])
            set_integer(EP[:vCO2CaptureNewCap][k])
		end
	end # END unit commitment configuration

	### Capacitated limits on unit commitment decision variables (Constraints #1-3)
	@constraints(EP, begin
		[k in CO2_CAPTURE_COMMIT, t=1:T], EP[:vCO2CaptureCommit][k,t] <= EP[:eCO2CaptureTotalCap][k]/dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]
		[k in CO2_CAPTURE_COMMIT, t=1:T], EP[:vCO2CaptureStart][k,t] <= EP[:eCO2CaptureTotalCap][k]/dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]
		[k in CO2_CAPTURE_COMMIT, t=1:T], EP[:vCO2CaptureShut][k,t] <= EP[:eCO2CaptureTotalCap][k]/dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]
	end)

	# Commitment state constraint linking startup and shutdown decisions (Constraint #4)
	@constraints(EP, begin
	# For Start Hours, links first time step with last time step in subperiod
	[k in CO2_CAPTURE_COMMIT, t in START_SUBPERIODS], EP[:vCO2CaptureCommit][k,t] == EP[:vCO2CaptureCommit][k,(t+hours_per_subperiod-1)] + EP[:vCO2CaptureStart][k,t] - EP[:vCO2CaptureShut][k,t]
	# For all other hours, links commitment state in hour t with commitment state in prior hour + sum of start up and shut down in current hour
	[k in CO2_CAPTURE_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vCO2CaptureCommit][k,t] == EP[:vCO2CaptureCommit][k,t-1] + EP[:vCO2CaptureStart][k,t] - EP[:vCO2CaptureShut][k,t]
	end)


	### Maximum ramp up and down between consecutive hours (Constraints #5-6)

	## For Start Hours
	# Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
	# rampup constraints
	@constraint(EP,[k in CO2_CAPTURE_COMMIT, t in START_SUBPERIODS],
	EP[:vCO2Capture][k,t]-EP[:vCO2Capture][k,(t+hours_per_subperiod-1)] <= dfCO2Capture[!,:Ramp_Up_Percentage][k] * dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]*(EP[:vCO2CaptureCommit][k,t]-EP[:vCO2CaptureStart][k,t])
	+ min(inputs["pCO2_Max"][k,t],max(dfCO2Capture[!,:CO2Capture_min_output][k],dfCO2Capture[!,:Ramp_Up_Percentage][k]))*dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]*EP[:vCO2CaptureStart][k,t]
	- dfCO2Capture[!,:CO2Capture_min_output][k] * dfCO2Capture[!,:Cap_Size_tonne_p_hr][k] * EP[:vCO2CaptureShut][k,t])

	# rampdown constraints
	@constraint(EP,[k in CO2_CAPTURE_COMMIT, t in START_SUBPERIODS],
	EP[:vCO2Capture][k,(t+hours_per_subperiod-1)]-EP[:vCO2Capture][k,t] <= dfCO2Capture[!,:Ramp_Down_Percentage][k]*dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]*(EP[:vCO2CaptureCommit][k,t]-EP[:vCO2CaptureStart][k,t])
	- dfCO2Capture[!,:CO2Capture_min_output][k]*dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]*EP[:vCO2CaptureStart][k,t]
	+ min(inputs["pCO2_Max"][k,t],max(dfCO2Capture[!,:CO2Capture_min_output][k],dfCO2Capture[!,:Ramp_Down_Percentage][k]))*dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]*EP[:vCO2CaptureShut][k,t])

	## For Interior Hours
	# rampup constraints
	@constraint(EP,[k in CO2_CAPTURE_COMMIT, t in INTERIOR_SUBPERIODS],
		EP[:vCO2Capture][k,t]-EP[:vCO2Capture][k,t-1] <= dfCO2Capture[!,:Ramp_Up_Percentage][k]*dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]*(EP[:vCO2CaptureCommit][k,t]-EP[:vCO2CaptureStart][k,t])
			+ min(inputs["pCO2_Max"][k,t],max(dfCO2Capture[!,:CO2Capture_min_output][k],dfCO2Capture[!,:Ramp_Up_Percentage][k]))*dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]*EP[:vCO2CaptureStart][k,t]
			-dfCO2Capture[!,:CO2Capture_min_output][k]*dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]*EP[:vCO2CaptureShut][k,t])

	# rampdown constraints
	@constraint(EP,[k in CO2_CAPTURE_COMMIT, t in INTERIOR_SUBPERIODS],
	EP[:vCO2Capture][k,t-1]-EP[:vCO2Capture][k,t] <= dfCO2Capture[!,:Ramp_Down_Percentage][k]*dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]*(EP[:vCO2CaptureCommit][k,t]-EP[:vCO2CaptureStart][k,t])
	-dfCO2Capture[!,:CO2Capture_min_output][k]*dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]*EP[:vCO2CaptureStart][k,t]
	+min(inputs["pCO2_Max"][k,t],max(dfCO2Capture[!,:CO2Capture_min_output][k],dfCO2Capture[!,:Ramp_Down_Percentage][k]))*dfCO2Capture[!,:Cap_Size_tonne_p_hr][k]*EP[:vCO2CaptureShut][k,t])

	@constraints(EP, begin
	# Minimum stable generated per technology "k" at hour "t" > = Min stable output level
	[k in CO2_CAPTURE_COMMIT, t=1:T], EP[:vCO2Capture][k,t] >= dfCO2Capture[!,:Cap_Size_tonne_p_hr][k] *dfCO2Capture[!,:CO2Capture_min_output][k]* EP[:vCO2CaptureCommit][k,t]
	# Maximum power generated per technology "k" at hour "t" < Max power
	[k in CO2_CAPTURE_COMMIT, t=1:T], EP[:vCO2Capture][k,t] <= dfCO2Capture[!,:Cap_Size_tonne_p_hr][k] * EP[:vCO2CaptureCommit][k,t] * inputs["pCO2_Max"][k,t]
	end)


	### Minimum up and down times (Constraints #9-10)
	for y in CO2_CAPTURE_COMMIT

		## up time
		Up_Time = Int(floor(dfCO2Capture[!,:Up_Time][y]))
		Up_Time_HOURS = [] # Set of hours in the summation term of the maximum up time constraint for the first subperiod of each representative period
		for s in START_SUBPERIODS
			Up_Time_HOURS = union(Up_Time_HOURS, (s+1):(s+Up_Time-1))
		end

		@constraints(EP, begin
			# cUpTimeInterior: Constraint looks back over last n hours, where n = dfCO2Capture[!,:Up_Time][y]
			[t in setdiff(INTERIOR_SUBPERIODS,Up_Time_HOURS)], EP[:vCO2CaptureCommit][y,t] >= sum(EP[:vCO2CaptureStart][y,e] for e=(t-dfCO2Capture[!,:Up_Time][y]):t)

			# cUpTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
			# cUpTimeWrap constraint equivalant to: sum(EP[:vCO2CaptureStart][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vCO2CaptureStart][y,e] for e=(hours_per_subperiod_max-(dfCO2Capture[!,:Up_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
			[t in Up_Time_HOURS], EP[:vCO2CaptureCommit][y,t] >= sum(EP[:vCO2CaptureStart][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vCO2CaptureStart][y,e] for e=((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfCO2Capture[!,:Up_Time][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod)))

			# cUpTimeStart:
			# NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
			[t in START_SUBPERIODS], EP[:vCO2CaptureCommit][y,t] >= EP[:vCO2CaptureStart][y,t]+sum(EP[:vCO2CaptureStart][y,e] for e=((t+hours_per_subperiod-1)-(dfCO2Capture[!,:Up_Time][y]-1)):(t+hours_per_subperiod-1))
		end)

		## down time
		Down_Time = Int(floor(dfCO2Capture[!,:Down_Time][y]))
		Down_Time_HOURS = [] # Set of hours in the summation term of the maximum down time constraint for the first subperiod of each representative period
		for s in START_SUBPERIODS
			Down_Time_HOURS = union(Down_Time_HOURS, (s+1):(s+Down_Time-1))
		end

		# Constraint looks back over last n hours, where n = dfCO2Capture[!,:Down_Time][y]
		# TODO: Replace LHS of constraints in this block with eNumPlantsOffline[y,t]
		@constraints(EP, begin
			# cDownTimeInterior: Constraint looks back over last n hours, where n = inputs["pDMS_Time"][y]
			[t in setdiff(INTERIOR_SUBPERIODS,Down_Time_HOURS)], EP[:eCO2CaptureTotalCap][y]/dfCO2Capture[!,:Cap_Size_tonne_p_hr][y]-EP[:vCO2CaptureCommit][y,t] >= sum(EP[:vCO2CaptureShut][y,e] for e=(t-dfCO2Capture[!,:Down_Time][y]):t)

			# cDownTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
			# cDownTimeWrap constraint equivalant to: EP[:eCO2CaptureTotalCap][y]/dfCO2Capture[!,:Cap_Size_tonne_p_hr][y]-EP[:vCO2CaptureCommit][y,t] >= sum(EP[:vCO2CaptureShut][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vCO2CaptureShut][y,e] for e=(hours_per_subperiod_max-(dfCO2Capture[!,:Down_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
			[t in Down_Time_HOURS], EP[:eCO2CaptureTotalCap][y]/dfCO2Capture[!,:Cap_Size_tonne_p_hr][y]-EP[:vCO2CaptureCommit][y,t] >= sum(EP[:vCO2CaptureShut][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vCO2CaptureShut][y,e] for e=((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfCO2Capture[!,:Down_Time][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod)))

			# cDownTimeStart:
			# NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
			[t in START_SUBPERIODS], EP[:eCO2CaptureTotalCap][y]/dfCO2Capture[!,:Cap_Size_tonne_p_hr][y]-EP[:vCO2CaptureCommit][y,t]  >= EP[:vCO2CaptureShut][y,t]+sum(EP[:vCO2CaptureShut][y,e] for e=((t+hours_per_subperiod-1)-(dfCO2Capture[!,:Down_Time][y]-1)):(t+hours_per_subperiod-1))
		end)
	end

	return EP

end