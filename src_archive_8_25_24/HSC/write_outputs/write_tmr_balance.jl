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
	write_TMR_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting hydrogen balance.
"""
function write_tmr_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfGen = inputs["dfGen"]
	H2_GEN = inputs["H2_GEN"]
	dfH2Gen = inputs["dfH2Gen"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	H = inputs["H2_RES_ALL"]  # Set of H2 storage resources
	H2_STOR_ALL = inputs["H2_STOR_ALL"]
	## Hydrogen balance for each zone
	hours_per_subperiod = Int(inputs["hours_per_subperiod"])
	#Rep_Periods = inputs["Rep_Periods"]
	Rep_Periods = Int(T/hours_per_subperiod)

	# Identify number of time matching requirements
	nH2_TMR = count(s -> startswith(String(s), "H2_TMR_"), names(dfGen))
	
	# Identify number of ESRR requirements
	nESR = count(s -> startswith(String(s), "ESR_"), names(dfGen))

	rowoffset=3
	dfTMRBalance = Array{Union{Missing, Any}}(missing, T+rowoffset, 4)

	#TEST

	nPPARen = length(dfGen[findall(x->x>0,dfGen[!,Symbol("H2_TMR_1")]),:R_ID])
	nPPABat = length(intersect(dfGen[findall(x->x>0,dfGen[!,Symbol("H2_TMR_1")]),:R_ID], inputs["STOR_ALL"]))
	nH2Gen = length(intersect(H2_GEN, dfH2Gen[findall(x->x>0,dfH2Gen[!,Symbol("H2_TMR_1")]),:R_ID]))

	dfTMRBalanceTest = Array{Union{Missing, Any}}(missing, T+rowoffset, nPPARen+nPPABat+nH2Gen+3)

	for z in 1:Z
		dfTemp1Test = Array{Union{Missing, Any}}(missing, T+rowoffset, nPPARen+nPPABat+nH2Gen+3)

		dfTemp1Test[1, 1:nPPARen] = dfGen[findall(x -> x > 0, dfGen[!, Symbol("H2_TMR_1")]), :Resource]
		#Why do I have to write R_ID for the following line, not Resource? which works for the others
		dfTemp1Test[1, nPPARen+1:nPPARen+nPPABat] = dfGen[intersect(dfGen[findall(x -> x > 0, dfGen[!, Symbol("H2_TMR_1")]), :R_ID], inputs["STOR_ALL"]), :Resource]
		#dfTemp1Test[1, nPPARen+1:nPPARen+nPPABat] = dfGen[findall(x -> x > 0, dfGen[!, Symbol("H2_TMR_1")]), :Resource]
		#dfTemp1Test[1, nPPARen+nPPABat+1:nPPARen+nPPABat+nH2Gen] = intersect(H2_GEN, dfH2Gen[findall(x -> x > 0, dfH2Gen[!, Symbol("H2_TMR_1")]), :R_ID])
		dfTemp1Test[1, nPPARen+nPPABat+1:nPPARen+nPPABat+nH2Gen] = dfH2Gen[findall(x->x>0,dfH2Gen[!,Symbol("H2_TMR_1")]), :H2_Resource]
		dfTemp1Test[1, nPPARen+nPPABat+nH2Gen+1] = "TMR_Slack"
		dfTemp1Test[1, nPPARen+nPPABat+nH2Gen+2] = "Storage Discharging"
		dfTemp1Test[1, nPPARen+nPPABat+nH2Gen+3] = "Storage Charging"

		for t in 1:T

			for TMR in 1:nH2_TMR
				dfTemp1Test[t+rowoffset, 1:nPPARen] =  value.(dfGen[!,Symbol("H2_TMR_1")][y]*EP[:vP][y,t] for y=dfGen[findall(x->x>0,dfGen[!,Symbol("H2_TMR_1")]),:R_ID])
				dfTemp1Test[t+rowoffset, nPPARen+1:nPPARen+nPPABat] =  -  value.(dfGen[!,Symbol("H2_TMR_1")][s]*EP[:vCHARGE][s,t] for s in intersect(dfGen[findall(x->x>0,dfGen[!,Symbol("H2_TMR_1")]),:R_ID], inputs["STOR_ALL"]))
				dfTemp1Test[t+rowoffset, nPPARen+nPPABat+1:nPPARen+nPPABat+nH2Gen] =  - value.(EP[:vH2Gen][k,t]*dfH2Gen[!,:etaP2G_MWh_p_tonne][k] for k in intersect(H2_GEN, dfH2Gen[findall(x -> x > 0, dfH2Gen[!, Symbol("H2_TMR_1")]), :R_ID]))
			end
		
			if haskey(setup, "H2TMR_slack_cost")
				dfTemp1Test[t+rowoffset, nPPARen+nPPABat+nH2Gen+1] = value.(EP[:vH2_TMR_slack][t])
			else
				dfTemp1Test[t+rowoffset, nPPARen+nPPABat+nH2Gen+1] = 0
			end

			dfTemp1Test[t+rowoffset,nPPARen+nPPABat+nH2Gen+2] = 0
            dfTemp1Test[t+rowoffset,nPPARen+nPPABat+nH2Gen+3] = 0

			if !isempty(intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL))
				dfTemp1Test[t+rowoffset,nPPARen+nPPABat+nH2Gen+2] = sum(value.(EP[:vH2Gen][y,t]) for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL))
			   	dfTemp1Test[t+rowoffset,nPPARen+nPPABat+nH2Gen+3] = -sum(value.(EP[:vH2_CHARGE_STOR][y,t]) for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL))
			end

		end

		if z==1
			dfTMRBalanceTest =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1Test)
		else
			dfTMRBalanceTest = hcat(dfTMRBalanceTest, dfTemp1Test)
		end

	end

	for c in 2:size(dfTMRBalanceTest,2)
		dfTMRBalanceTest[rowoffset,c]=sum(inputs["omega"].*dfTMRBalanceTest[(rowoffset+1):size(dfTMRBalanceTest,1),c])
	end

	#TEST

	for z in 1:Z
		dfTemp1 = Array{Union{Missing, Any}}(missing, T+rowoffset, 4)
		dfTemp1[1,1:size(dfTemp1,2)] = ["PPA_Renewables", #1
										"PPA_Battery", #2
										"H2_Gen", # 3
										"TMR_Slack",#4
										]

		for t in 1:T
			PPA_Ren = 0
			PPA_Bat = 0
			H2_Stor = 0
			for TMR in 1:nH2_TMR
				PPA_Ren +=  sum(value.(dfGen[!,Symbol("H2_TMR_$TMR")][y]*EP[:vP][y,t] for y=dfGen[findall(x->x>0,dfGen[!,Symbol("H2_TMR_$TMR")]),:R_ID]))
				PPA_Bat +=  - sum(value.(dfGen[!,Symbol("H2_TMR_$TMR")][s]*EP[:vCHARGE][s,t] for s in intersect(dfGen[findall(x->x>0,dfGen[!,Symbol("H2_TMR_$TMR")]),:R_ID], inputs["STOR_ALL"])))
				H2_Stor +=  - sum(value.(EP[:vH2Gen][k,t]*dfH2Gen[!,:etaP2G_MWh_p_tonne][k] for k in intersect(H2_GEN, dfH2Gen[findall(x->x>0,dfH2Gen[!,Symbol("H2_TMR_$TMR")]),:R_ID])))
			end

			dfTemp1[t+rowoffset,1] = PPA_Ren
			dfTemp1[t+rowoffset,2] = PPA_Bat
			dfTemp1[t+rowoffset,3] = H2_Stor
		
			if haskey(setup, "H2TMR_slack_cost")
				dfTemp1[t+rowoffset,4] = value.(EP[:vH2_TMR_slack][t])
			else
				dfTemp1[t+rowoffset,4] = 0
			end

		end

		if z==1
			dfTMRBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
			dfTMRBalance = hcat(dfTMRBalance, dfTemp1)
		end

	end

	for c in 2:size(dfTMRBalance,2)
		dfTMRBalance[rowoffset,c]=sum(inputs["omega"].*dfTMRBalance[(rowoffset+1):size(dfTMRBalance,1),c])
	end
	
	dfTMRBalance = DataFrame(dfTMRBalance, :auto)
	CSV.write(string(path,sep,"HSC_TMR_balance_simple.csv"), dfTMRBalance, writeheader=false)

	dfTMRBalanceTest = DataFrame(dfTMRBalanceTest, :auto)
	CSV.write(string(path,sep,"HSC_TMR_balance_expanded.csv"), dfTMRBalanceTest, writeheader=false)

end

