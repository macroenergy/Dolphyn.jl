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

function h2_g2p_commit(EP::Model, inputs::Dict, setup::Dict)

	#Rename H2Gen dataframe
	dfH2G2P = inputs["dfH2G2P"]
	H2G2PCommit = setup["H2G2PCommit"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	H = inputs["H"]		#NUmber of hydrogen generation units 
	
	H2_G2P_COMMIT = inputs["H2_G2P_COMMIT"]
	H2_G2P_NEW_CAP = inputs["H2_G2P_NEW_CAP"] 
	H2_G2P_RET_CAP = inputs["H2_G2P_RET_CAP"] 
	
	#Define start subperiods and interior subperiods
	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ###Variables###

	# commitment state variable
	@variable(EP, vH2G2PCOMMIT[k in H2_G2P_COMMIT, t=1:T] >= 0)
	# Start up variable
	@variable(EP, vH2G2PStart[k in H2_G2P_COMMIT, t=1:T] >= 0)
	# Shutdown Variable
	@variable(EP, vH2G2PShut[k in H2_G2P_COMMIT, t=1:T] >= 0)

	###Expressions###

	#Objective function expressions
	# Startup costs of "generation" for resource "y" during hour "t"
	#  ParameterScale = 1 --> objective function is in million $
	#  ParameterScale = 0 --> objective function is in $
	if setup["ParameterScale"] ==1 
		@expression(EP, eH2G2PCStart[k in H2_G2P_COMMIT, t=1:T],(inputs["omega"][t]*inputs["C_G2P_Start"][k]*vH2G2PStart[k,t]/ModelScalingFactor^2))
	else
		@expression(EP, eH2G2PCStart[k in H2_G2P_COMMIT, t=1:T],(inputs["omega"][t]*inputs["C_G2P_Start"][k]*vH2G2PStart[k,t]))
	end

	# Julia is fastest when summing over one row one column at a time
	@expression(EP, eTotalH2G2PCStartT[t=1:T], sum(eH2G2PCStart[k,t] for k in H2_G2P_COMMIT))
	@expression(EP, eTotalH2G2PCStart, sum(eTotalH2G2PCStartT[t] for t=1:T))

	EP[:eObj] += eTotalH2G2PCStart

	#H2 Balance expressions
	@expression(EP, eH2G2PCommit[t=1:T, z=1:Z],
	sum(EP[:vH2G2P][k,t] for k in intersect(H2_G2P_COMMIT, dfH2G2P[dfH2G2P[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] -= eH2G2PCommit

	#Power Consumption for H2 Generation
	if setup["ParameterScale"] ==1 # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
		@expression(EP, ePowerBalanceH2G2PCommit[t=1:T, z=1:Z],
		sum(EP[:vPG2P][k,t]/ModelScalingFactor for k in intersect(H2_G2P_COMMIT, dfH2G2P[dfH2G2P[!,:Zone].==z,:][!,:R_ID]))) 

	else # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of H2 related power consumption
		@expression(EP, ePowerBalanceH2G2PCommit[t=1:T, z=1:Z],
		sum(EP[:vPG2P][k,t] for k in intersect(H2_G2P_COMMIT, dfH2G2P[dfH2G2P[!,:Zone].==z,:][!,:R_ID]))) 
	end

	EP[:ePowerBalance] += ePowerBalanceH2G2PCommit

	### Constraints ###
	## Declaration of integer/binary variables
	if H2G2PCommit == 1 # Integer UC constraints
		for k in H2_G2P_COMMIT
			set_integer.(vH2G2PCOMMIT[k,:])
			set_integer.(vH2G2PStart[k,:])
			set_integer.(vH2G2PShut[k,:])
			if k in H2_G2P_RET_CAP
				set_integer(EP[:vH2G2PRetCap][k])
			end
			if k in H2_G2P_NEW_CAP 
				set_integer(EP[:vH2G2PNewCap][k])
			end
		end
	end #END unit commitment configuration

		###Constraints###
		@constraints(EP, begin
		#Power Balance
		[k in H2_G2P_COMMIT, t = 1:T], EP[:vPG2P][k,t] == EP[:vH2G2P][k,t] * dfH2G2P[!,:etaG2P_MWh_p_tonne][k]
	end)

	### Capacitated limits on unit commitment decision variables (Constraints #1-3)
	@constraints(EP, begin
		[k in H2_G2P_COMMIT, t=1:T], EP[:vH2G2PCOMMIT][k,t] <= EP[:eH2G2PTotalCap][k]/dfH2G2P[!,:Cap_Size_MW][k]
		[k in H2_G2P_COMMIT, t=1:T], EP[:vH2G2PStart][k,t] <= EP[:eH2G2PTotalCap][k]/dfH2G2P[!,:Cap_Size_MW][k]
		[k in H2_G2P_COMMIT, t=1:T], EP[:vH2G2PShut][k,t] <= EP[:eH2G2PTotalCap][k]/dfH2G2P[!,:Cap_Size_MW][k]
	end)

	# Commitment state constraint linking startup and shutdown decisions (Constraint #4)
	@constraints(EP, begin
	# For Start Hours, links first time step with last time step in subperiod
	[k in H2_G2P_COMMIT, t in START_SUBPERIODS], EP[:vH2G2PCOMMIT][k,t] == EP[:vH2G2PCOMMIT][k,(t+hours_per_subperiod-1)] + EP[:vH2G2PStart][k,t] - EP[:vH2G2PShut][k,t]
	# For all other hours, links commitment state in hour t with commitment state in prior hour + sum of start up and shut down in current hour
	[k in H2_G2P_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2G2PCOMMIT][k,t] == EP[:vH2G2PCOMMIT][k,t-1] + EP[:vH2G2PStart][k,t] - EP[:vH2G2PShut][k,t]
	end)


	### Maximum ramp up and down between consecutive hours (Constraints #5-6)

	## For Start Hours
	# Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
	# rampup constraints
	@constraint(EP,[k in H2_G2P_COMMIT, t in START_SUBPERIODS],
	EP[:vPG2P][k,t]-EP[:vPG2P][k,(t+hours_per_subperiod-1)] <= dfH2G2P[!,:Ramp_Up_Percentage][k] * dfH2G2P[!,:Cap_Size_MW][k]*(EP[:vH2G2PCOMMIT][k,t]-EP[:vH2G2PStart][k,t])
	+ min(inputs["pH2_g2p_Max"][k,t],max(dfH2G2P[!,:G2P_min_output][k],dfH2G2P[!,:Ramp_Up_Percentage][k]))*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PStart][k,t]
	- dfH2G2P[!,:G2P_min_output][k] * dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PShut][k,t])

	# rampdown constraints
	@constraint(EP,[k in H2_G2P_COMMIT, t in START_SUBPERIODS],
	EP[:vPG2P][k,(t+hours_per_subperiod-1)]-EP[:vPG2P][k,t] <= dfH2G2P[!,:Ramp_Down_Percentage][k]*dfH2G2P[!,:Cap_Size_MW][k]*(EP[:vH2G2PCOMMIT][k,t]-EP[:vH2G2PStart][k,t])
	- dfH2G2P[!,:G2P_min_output][k]*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PStart][k,t]
	+ min(inputs["pH2_g2p_Max"][k,t],max(dfH2G2P[!,:G2P_min_output][k],dfH2G2P[!,:Ramp_Down_Percentage][k]))*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PShut][k,t])

	## For Interior Hours
	# rampup constraints
	@constraint(EP,[k in H2_G2P_COMMIT, t in INTERIOR_SUBPERIODS],
		EP[:vPG2P][k,t]-EP[:vPG2P][k,t-1] <= dfH2G2P[!,:Ramp_Up_Percentage][k]*dfH2G2P[!,:Cap_Size_MW][k]*(EP[:vH2G2PCOMMIT][k,t]-EP[:vH2G2PStart][k,t])
			+ min(inputs["pH2_g2p_Max"][k,t],max(dfH2G2P[!,:G2P_min_output][k],dfH2G2P[!,:Ramp_Up_Percentage][k]))*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PStart][k,t]
			-dfH2G2P[!,:G2P_min_output][k]*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PShut][k,t])

	# rampdown constraints
	@constraint(EP,[k in H2_G2P_COMMIT, t in INTERIOR_SUBPERIODS],
	EP[:vPG2P][k,t-1]-EP[:vPG2P][k,t] <= dfH2G2P[!,:Ramp_Down_Percentage][k]*dfH2G2P[!,:Cap_Size_MW][k]*(EP[:vH2G2PCOMMIT][k,t]-EP[:vH2G2PStart][k,t])
	-dfH2G2P[!,:G2P_min_output][k]*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PStart][k,t]
	+min(inputs["pH2_g2p_Max"][k,t],max(dfH2G2P[!,:G2P_min_output][k],dfH2G2P[!,:Ramp_Down_Percentage][k]))*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PShut][k,t])

	@constraints(EP, begin
	# Minimum stable generated per technology "k" at hour "t" > = Min stable output level
	[k in H2_G2P_COMMIT, t=1:T], EP[:vPG2P][k,t] >= dfH2G2P[!,:Cap_Size_MW][k] *dfH2G2P[!,:G2P_min_output][k]* EP[:vH2G2PCOMMIT][k,t]
	# Maximum power generated per technology "k" at hour "t" < Max power
	[k in H2_G2P_COMMIT, t=1:T], EP[:vPG2P][k,t] <= dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PCOMMIT][k,t] * inputs["pH2_g2p_Max"][k,t]
	end)


	### Minimum up and down times (Constraints #9-10)
	for y in H2_G2P_COMMIT

		## up time
		Up_Time = Int(floor(dfH2G2P[!,:Up_Time][y]))
		Up_Time_HOURS = [] # Set of hours in the summation term of the maximum up time constraint for the first subperiod of each representative period
		for s in START_SUBPERIODS
			Up_Time_HOURS = union(Up_Time_HOURS, (s+1):(s+Up_Time-1))
		end

		@constraints(EP, begin
			# cUpTimeInterior: Constraint looks back over last n hours, where n = dfH2G2P[!,:Up_Time][y]
			[t in setdiff(INTERIOR_SUBPERIODS,Up_Time_HOURS)], EP[:vH2G2PCOMMIT][y,t] >= sum(EP[:vH2G2PStart][y,e] for e=(t-dfH2G2P[!,:Up_Time][y]):t)

			# cUpTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
			# cUpTimeWrap constraint equivalant to: sum(EP[:vH2G2PStart][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2G2PStart][y,e] for e=(hours_per_subperiod_max-(dfH2G2P[!,:Up_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
			[t in Up_Time_HOURS], EP[:vH2G2PCOMMIT][y,t] >= sum(EP[:vH2G2PStart][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2G2PStart][y,e] for e=((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfH2G2P[!,:Up_Time][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod)))

			# cUpTimeStart:
			# NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
			[t in START_SUBPERIODS], EP[:vH2G2PCOMMIT][y,t] >= EP[:vH2G2PStart][y,t]+sum(EP[:vH2G2PStart][y,e] for e=((t+hours_per_subperiod-1)-(dfH2G2P[!,:Up_Time][y]-1)):(t+hours_per_subperiod-1))
		end)

		## down time
		Down_Time = Int(floor(dfH2G2P[!,:Down_Time][y]))
		Down_Time_HOURS = [] # Set of hours in the summation term of the maximum down time constraint for the first subperiod of each representative period
		for s in START_SUBPERIODS
			Down_Time_HOURS = union(Down_Time_HOURS, (s+1):(s+Down_Time-1))
		end

		# Constraint looks back over last n hours, where n = dfH2G2P[!,:Down_Time][y]
		# TODO: Replace LHS of constraints in this block with eNumPlantsOffline[y,t]
		@constraints(EP, begin
			# cDownTimeInterior: Constraint looks back over last n hours, where n = inputs["pDMS_Time"][y]
			[t in setdiff(INTERIOR_SUBPERIODS,Down_Time_HOURS)], EP[:eH2G2PTotalCap][y]/dfH2G2P[!,:Cap_Size_MW][y]-EP[:vH2G2PCOMMIT][y,t] >= sum(EP[:vH2G2PShut][y,e] for e=(t-dfH2G2P[!,:Down_Time][y]):t)

			# cDownTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
			# cDownTimeWrap constraint equivalant to: EP[:eH2G2PTotalCap][y]/dfH2G2P[!,:Cap_Size_MW][y]-EP[:vH2G2PCOMMIT][y,t] >= sum(EP[:vH2G2PShut][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2G2PShut][y,e] for e=(hours_per_subperiod_max-(dfH2G2P[!,:Down_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
			[t in Down_Time_HOURS], EP[:eH2G2PTotalCap][y]/dfH2G2P[!,:Cap_Size_MW][y]-EP[:vH2G2PCOMMIT][y,t] >= sum(EP[:vH2G2PShut][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2G2PShut][y,e] for e=((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfH2G2P[!,:Down_Time][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod)))

			# cDownTimeStart:
			# NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
			[t in START_SUBPERIODS], EP[:eH2G2PTotalCap][y]/dfH2G2P[!,:Cap_Size_MW][y]-EP[:vH2G2PCOMMIT][y,t]  >= EP[:vH2G2PShut][y,t]+sum(EP[:vH2G2PShut][y,e] for e=((t+hours_per_subperiod-1)-(dfH2G2P[!,:Down_Time][y]-1)):(t+hours_per_subperiod-1))
		end)
	end

	return EP

end