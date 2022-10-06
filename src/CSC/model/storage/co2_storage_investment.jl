"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021, Massachusetts Institute of Technology and Peking University
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	co2_storage_investment(EP::Model, inputs::Dict, setup::Dict)

This module defines the  decision variable  representing charging and carbon components of hydrogen storage technologies.

"""
function co2_storage_investment(EP::Model, inputs::Dict, setup::Dict)

	println("CO2 Storage Investment Module")

	dfCO2Stor = inputs["dfCO2Stor"]

	CO2_STOR_ALL = inputs["CO2_STOR_ALL"] # Set of CO2 storage resources - all have asymmetric (separate) charge capacity components

	NEW_CAP_CO2_CHARGE = inputs["NEW_CAP_CO2_CHARGE"] # Set of asymmetric charge storage resources eligible for new charge capacity

    NEW_CAP_CO2_STORAGE = inputs["NEW_CAP_CO2_STORAGE"] # set of storage resource eligible for new carbon capacity investment

	### Variables ###

	## Storage capacity built for storage resources with independent charge power capacities (STOR=2)

	# New installed charge capacity of resource "y"
	@variable(EP, vCO2CAPCHARGE[y in NEW_CAP_CO2_CHARGE] >= 0)

	# New installed carbon capacity of resource "y"
	@variable(EP, vCO2CAPCARBON[y in NEW_CAP_CO2_STORAGE] >= 0)

	### Expressions ###
	# Total available charging capacity in tonnes/hour
	@expression(EP, eTotalCO2CapCharge[y in CO2_STOR_ALL], EP[:vCO2CAPCHARGE][y])


    # Total available carbon capacity in tonnes
	@expression(EP, eTotalCO2CapCarbon[y in CO2_STOR_ALL], EP[:vCO2CAPCARBON][y])

	## Objective Function Expressions ##

	# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new charge capacity, fixed costs are only O&M costs
	# Sum individual resource contributions to fixed costs to get total fixed costs
	#  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	#  ParameterScale = 0 --> objective function is in $
	if setup["ParameterScale"] ==1
        @expression(EP, eCFixCO2Charge[y in CO2_STOR_ALL], 1/ModelScalingFactor^2*(dfCO2Stor[!,:Inv_Cost_Charge_p_tonne_p_hr_yr][y]*vCO2CAPCHARGE[y] + dfCO2Stor[!,:Fixed_OM_Cost_Charge_p_tonne_p_hr_yr][y]*eTotalCO2CapCharge[y]))
    else
        @expression(EP, eCFixCO2Charge[y in CO2_STOR_ALL], dfCO2Stor[!,:Inv_Cost_Charge_p_tonne_p_hr_yr][y]*vCO2CAPCHARGE[y] + dfCO2Stor[!,:Fixed_OM_Cost_Charge_p_tonne_p_hr_yr][y]*eTotalCO2CapCharge[y])
    end

	# Sum individual resource contributions to fixed costs to get total fixed costs
	@expression(EP, eTotalCFixCO2Charge, sum(EP[:eCFixCO2Charge][y] for y in CO2_STOR_ALL))

	# Add term to objective function expression
	EP[:eObj] += eTotalCFixCO2Charge

    # Carbon capacity costs
	# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new carbon capacity, fixed costs are only O&M costs
	#  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	#  ParameterScale = 0 --> objective function is in $
	if setup["ParameterScale"]==1
		@expression(EP, eCFixCO2Carbon[y in CO2_STOR_ALL], 1/ModelScalingFactor^2*(dfCO2Stor[!,:Inv_Cost_Carbon_p_tonne_yr][y]*vCO2CAPCARBON[y] + dfCO2Stor[!,:Fixed_OM_Cost_Carbon_p_tonne_yr][y]*eTotalCO2CapCarbon[y]))
	else
		@expression(EP, eCFixCO2Carbon[y in CO2_STOR_ALL], dfCO2Stor[!,:Inv_Cost_Carbon_p_tonne_yr][y]*vCO2CAPCARBON[y] + dfCO2Stor[!,:Fixed_OM_Cost_Carbon_p_tonne_yr][y]*eTotalCO2CapCarbon[y])
	end

    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixCO2Carbon, sum(EP[:eCFixCO2Carbon][y] for y in CO2_STOR_ALL))

    # Add term to objective function expression
    EP[:eObj] += eTotalCFixCO2Carbon


	### Constratints ###

  	#Constraints on new built capacity

	# Constraint on maximum charge capacity (if applicable) [set input to -1 if no constraint on maximum charge capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Charge_Cap_MW is >= Max_Charge_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMaxCapCO2Charge[y in intersect(dfCO2Stor[!,:Max_Charge_Cap_tonne_p_hr].>0, CO2_STOR_ALL)], eTotalCO2CapCharge[y] <= dfCO2Stor[!,:Max_Charge_Cap_tonne_p_hr][y])

	# Constraint on minimum charge capacity (if applicable) [set input to -1 if no constraint on minimum charge capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Charge_Cap_MW is <= Min_Charge_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMinCapCO2Charge[y in intersect(dfCO2Stor[!,:Min_Charge_Cap_tonne_p_hr].>0, CO2_STOR_ALL)], eTotalCO2CapCharge[y] >= dfCO2Stor[!,:Min_Charge_Cap_tonne_p_hr][y])

	## Constraints on new built carbon capacity
	# Constraint on maximum carbon capacity (if applicable) [set input to -1 if no constraint on maximum carbon capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is >= Max_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMaxCapCO2Carbon[y in intersect(dfCO2Stor[dfCO2Stor.Max_Carbon_Cap_tonne.>0,:R_ID], CO2_STOR_ALL)], eTotalCO2CapCarbon[y] <= dfCO2Stor[!,:Max_Carbon_Cap_tonne][y])

	# Constraint on minimum carbon capacity (if applicable) [set input to -1 if no constraint on minimum carbon apacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MWh is <= Min_Cap_MWh and lead to infeasabilty
	@constraint(EP, cMinCapCO2Carbon[y in intersect(dfCO2Stor[dfCO2Stor.Min_Carbon_Cap_tonne.>0,:R_ID], CO2_STOR_ALL)], eTotalCO2CapCarbon[y] >= dfCO2Stor[!,:Min_Carbon_Cap_tonne][y])

	return EP
end
