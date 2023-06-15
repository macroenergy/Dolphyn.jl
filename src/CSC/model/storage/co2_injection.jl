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
    co2_injection(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

The co2_injection module creates decision variables, expressions, and constraints related to injecting the captured carbon into geological sequestration
"""

function co2_injection(EP::Model, inputs::Dict,setup::Dict)

	#Rename CO2Storage dataframe
	dfCO2Storage = inputs["dfCO2Storage"]
	CO2_STOR_ALL = inputs["CO2_STOR_ALL"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	#####################################################################################################################################
	##Variables
	#CO2 injected into geological sequestration from carbon injection resource k (tonnes of CO2/hr) in time t
	@variable(EP, vCO2_Injected[k=1:CO2_STOR_ALL, t = 1:T] >= 0 )

	#Power required by carbon injection resource k (MW)
	@variable(EP, vPower_CO2_Injection[k=1:CO2_STOR_ALL, t = 1:T] >= 0 )
	
	###############################################################################################################################

	#Power Balance
	# If ParameterScale = 1, power system operation/capacity modeled in GW, no need to scale as MW/ton = GW/kton 
	# If ParameterScale = 0, power system operation/capacity modeled in MW

	@expression(EP, ePower_Balance_CO2_Injection[t=1:T, z=1:Z],
	sum(EP[:vPower_CO2_Injection][k,t] for k in dfCO2Storage[dfCO2Storage[!,:Zone].==z,:][!,:R_ID]))

	#Add to power balance to take power away from generated
	EP[:ePowerBalance] += -ePower_Balance_CO2_Injection

	##For CO2 Policy constraint right hand side development - power consumption by zone and each time step
	EP[:eCSCNetpowerConsumptionByAll] += ePower_Balance_CO2_Injection

	#CO2 Balance expressions
	@expression(EP, eStored_Captured_CO2[t=1:T, z=1:Z],
	sum(EP[:vCO2_Injected][k,t] for k in dfCO2Storage[(dfCO2Storage[!,:Zone].==z),:R_ID]))

	#ADD TO CO2 BALANCE
	EP[:eCaptured_CO2_Balance] -= eStored_Captured_CO2

	##Storage
	#Amount of carbon injected into geological sequestration in zone z at time t
	@expression(EP, eCO2_Injected_per_zone[z=1:Z, t=1:T], sum(EP[:vCO2_Injected][k,t] for k in dfCO2Storage[(dfCO2Storage[!,:Zone].==z),:R_ID]))

	#Amount of carbon injected into geological sequestration in zone z at time t
	@expression(EP, eCO2_Injected_per_year[k=1:CO2_STOR_ALL], sum(inputs["omega"][t]*EP[:vCO2_Injected][k,t] for t in 1:T))

	###############################################################################################################################
	##Constraints
	#Power constraint
	@constraint(EP,cPower_Consumption_CO2_Injection[k=1:CO2_STOR_ALL, t = 1:T], EP[:vPower_CO2_Injection][k,t] == EP[:vCO2_Injected][k,t] * dfCO2Storage[!,:etaPCO2_MWh_per_tonne][k])

	#Include constraint of min injection operation
	@constraint(EP,cMin_CO2_Injected_per_type_per_time[k=1:CO2_STOR_ALL], EP[:eCO2_Injected_per_year][k] >= EP[:vCapacity_CO2_Injection_per_type][k] * dfCO2Storage[!,:CO2_Injection_Min_Output][k])

	#Max carbon injected into geological sequestration per resoruce type k at hour T
	@constraint(EP,cMax_CO2_Injected_per_type_per_time[k=1:CO2_STOR_ALL], EP[:eCO2_Injected_per_year][k] <= EP[:vCapacity_CO2_Injection_per_type][k] * dfCO2Storage[!,:CO2_Injection_Max_Output][k])

	###############################################################################################################################

	return EP

end




