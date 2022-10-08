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

"""

function syn_fuels_production_no_commit(EP::Model, inputs::Dict,setup::Dict)

	#Rename H2Gen dataframe
	dfSynFuels = inputs["dfSynFuels"]
    dfSynFuelsByProdExcess = inputs["dfSynFuelsByProdExcess"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
    NSFByProd = inputs["NSFByProd"]

	SYN_GEN_NO_COMMIT = inputs["SYN_GEN_NO_COMMIT"]

	###Expressions###

    #Liquid Fuel Balance Expression
    @expression(EP, eSynFuelProdNoCommit[t=1:T, z=1:Z],
		sum(EP[:vSFProd][k,t] for k in intersect(SYN_GEN_NO_COMMIT, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))#intersect(SYN_GEN_NO_COMMIT, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))

    EP[:eLFBalance] -= eSynFuelProdNoCommit

	#H2 Balance expressions
	@expression(EP, eSynFuelH2ConsNoCommit[t=1:T, z=1:Z],
		sum(EP[:vSFH2in][k,t] for k in intersect(SYN_GEN_NO_COMMIT, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] -= eSynFuelH2ConsNoCommit

    #CO2 Balance Expression
    @expression(EP, eSynFuelCO2ConsNoCommit[t=1:T, z=1:Z],
		sum(EP[:vSFCO2in][k,t] for k in intersect(SYN_GEN_NO_COMMIT, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))

	EP[:eCaptured_CO2_Balance] -= eSynFuelCO2ConsNoCommit

    #Power Consumption for Syn Fuel Production
	if setup["ParameterScale"] ==1 # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW
		@expression(EP, ePowerBalanceSynFuelResNoCommit[t=1:T, z=1:Z],
		sum(EP[:vSFPin][k,t]/ModelScalingFactor for k in intersect(SYN_GEN_NO_COMMIT, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))

	else # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling
		@expression(EP, ePowerBalanceSynFuelResNoCommit[t=1:T, z=1:Z],
		sum(EP[:vSFPin][k,t] for k in intersect(SYN_GEN_NO_COMMIT, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))
	end

	EP[:ePowerBalance] += -ePowerBalanceSynFuelResNoCommit

	###Constraints###
	# Power and natural gas consumption associated with Syn Fuel Production in each time step
	@constraints(EP, begin
		#Power Balance
		[k in SYN_GEN_NO_COMMIT, t = 1:T], EP[:vSFPin][k,t] == EP[:vSFCO2in][k,t] * dfSynFuels[!,:tonnes_h2_p_tonne_co2][k]
	end)

    # By-product produced cosntraint
    @constraints(EP, begin
	[k in SYN_GEN_NO_COMMIT, b in 1:NSFByProd, t=1:T], EP[:vSFByProd][k, b, t] == EP[:vSFCO2in][k,t] * dfSynFuelsByProdExcess[:,b][k]
	end)

    # Production must be smaller than available capacity
	@constraints(EP, begin [k in SYN_GEN_NO_COMMIT, t=1:T], EP[:vSFCO2in][k,t] <= EP[:vCapacity_Syn_Fuel_per_type][k]
	end)

	#Add ramping constraints later

	return EP

end




