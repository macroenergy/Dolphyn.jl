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
co2_capture_uc(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

The co2_capture module creates decision variables, expressions, and constraints related to carbon capture technologies with unit commitment constraints

Documentation to follow ******
"""

function co2_capture_uc(EP::Model, inputs::Dict, setup::Dict)

	#Rename CO2Capture dataframe
	dfCO2Capture = inputs["dfCO2Capture"]

	if setup["ParameterScale"] ==1 
		DAC_Capacity_Min_Limit = dfCO2Capture[!,:Min_capacity_tonne_per_hr]/ModelScalingFactor # kton/h
		DAC_Capacity_Max_Limit = dfCO2Capture[!,:Max_capacity_tonne_per_hr]/ModelScalingFactor # kton/h
	else
		DAC_Capacity_Min_Limit = dfCO2Capture[!,:Min_capacity_tonne_per_hr] # t/h
		DAC_Capacity_Max_Limit = dfCO2Capture[!,:Max_capacity_tonne_per_hr] # t/h
	end

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
	CO2_CAPTURE_UC = inputs["CO2_CAPTURE_UC"]
	
	#Define start subperiods and interior subperiods
	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

	###############################################################################################################################
	##Start Cost
	#ParameterScale = 1 --> objective function is in million $/kton
	#ParameterScale = 0 --> objective function is in $/ton
	if setup["ParameterScale"] ==1 
		DAC_Start_Cost = dfCO2Capture[!,:Start_Cost_per_tonne_p_hr]/ModelScalingFactor
	else
		DAC_Start_Cost = dfCO2Capture[!,:Start_Cost_per_tonne_p_hr]
	end

	###############################################################################################################################
    ##Variables

	##New variables
	#Online state variable
	@variable(EP, vDAC_UC_Online[k in CO2_CAPTURE_UC, t=1:T], Bin)
	#Start up variable
	@variable(EP, vDAC_UC_Start[k in CO2_CAPTURE_UC, t=1:T], Bin)
	#Shut down variable
	@variable(EP, vDAC_UC_Shut[k in CO2_CAPTURE_UC, t=1:T], Bin)

	###############################################################################################################################
	##Expressions

	#CO2 Balance expressions
	@expression(EP, eDAC_CO2_Captured_UC[t=1:T, z=1:Z],
	sum(EP[:vDAC_CO2_Captured][k,t] for k in intersect(CO2_CAPTURE_UC, dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID])))

	#ADD TO CO2 BALANCE
	EP[:eCaptured_CO2_Balance] += eDAC_CO2_Captured_UC
	
	#Power Balance
	# IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW, , no need to scale as MW/ton = GW/kton 
	# IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of CO2 capture related power consumption
	@expression(EP, ePower_Balance_DAC_UC[t=1:T, z=1:Z],
	sum(EP[:vPower_DAC][k,t] for k in intersect(CO2_CAPTURE_UC, dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID]))) 		

	#Add to power balance to take power away from generated
	EP[:ePowerBalance] += -ePower_Balance_DAC_UC

	##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
	EP[:eCSCNetpowerConsumptionByAll] += ePower_Balance_DAC_UC

	#Startup costs for resource "k" during hour "t"
	@expression(EP, eStartup_Cost_DAC_per_type_per_time[k in CO2_CAPTURE_UC, t=1:T], (inputs["omega"][t] * DAC_Start_Cost[k] * EP[:vDAC_UC_Start][k,t]))
	@expression(EP,eTotal_Startup_Cost_DAC_per_type[k in CO2_CAPTURE_UC], sum(EP[:eStartup_Cost_DAC_per_type_per_time][k,t] for t in 1:T))
	@expression(EP,eTotal_Startup_Cost_DAC_per_time[t=1:T], sum(EP[:eStartup_Cost_DAC_per_type_per_time][k,t] for k in CO2_CAPTURE_UC))
	@expression(EP,eTotal_Startup_Cost_DAC, sum(EP[:eTotal_Startup_Cost_DAC_per_time][t] for t=1:T))

	#Add term to objective function expression
	EP[:eObj] += eTotal_Startup_Cost_DAC

	###############################################################################################################################
	##Constraints

	#Power constraint
	@constraint(EP,cPower_Consumption_DAC_UC[k in CO2_CAPTURE_UC, t = 1:T], EP[:vPower_DAC][k,t] == EP[:vDAC_CO2_Captured][k,t] * dfCO2Capture[!,:etaPCO2_MWh_per_tonne][k])

	#Commitment state constraint linking startup and shudown decisions for start and interior time points
	@constraint(EP,cDAC_Commitment_Start[k in CO2_CAPTURE_UC, t in START_SUBPERIODS], EP[:vDAC_UC_Online][k,t] == EP[:vDAC_UC_Online][k,(t+hours_per_subperiod-1)] + EP[:vDAC_UC_Start][k,t] - EP[:vDAC_UC_Shut][k,t])
	@constraint(EP,cDAC_Commitment_Interior[k in CO2_CAPTURE_UC, t in INTERIOR_SUBPERIODS], EP[:vDAC_UC_Online][k,t] == EP[:vDAC_UC_Online][k,t-1] + EP[:vDAC_UC_Start][k,t] - EP[:vDAC_UC_Shut][k,t])

	##Rampup and down constraints for start and interior time points
	#Up for start time
	@constraint(EP,cMax_Rampup_Start_DAC_UC[k in CO2_CAPTURE_UC, t in START_SUBPERIODS],
	EP[:vDAC_CO2_Captured][k,t] - EP[:vDAC_CO2_Captured][k,(t+hours_per_subperiod-1)]
	<= dfCO2Capture[!,:Ramp_Up_Percentage][k] * EP[:vCapacity_DAC_per_type][k] * (EP[:vDAC_UC_Online][k,t] - EP[:vDAC_UC_Start][k,t])
	+ min(inputs["CO2_Capture_Max_Output"][k,t],max(dfCO2Capture[!,:CO2_Capture_Min_Output][k],dfCO2Capture[!,:Ramp_Up_Percentage][k])) * EP[:vCapacity_DAC_per_type][k] * EP[:vDAC_UC_Start][k,t]
	- dfCO2Capture[!,:CO2_Capture_Min_Output][k] * EP[:vCapacity_DAC_per_type][k] * EP[:vDAC_UC_Shut][k,t])

	#Up for interior time
	@constraint(EP,cMax_Rampup_Interior_DAC_UC[k in CO2_CAPTURE_UC, t in INTERIOR_SUBPERIODS],
	EP[:vDAC_CO2_Captured][k,t] - EP[:vDAC_CO2_Captured][k,t-1]
	<= dfCO2Capture[!,:Ramp_Up_Percentage][k] * EP[:vCapacity_DAC_per_type][k] * (EP[:vDAC_UC_Online][k,t] - EP[:vDAC_UC_Start][k,t])
	+ min(inputs["CO2_Capture_Max_Output"][k,t],max(dfCO2Capture[!,:CO2_Capture_Min_Output][k],dfCO2Capture[!,:Ramp_Up_Percentage][k])) * EP[:vCapacity_DAC_per_type][k] * EP[:vDAC_UC_Start][k,t]
	- dfCO2Capture[!,:CO2_Capture_Min_Output][k] * EP[:vCapacity_DAC_per_type][k] * EP[:vDAC_UC_Shut][k,t])

	#Down for start time
	@constraint(EP,cMax_Rampdown_Start_DAC_UC[k in CO2_CAPTURE_UC, t in START_SUBPERIODS],
	EP[:vDAC_CO2_Captured][k,(t+hours_per_subperiod-1)] - EP[:vDAC_CO2_Captured][k,t]
	<= dfCO2Capture[!,:Ramp_Down_Percentage][k] * EP[:vCapacity_DAC_per_type][k] * (EP[:vDAC_UC_Online][k,t] - EP[:vDAC_UC_Start][k,t])
	+ min(inputs["CO2_Capture_Max_Output"][k,t],max(dfCO2Capture[!,:CO2_Capture_Min_Output][k],dfCO2Capture[!,:Ramp_Down_Percentage][k])) * EP[:vCapacity_DAC_per_type][k] * EP[:vDAC_UC_Shut][k,t]
	- dfCO2Capture[!,:CO2_Capture_Min_Output][k] * EP[:vCapacity_DAC_per_type][k] * EP[:vDAC_UC_Start][k,t])

	#Down for interior time
	@constraint(EP,cMax_Rampdown_Interior_DAC_UC[k in CO2_CAPTURE_UC, t in INTERIOR_SUBPERIODS],
	EP[:vDAC_CO2_Captured][k,t-1] - EP[:vDAC_CO2_Captured][k,t]
	<= dfCO2Capture[!,:Ramp_Down_Percentage][k] * EP[:vCapacity_DAC_per_type][k] * (EP[:vDAC_UC_Online][k,t] - EP[:vDAC_UC_Start][k,t])
	+ min(inputs["CO2_Capture_Max_Output"][k,t],max(dfCO2Capture[!,:CO2_Capture_Min_Output][k],dfCO2Capture[!,:Ramp_Down_Percentage][k])) * EP[:vCapacity_DAC_per_type][k] * EP[:vDAC_UC_Shut][k,t]
	- dfCO2Capture[!,:CO2_Capture_Min_Output][k] * EP[:vCapacity_DAC_per_type][k] * EP[:vDAC_UC_Start][k,t])

	##Min start and shut time constraints
	#Up time
	p = hours_per_subperiod
	Up_Time = zeros(Int,nrow(dfCO2Capture))
	Up_Time[CO2_CAPTURE_UC] .= Int.(floor.(dfCO2Capture[CO2_CAPTURE_UC,:Up_Time]))
	@constraint(EP,cUp_Time_DAC_UC[k in CO2_CAPTURE_UC, t in 1:T],
	EP[:vDAC_UC_Online][k,t] >= sum(EP[:vDAC_UC_Start][k, hoursbefore_DAC(p,t,0:(Up_Time[k]-1))]))

	#Down time
	Down_Time = zeros(Int,nrow(dfCO2Capture))
	Down_Time[CO2_CAPTURE_UC] .= Int.(floor.(dfCO2Capture[CO2_CAPTURE_UC,:Down_Time]))
	@constraint(EP,cDown_Time_DAC_UC[k in CO2_CAPTURE_UC, t in 1:T],
	(1 - EP[:vDAC_UC_Online][k,t]) >= sum(EP[:vDAC_UC_Shut][k, hoursbefore_DAC(p,t,0:(Down_Time[k]-1))]))

	#Dummy capacity min and max
	@constraint(EP,cMin_CO2_Captured_DAC_UC_per_type_per_time[k in CO2_CAPTURE_UC, t = 1:T],
	EP[:vDAC_CO2_Captured][k,t] >= EP[:vDummy_Capacity_DAC_per_type][k,t]  * dfCO2Capture[!,:CO2_Capture_Min_Output][k])

	@constraint(EP,cMax_CO2_Captured_DAC_UC_per_type_per_time[k in CO2_CAPTURE_UC, t = 1:T],
	EP[:vDAC_CO2_Captured][k,t] <= EP[:vDummy_Capacity_DAC_per_type][k,t] * inputs["CO2_Capture_Max_Output"][k,t])
		
	#Standard Linearization formulation
	#Eq 1 min
	@constraint(EP,cStan_Lin_1_Min[k in CO2_CAPTURE_UC, t = 1:T],
	EP[:vDummy_Capacity_DAC_per_type][k,t] >= DAC_Capacity_Min_Limit[k] * EP[:vDAC_UC_Online][k,t])

	#Eq 1 max
	@constraint(EP,cStan_Lin_1_Max[k in CO2_CAPTURE_UC, t = 1:T],
	EP[:vDummy_Capacity_DAC_per_type][k,t] <= DAC_Capacity_Max_Limit[k] * EP[:vDAC_UC_Online][k,t])

	#Eq 2 min
	@constraint(EP,cStan_Lin_2_Min[k in CO2_CAPTURE_UC, t = 1:T],
	EP[:vDummy_Capacity_DAC_per_type][k,t] >= EP[:vCapacity_DAC_per_type][k] - (1 - EP[:vDAC_UC_Online][k,t]) * DAC_Capacity_Max_Limit[k])

	#Eq 2 max
	@constraint(EP,cStan_Lin_2_Max[k in CO2_CAPTURE_UC, t = 1:T],
	EP[:vDummy_Capacity_DAC_per_type][k,t] <= EP[:vCapacity_DAC_per_type][k] - (1 - EP[:vDAC_UC_Online][k,t]) * DAC_Capacity_Min_Limit[k])

	return EP

end


#Calculate hoursbefore_DAC
#Time index b hours before index t where t=1 is separated into distinct periods of length p
#Account for starting, interior, and wrapping
#Example p = 10
#1h before t=1 is t=10
#1h before t=10 is t=9
#1h before t=11 is t=20
function hoursbefore_DAC(p::Int,t::Int,b::UnitRange{Int})::Vector{Int}
	period = div(t-1,p)
	return period*p.+mod1.(t.-b,p)
end