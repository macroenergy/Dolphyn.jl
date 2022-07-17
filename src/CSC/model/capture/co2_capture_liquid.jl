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

The co2_capture module creates decision variables, expressions, and constraints related to various carbon capture technologies (electrolyzers, natural gas reforming etc.) without unit commitment constraints

"""

function co2_capture_liquid(EP::Model, inputs::Dict,setup::Dict)

	#Rename CO2Capture dataframe
	dfCO2Capture = inputs["dfCO2Capture"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
	CO2_CAPTURE_LIQUID = inputs["CO2_CAPTURE_LIQUID"]
	
	#Define start subperiods and interior subperiods
	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod


	###############################################################################################################################
	##Expressions

	#CO2 Balance expressions
	@expression(EP, eDAC_CO2_Captured_Liquid[t=1:T, z=1:Z],
	sum(EP[:vDAC_CO2_Captured][k,t] for k in intersect(CO2_CAPTURE_LIQUID, dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID])))

	#ADD TO CO2 BALANCE
	EP[:eCaptured_CO2_Balance] += eDAC_CO2_Captured_Liquid

	#Power Balance
	if setup["ParameterScale"] == 1 # If ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
		@expression(EP, ePower_Balance_DAC_Liquid[t=1:T, z=1:Z],
		sum(EP[:vPower_DAC][k,t]/ModelScalingFactor for k in intersect(CO2_CAPTURE_LIQUID, dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID])))
		
	else # If ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of CO2 related power consumption
		@expression(EP, ePower_Balance_DAC_Liquid[t=1:T, z=1:Z],
		sum(EP[:vPower_DAC][k,t] for k in intersect(CO2_CAPTURE_LIQUID, dfCO2Capture[dfCO2Capture[!,:Zone].==z,:][!,:R_ID])))
	end

	#Add to power balance to take power away from generated
	EP[:ePowerBalance] += -ePower_Balance_DAC_Liquid

	##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
	EP[:eDACNetpowerConsumptionByAll] += ePower_Balance_DAC_Liquid

	###############################################################################################################################
	##Constraints
	#Power constraint
	@constraint(EP,cPower_Consumption_DAC_Liquid[k in CO2_CAPTURE_LIQUID, t = 1:T], EP[:vPower_DAC][k,t] == EP[:vDAC_CO2_Captured][k,t] * dfCO2Capture[!,:etaPCO2_MWh_p_tonne][k])

	#Include constraint of min capture operation
	@constraint(EP,cMin_CO2_Captured_DAC_Liquid_per_type_per_time[k in CO2_CAPTURE_LIQUID, t=1:T], EP[:vDAC_CO2_Captured][k,t] >= EP[:vCapacity_DAC_per_type][k] * dfCO2Capture[!,:CO2_Capture_Min_Output][k])

	#Max carbon capture per resoruce type k at hour T
	@constraint(EP,cMax_CO2_Captured_DAC_Liquid_per_type_per_time[k in CO2_CAPTURE_LIQUID, t=1:T], EP[:vDAC_CO2_Captured][k,t] <= EP[:vCapacity_DAC_per_type][k] * inputs["CO2_Capture_Max_Output"][k,t] )


	#Define start subperiods and interior subperiods

	@constraint(EP, cMax_Rampup_Start_DAC_Liquid[k in CO2_CAPTURE_LIQUID, t in START_SUBPERIODS], (EP[:vDAC_CO2_Captured][k,t] - EP[:vDAC_CO2_Captured][k,(t + hours_per_subperiod-1)]) <= dfCO2Capture[!,:Ramp_Up_Percentage][k] * EP[:vCapacity_DAC_per_type][k])

	@constraint(EP, cMax_Rampup_Interior_DAC_Liquid[k in CO2_CAPTURE_LIQUID, t in INTERIOR_SUBPERIODS], (EP[:vDAC_CO2_Captured][k,t] - EP[:vDAC_CO2_Captured][k,t-1]) <= dfCO2Capture[!,:Ramp_Up_Percentage][k] * EP[:vCapacity_DAC_per_type][k])

	@constraint(EP, cMax_Rampdown_Start_DAC_Liquid[k in CO2_CAPTURE_LIQUID, t in START_SUBPERIODS], (EP[:vDAC_CO2_Captured][k,(t + hours_per_subperiod-1)] - EP[:vDAC_CO2_Captured][k,t]) <= dfCO2Capture[!,:Ramp_Down_Percentage][k] * EP[:vCapacity_DAC_per_type][k])

	@constraint(EP, cMax_Rampdown_Interior_DAC_Liquid[k in CO2_CAPTURE_LIQUID, t in INTERIOR_SUBPERIODS], (EP[:vDAC_CO2_Captured][k,t-1] - EP[:vDAC_CO2_Captured][k,t]) <= dfCO2Capture[!,:Ramp_Down_Percentage][k] * EP[:vCapacity_DAC_per_type][k])

	return EP

end



