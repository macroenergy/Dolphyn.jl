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
    co2_discharge(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the production decision variable  representing carbon injected into the network by resource $k$ by at time period $t$.

This module additionally defines contributions to the objective function from variable costs of capture (variable O&M plus fuel cost) from all resources over all time periods.

"""
function co2_investment(EP::Model, inputs::Dict, setup::Dict)

	println("Carbon Capture Investment Module")

    dfCO2Capture = inputs["dfCO2Capture"]

    # Define sets
	CO2_CAPTURE_NEW_CAP = inputs["CO2_CAPTURE_NEW_CAP"] 
    CO2_CAPTURE_COMMIT = inputs["CO2_CAPTURE_COMMIT"]
	CO2_RES_ALL = inputs["CO2_RES_ALL"]

	#Capacity of New CO2 Capture units (tonnes/hr)
	#For capture with unit commitment, this variable refers to the number of units, not capacity. 
	@variable(EP, vCO2CaptureNewCap[k in CO2_CAPTURE_NEW_CAP] >= 0)
	
	### Expressions ###
	# Cap_Size is set to 1 for all variables when unit UCommit == 0
	# When UCommit > 0, Cap_Size is set to 1 for all variables except those where THERM == 1
	@expression(EP, eCO2CaptureTotalCap[k in CO2_RES_ALL],
		if k in CO2_CAPTURE_NEW_CAP
			dfCO2Capture[!,:Cap_Size_tonne_p_hr][k] * EP[:vCO2CaptureNewCap][k]
		else
			EP[:vCO2CaptureNewCap][k]
		end
	)

	## Objective Function Expressions ##

	# Sum individual resource contributions to fixed costs to get total fixed costs
	#  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	#  ParameterScale = 0 --> objective function is in $
	if setup["ParameterScale"] == 1 
		# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
		# If resource is not eligible for new capacity, fixed costs are only O&M costs
		@expression(EP, eCO2CaptureCFix[k in CO2_RES_ALL],
			if k in CO2_CAPTURE_COMMIT
				1/ModelScalingFactor^2*(dfCO2Capture[!,:Inv_Cost_p_tonne_p_hr_yr][k] * dfCO2Capture[!,:Cap_Size_tonne_p_hr][k] * EP[:vCO2CaptureNewCap][k] + dfCO2Capture[!,:Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eCO2CaptureTotalCap[k])
			else
				1/ModelScalingFactor^2*(dfCO2Capture[!,:Inv_Cost_p_tonne_p_hr_yr][k] * EP[:vCO2CaptureNewCap][k] + dfCO2Capture[!,:Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eCO2CaptureTotalCap[k])
			end
		)
	else
		# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
		# If resource is not eligible for new capacity, fixed costs are only O&M costs
		@expression(EP, eCO2CaptureCFix[k in CO2_RES_ALL],
			if k in CO2_CAPTURE_COMMIT
				dfCO2Capture[!,:Inv_Cost_p_tonne_p_hr_yr][k] * dfCO2Capture[!,:Cap_Size_tonne_p_hr][k] * EP[:vCO2CaptureNewCap][k] + dfCO2Capture[!,:Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eCO2CaptureTotalCap[k]
			else
				dfCO2Capture[!,:Inv_Cost_p_tonne_p_hr_yr][k] * EP[:vCO2CaptureNewCap][k] + dfCO2Capture[!,:Fixed_OM_Cost_p_tonne_p_hr_yr][k] * eCO2CaptureTotalCap[k]
			end
		)
	end

	# # Sum individual resource contributions to fixed costs to get total fixed costs
	# #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	# #  ParameterScale = 0 --> objective function is in $
	if setup["ParameterScale"] == 1 
		@expression(EP, eTotalCO2CaptureCFix, sum(EP[:eCO2CaptureCFix][k]/(ModelScalingFactor)^2 for k in CO2_RES_ALL))
	else
	 	@expression(EP, eTotalCO2CaptureCFix, sum(EP[:eCO2CaptureCFix][k] for k in CO2_RES_ALL))
	end

	# Add term to objective function expression
	EP[:eObj] += eTotalCO2CaptureCFix

    return EP

end
