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

	################## Adding values from CO2 Pipelines #####################
	CO2_P = inputs["CO2_P"] # Number of CO2 Pipelines
    CO2_Pipe_Map = inputs["CO2_Pipe_Map"] 

	#####################################################################################################################################
	##Variables
	#CO2 injected into geological sequestration from carbon storage resource k (tonnes of CO2/hr) in time t
	@variable(EP, vCO2_Injected[k=1:CO2_STOR_ALL, t = 1:T] >= 0 )

	@variable(EP, vCO2_Injected_transpose[t = 1:T, k = 1:CO2_STOR_ALL] >= 0)

	#Power required by carbon storage resource k (MW)
	@variable(EP, vPower_CO2_Storage[k=1:CO2_STOR_ALL, t = 1:T] >= 0 )


	############ Specifying values related to CO2 Pipelines ##############################
	@variable(EP, vCO2FlowIntoZone[p=1:CO2_P, t = 1:T, d = [1,-1]] >= 0) #positive pipeflow : This also incdicates inflow into a zone

	
	###############################################################################################################################

	#Power Balance
	# If ParameterScale = 1, power system operation/capacity modeled in GW, no need to scale as MW/ton = GW/kton 
	# If ParameterScale = 0, power system operation/capacity modeled in MW

	@expression(EP, ePower_Balance_CO2_Storage[t=1:T, z=1:Z],
	sum(EP[:vPower_CO2_Storage][k,t] for k in dfCO2Storage[dfCO2Storage[!,:Zone].==z,:][!,:R_ID]))

	#Add to power balance to take power away from generated
	EP[:ePowerBalance] += -ePower_Balance_CO2_Storage

	##For CO2 Policy constraint right hand side development - power consumption by zone and each time step
	EP[:eCSCNetpowerConsumptionByAll] += ePower_Balance_CO2_Storage

	#CO2 Balance expressions
	@expression(EP, eStored_Captured_CO2[t=1:T, z=1:Z],
	sum(EP[:vCO2_Injected][k,t] for k in dfCO2Storage[(dfCO2Storage[!,:Zone].==z),:R_ID]))

	#ADD TO CO2 BALANCE
	EP[:eCaptured_CO2_Balance] -= eStored_Captured_CO2

	##Storage
	#Amount of carbon injected into geological sequestration in zone z at time t
	@expression(EP, eCO2_Injected_per_zone[z=1:Z, t=1:T], sum(EP[:vCO2_Injected][k,t] for k in dfCO2Storage[(dfCO2Storage[!,:Zone].==z),:R_ID]))


	######## Testing transpose of co2 injected per zone ##############
	@expression(EP, eCO2_Injected_per_time_per_zone[t=1:T, z=1:Z], sum(EP[:vCO2_Injected_transpose][t,k] for k in dfCO2Storage[(dfCO2Storage[!,:Zone].==z),:R_ID]))

	#Amount of carbon injected into geological sequestration in zone z at time t
	@expression(EP, eCO2_Injected_per_year[k=1:CO2_STOR_ALL], sum(inputs["omega"][t]*EP[:vCO2_Injected][k,t] for t in 1:T))

	######## Adding Expression for CO2 entering into a particular site ##########

	@expression(EP, eCO2PipeFlowIntoZone[p = 1:CO2_P, t = 1:T, d = [-1, 1]], vCO2FlowIntoZone[p,t,d])

	@expression(EP, ePipeZoneTotalCO2InFlowOfCO2[t=1:T,z=1:Z],
        sum(eCO2PipeFlowIntoZone[p,t, CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] for p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
	
	EP[:ePipeZoneTotalCO2InFlowOfCO2] = ePipeZoneTotalCO2InFlowOfCO2

	###############################################################################################################################
	##Constraints
	#Power constraint
	@constraint(EP,cPower_Consumption_CO2_Storage[k=1:CO2_STOR_ALL, t = 1:T], EP[:vPower_CO2_Storage][k,t] == EP[:vCO2_Injected][k,t] * dfCO2Storage[!,:etaPCO2_MWh_per_tonne][k])

	#Include constraint of min storage operation

	#Max carbon injected into geological sequestration per resoruce type k
	@constraint(EP,cMax_CO2_Injected_per_type_per_year[k=1:CO2_STOR_ALL], EP[:eCO2_Injected_per_year][k] <= EP[:vCapacity_CO2_Storage_per_type][k])

	#Injection rate limit
	@constraint(EP,cMin_CO2_Injected_per_type_per_time[k=1:CO2_STOR_ALL, t=1:T], EP[:vCO2_Injected][k,t] >=  dfCO2Storage[!,:Max_injection_rate_tonne_per_hr][k] * dfCO2Storage[!,:CO2_Injection_Min_Output][k])
	@constraint(EP,cMax_CO2_Injected_per_type_per_time[k=1:CO2_STOR_ALL, t=1:T], EP[:vCO2_Injected][k,t] <=  dfCO2Storage[!,:Max_injection_rate_tonne_per_hr][k] * dfCO2Storage[!,:CO2_Injection_Max_Output][k])

	####### NOTE: Adding a new constraint that states that the maximum CO2 injected into geological sequestration in zone t at time t #########
	#eTotal_Flow_CO2_In = EP[:ePipeZoneCO2InFlowDemand_No_Loss]

	##### Testing taking a transpose of the dataframe #########

	df_pipeInflow = DataFrame(ePipeZoneTotalCO2InFlowOfCO2, :auto)
	df_pipeInflow = DataFrame(permutedims((df_pipeInflow)))

	for col in names(df_pipeInflow)
		df_pipeInflow[!, col] = convert(Vector{AffExpr}, df_pipeInflow[!, col])
	end

	ePipeZoneTotalCO2InFlowOfCO2 = Matrix(df_pipeInflow)

	EP[:ePipeZoneTotalCO2InFlowOfCO2] = ePipeZoneTotalCO2InFlowOfCO2
	
	##### NOTE: We might need take a transpose of this #####
	#@constraint(EP,cMax_Flow_in_per_time_per_type[t=1:T, k=1:CO2_STOR_ALL], EP[:ePipeZoneTotalCO2InFlowOfCO2][t,k] <=  dfCO2Storage[!,:Max_injection_rate_tonne_per_hr][k] * dfCO2Storage[!,:CO2_Injection_Max_Output][k])
	@constraint(EP,cMax_Flow_in_per_time_per_type[k=1:CO2_STOR_ALL, t=1:T], EP[:ePipeZoneTotalCO2InFlowOfCO2][k,t] <=  dfCO2Storage[!,:Max_injection_rate_tonne_per_hr][k] * dfCO2Storage[!,:CO2_Injection_Max_Output][k])

	

	###############################################################################################################################

	#Variable Cost of CO2 Storage (Injection)
	if setup["ParameterScale"] ==1
		@expression(EP, eVar_OM_CO2_Injection_per_type_per_time[k = 1:CO2_STOR_ALL,t = 1:T], 
		(inputs["omega"][t] * (dfCO2Storage[!,:Var_OM_Cost_per_tonne][k]/ModelScalingFactor) * vCO2_Injected[k,t]))
    else
		@expression(EP, eVar_OM_CO2_Injection_per_type_per_time[k = 1:CO2_STOR_ALL,t = 1:T], 
		(inputs["omega"][t] * dfCO2Storage[!,:Var_OM_Cost_per_tonne][k] * vCO2_Injected[k,t]))
	end

	@expression(EP, eVar_OM_CO2_Injection_per_time[t=1:T], sum(eVar_OM_CO2_Injection_per_type_per_time[k,t] for k in 1:CO2_STOR_ALL))
	@expression(EP, eVar_OM_CO2_Injection_per_type[k = 1:CO2_STOR_ALL], sum(eVar_OM_CO2_Injection_per_type_per_time[k,t] for t in 1:T))
	@expression(EP, eVar_OM_CO2_Injection_total, sum(eVar_OM_CO2_Injection_per_time[t] for t in 1:T))
	
	# Add total variable cost to the objective function
	EP[:eObj] += eVar_OM_CO2_Injection_total

	return EP

end




