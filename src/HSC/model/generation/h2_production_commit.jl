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
h2_generation_commit(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

The h2_generation module creates decision variables, expressions, and constraints related to various hydrogen generation technologies with unit commitment constraints (e.g. natural gas reforming etc.)

Documentation to follow ******
"""

function h2_generation_commit(EP::Model, inputs::Dict, setup::Dict)

	#Rename H2Gen dataframe
	dfH2Gen = inputs["dfH2Gen"]
	UCommit = setup["UCommit"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	H = inputs["H"]		#NUmber of hydrogen generation units 
	
	H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
	H2_GEN_NEW_CAP = inputs["H2_GEN_NEW_CAP"] 
	H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"] 
	
	#Define start subperiods and interior subperiods
	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ###Variables###

	# commitment state variable
	@variable(EP, vH2GenCOMMIT[k in H2_GEN_COMMIT, t=1:T] >= 0)
	# Start up variable
	@variable(EP, vH2GenStart[k in H2_GEN_COMMIT, t=1:T] >= 0)
	# Shutdown Variable
	@variable(EP, vH2GenShut[k in H2_GEN_COMMIT, t=1:T] >= 0)

	###Expressions###

	#Objective function expressions
	# Startup costs of "generation" for resource "y" during hour "t"
	@expression(EP, eH2GenCStart[k in H2_GEN_COMMIT, t=1:T],(inputs["omega"][t]*inputs["C_H2_Start"][k]*vH2GenStart[k,t]))

	# Julia is fastest when summing over one row one column at a time
	@expression(EP, eTotalH2GenCStartT[t=1:T], sum(eH2GenCStart[k,t] for k in H2_GEN_COMMIT))
	@expression(EP, eTotalH2GenCStart, sum(eTotalH2GenCStartT[t] for t=1:T))

	EP[:eObj] += eTotalH2GenCStart

	#H2 Balance expressions
	@expression(EP, eH2GenCommit[t=1:T, z=1:Z],
	sum(EP[:vH2Gen][k,t] for k in intersect(H2_GEN_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] += eH2GenCommit

	#Power Consumption for H2 Generation
	@expression(EP, ePowerBalanceH2GenCommit[t=1:T, z=1:Z],
	sum(EP[:vP2G][k,t] for k in intersect(H2_GEN_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]))) 

	EP[:ePowerBalance] += ePowerBalanceH2GenCommit


	### Constraints ###
	## Declaration of integer/binary variables
	if UCommit == 1 # Integer UC constraints
		for k in H2_GEN_COMMIT
			set_integer.(vH2GenCOMMIT[k,:])
			set_integer.(vH2GenStart[k,:])
			set_integer.(vH2GenShut[k,:])
			if k in H2_GEN_RET_CAP
				set_integer(EP[:vH2GenRetCap][k])
			end
			if k in H2_GEN_NEW_CAP 
				set_integer(EP[:vH2GenNewCap][k])
			end
		end
	end #END unit commitment configuration

		###Constraints###
		@constraints(EP, begin
		#Power Balance
		[k in H2_GEN_COMMIT, t = 1:T], EP[:vP2G][k,t] == EP[:vH2Gen][k,t] * dfH2Gen[!,:etaP2G_MWh_per_tonne][k]
		#Gas Balance
		[k in H2_GEN_COMMIT, t = 1:T], EP[:vGas][k,t] == EP[:vH2Gen][k,t] * dfH2Gen[!,:etaGas_MMBtu_per_tonne][k]
	end)

	### Capacitated limits on unit commitment decision variables (Constraints #1-3)
	@constraints(EP, begin
		[k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenCOMMIT][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size][k]
		[k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenStart][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size][k]
		[k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenShut][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size][k]
	end)

	# Commitment state constraint linking startup and shutdown decisions (Constraint #4)
	@constraints(EP, begin
	# For Start Hours, links first time step with last time step in subperiod
	[k in H2_GEN_COMMIT, t in START_SUBPERIODS], EP[:vH2GenCOMMIT][k,t] == EP[:vH2GenCOMMIT][k,(t+hours_per_subperiod-1)] + EP[:vH2GenStart][k,t] - EP[:vH2GenShut][k,t]
	# For all other hours, links commitment state in hour t with commitment state in prior hour + sum of start up and shut down in current hour
	[k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2GenCOMMIT][k,t] == EP[:vH2GenCOMMIT][k,t-1] + EP[:vH2GenStart][k,t] - EP[:vH2GenShut][k,t]
	end)


	### Maximum ramp up and down between consecutive hours (Constraints #5-6)

	## For Start Hours
	# Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
	# rampup constraints
	@constraint(EP,[k in H2_GEN_COMMIT, t in START_SUBPERIODS],
	EP[:vH2Gen][k,t]-EP[:vH2Gen][k,(t+hours_per_subperiod-1)] <= dfH2Gen[!,:Ramp_Up_Percentage][k] * dfH2Gen[!,:Cap_Size][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
	+ min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:Min_H2Gen][k],dfH2Gen[!,:Ramp_Up_Percentage][k]))*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenStart][k,t]
	- dfH2Gen[!,:Min_H2Gen][k] * dfH2Gen[!,:Cap_Size][k] * EP[:vH2GenShut][k,t])

	# rampdown constraints
	@constraint(EP,[k in H2_GEN_COMMIT, t in START_SUBPERIODS],
	EP[:vH2Gen][k,(t+hours_per_subperiod-1)]-EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k]*dfH2Gen[!,:Cap_Size][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
	- dfH2Gen[!,:Min_H2Gen][k]*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenStart][k,t]
	+ min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:Min_H2Gen][k],dfH2Gen[!,:Ramp_Down_Percentage][k]))*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenShut][k,t])

	## For Interior Hours
	# rampup constraints
	@constraint(EP,[k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS],
		EP[:vH2Gen][k,t]-EP[:vH2Gen][k,t-1] <= dfH2Gen[!,:Ramp_Up_Percentage][k]*dfH2Gen[!,:Cap_Size][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
			+ min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:Min_H2Gen][k],dfH2Gen[!,:Ramp_Up_Percentage][k]))*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenStart][k,t]
			-dfH2Gen[!,:Min_H2Gen][k]*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenShut][k,t])

	# rampdown constraints
	@constraint(EP,[k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS],
	EP[:vH2Gen][k,t-1]-EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k]*dfH2Gen[!,:Cap_Size][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
	-dfH2Gen[!,:Min_H2Gen][k]*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenStart][k,t]
	+min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:Min_H2Gen][k],dfH2Gen[!,:Ramp_Down_Percentage][k]))*dfH2Gen[!,:Cap_Size][k]*EP[:vH2GenShut][k,t])

	@constraints(EP, begin
	# Minimum stable generated per technology "k" at hour "t" > = Min stable output level
	[k in H2_GEN_COMMIT, t=1:T], EP[:vH2Gen][k,t] >= dfH2Gen[!,:Cap_Size][k] *dfH2Gen[!,:Min_H2Gen][k]* EP[:vH2GenCOMMIT][k,t]
	# Maximum power generated per technology "k" at hour "t" < Max power
	[k in H2_GEN_COMMIT, t=1:T], EP[:vH2Gen][k,t] <= dfH2Gen[!,:Cap_Size][k] * EP[:vH2GenCOMMIT][k,t] * inputs["pH2_Max"][k,t]
	end)

	return EP

end