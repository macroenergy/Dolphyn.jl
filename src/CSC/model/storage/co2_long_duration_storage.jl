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
	co2_long_duration_storage(EP::Model, inputs::Dict)

This module defines the decision variables related to carbon stroage when involing long duration storage process.

"""

function co2_long_duration_storage(EP::Model, inputs::Dict)

	println("Carbon Long Duration Storage Module")

	dfCO2Stor = inputs["dfCO2Stor"]

	REP_PERIOD = inputs["REP_PERIOD"]     # Number of representative periods

	CO2_STOR_LONG_DURATION = inputs["CO2_STOR_LONG_DURATION"]
	START_SUBPERIODS = inputs["START_SUBPERIODS"]

	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

	dfPeriodMap = inputs["Period_Map"] # Dataframe that maps modeled periods to representative periods
	NPeriods = size(inputs["Period_Map"])[1] # Number of modeled periods

	MODELED_PERIODS_INDEX = 1:NPeriods
	REP_PERIODS_INDEX = MODELED_PERIODS_INDEX[dfPeriodMap[!,:Rep_Period] .== MODELED_PERIODS_INDEX]

	### Variables ###

	# Variables to define inter-period carbon transferred between modeled periods

	# State of charge of CO2 storage at beginning of each modeled period n
	@variable(EP, vCO2SOCw[y in STOR_LONG_DURATION, n in MODELED_PERIODS_INDEX] >= 0)

	# Build up in storage inventory over each representative period w
	# Build up inventory can be positive or negative
	@variable(EP, vdCO2SOC[y in STOR_LONG_DURATION, w=1:REP_PERIOD])

	### Constraints ###

	# Links last time step with first time step, ensuring position in hour 1 is within eligible change from final hour position
	# Modified initial state of storage for long-duration storage - initialize wth value carried over from last period
	# Alternative to cSoCBalStart constraint which is included when not modeling operations wrapping and long duration storage
	# Note: tw_min = hours_per_subperiod*(w-1)+1; tw_max = hours_per_subperiod*w
	@constraint(EP, cCO2SoCBalLongDurationStorageStart[w=1:REP_PERIOD, y in CO2_STOR_LONG_DURATION],
				    EP[:vCO2S][y,hours_per_subperiod*(w-1)+1] == (EP[:vCO2S][y,hours_per_subperiod*w]-vdCO2SOC[y,w])
					+(dfCO2Stor[!,:CO2Stor_eff_charge][y]*EP[:vCO2CHARGE_STOR][y,hours_per_subperiod*(w-1)+1]))
					#-dfCO2Stor[!,:CO2Stor_self_discharge_rate_p_hour][y]*(EP[:vCO2S][y,hours_per_subperiod*w]-vdCO2SOC[y,w])

	# Storage at beginning of period w = storage at beginning of period w-1 + storage built up in period w (after n representative periods)
	## Multiply storage build up term from prior period with corresponding weight
	@constraint(EP, cCO2SoCBalLongDurationStorageInterior[y in CO2_STOR_LONG_DURATION, r in MODELED_PERIODS_INDEX[1:(end-1)]],
					vCO2SOCw[y,r+1] == vCO2SOCw[y,r] + vdCO2SOC[y,dfPeriodMap[!,:Rep_Period_Index][r]])

	## Last period is linked to first period
	@constraint(EP, cCO2SoCBalLongDurationStorageEnd[y in CO2_STOR_LONG_DURATION, r in MODELED_PERIODS_INDEX[end]],
					vCO2SOCw[y,1] == vCO2SOCw[y,r] + vdCO2SOC[y,dfPeriodMap[!,:Rep_Period_Index][r]])

	# Storage at beginning of each modeled period cannot exceed installed carbon capacity
	@constraint(EP, cCO2SoCBalLongDurationStorageUpper[y in CO2_STOR_LONG_DURATION, r in MODELED_PERIODS_INDEX],
					vCO2SOCw[y,r] <= EP[:eTotalCO2CapCarbon][y])

	# Initial storage level for representative periods must also adhere to sub-period storage inventory balance
	# Initial storage = Final storage - change in storage inventory across representative period
	@constraint(EP, cCO2SoCBalLongDurationStorageSub[y in CO2_STOR_LONG_DURATION, r in REP_PERIODS_INDEX],
					vCO2SOCw[y,r] == EP[:vCO2S][y,hours_per_subperiod*dfPeriodMap[!,:Rep_Period_Index][r]] - vdCO2SOC[y,dfPeriodMap[!,:Rep_Period_Index][r]])

	return EP
end
