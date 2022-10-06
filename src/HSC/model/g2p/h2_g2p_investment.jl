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
    h2_discharge(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the production decision variable  representing hydrogen injected into the network by resource $y$ by at time period $t$.

This module additionally defines contributions to the objective function from variable costs of generation (variable O&M plus fuel cost) from all resources over all time periods.

"""
function h2_g2p_investment(EP::Model, inputs::Dict, setup::Dict)

    dfH2G2P = inputs["dfH2G2P"]

    #Define sets
	H2_G2P_NEW_CAP = inputs["H2_G2P_NEW_CAP"]
	H2_G2P_RET_CAP = inputs["H2_G2P_RET_CAP"]
    H2_G2P_COMMIT = inputs["H2_G2P_COMMIT"]

	#NOT SURE ABOUT THIS
	H =inputs["H2_G2P_ALL"]


	#Capacity of New H2 G2P units (MW)
	#For G2P with unit commitment, this variable refers to the number of units, not capacity.
	@variable(EP, vH2G2PNewCap[k in H2_G2P_NEW_CAP] >= 0)
	#Capacity of Retired H2 G2P units built (MW)
    #For generation with unit commitment, this variable refers to the number of units, not capacity.
	@variable(EP, vH2G2PRetCap[k in H2_G2P_RET_CAP] >= 0)

	### Expressions ###
	# Cap_Size is set to 1 for all variables when unit UCommit == 0
	# When UCommit > 0, Cap_Size is set to 1 for all variables except those where THERM == 1
	@expression(EP, eH2G2PTotalCap[k in 1:H],
		if k in intersect(H2_G2P_NEW_CAP, H2_G2P_RET_CAP) # Resources eligible for new capacity and retirements
			if k in H2_G2P_COMMIT
				dfH2G2P[!,:Existing_Cap_MW][k] + dfH2G2P[!,:Cap_Size_MW][k] * (EP[:vH2G2PNewCap][k] - EP[:vH2G2PRetCap][k])
			else
				dfH2G2P[!,:Existing_Cap_MW][k] + EP[:vH2G2PNewCap][k] - EP[:vH2G2PRetCap][k]
			end
		elseif k in setdiff(H2_G2P_NEW_CAP, H2_G2P_RET_CAP) # Resources eligible for only new capacity
			if k in H2_G2P_COMMIT
				dfH2G2P[!,:Existing_Cap_MW][k] + dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PNewCap][k]
			else
				dfH2G2P[!,:Existing_Cap_MW][k] + EP[:vH2G2PNewCap][k]
			end
		elseif k in setdiff(H2_G2P_RET_CAP, H2_G2P_NEW_CAP) # Resources eligible for only capacity retirements
			if k in H2_G2P_COMMIT
				dfH2G2P[!,:Existing_Cap_MW][k] - dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PRetCap][k]
			else
				dfH2G2P[!,:Existing_Cap_MW][k] - EP[:vH2G2PRetCap][k]
			end
		else
			# Resources not eligible for new capacity or retirements
			dfH2G2P[!,:Existing_Cap_MW][k]
		end
	)

	## Objective Function Expressions ##

		# Sum individual resource contributions to fixed costs to get total fixed costs
	#  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	#  ParameterScale = 0 --> objective function is in $
	if setup["ParameterScale"] ==1
		# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
		# If resource is not eligible for new capacity, fixed costs are only O&M costs
		@expression(EP, eH2G2PCFix[k in 1:H],
			if k in H2_G2P_NEW_CAP # Resources eligible for new capacity
				if k in H2_G2P_COMMIT
					1/ModelScalingFactor^2*(dfH2G2P[!,:Inv_Cost_p_MW_p_yr][k] * dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PNewCap][k] + dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k])
				else
					1/ModelScalingFactor^2*(dfH2G2P[!,:Inv_Cost_p_MW_p_yr][k] * EP[:vH2G2PNewCap][k] + dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k])
				end
			else
				(dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k])/ModelScalingFactor^2
			end
		)
	else
		# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
		# If resource is not eligible for new capacity, fixed costs are only O&M costs
		@expression(EP, eH2G2PCFix[k in 1:H],
			if k in H2_G2P_NEW_CAP # Resources eligible for new capacity
				if k in H2_G2P_COMMIT
					dfH2G2P[!,:Inv_Cost_p_MW_p_yr][k] * dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PNewCap][k] + dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k]
				else
					dfH2G2P[!,:Inv_Cost_p_MW_p_yr][k] * EP[:vH2G2PNewCap][k] + dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k]
				end
			else
				dfH2G2P[!,:Fixed_OM_p_MW_yr][k] * eH2G2PTotalCap[k]
			end
		)

	end

	@expression(EP, eTotalH2G2PCFix, sum(EP[:eH2G2PCFix][k] for k in 1:H))


	# # Sum individual resource contributions to fixed costs to get total fixed costs
	# #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	# #  ParameterScale = 0 --> objective function is in $
	# if setup["ParameterScale"] ==1
	# 	@expression(EP, eTotalH2GenCFix, sum(EP[:eH2GenCFix][k]/(ModelScalingFactor)^2 for k in 1:H))
	# else
	# 	@expression(EP, eTotalH2GenCFix, sum(EP[:eH2GenCFix][k] for k in 1:H))
	# end


	# Add term to objective function expression
	EP[:eObj] += eTotalH2G2PCFix


    return EP


end
