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
	write_h2_tmr_prices(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting prices related to time matching requirement.	
"""
function write_h2_tmr_prices(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	dfGen = inputs["dfGen"] # Power sector inputs
	dfH2Gen = inputs["dfH2Gen"]
	T = inputs["T"]     # Number of time steps (hours)
	Rep_Periods = inputs["REP_PERIOD"] # number of representative periods


	# Identify number of time matching requirements
	nH2_TMR = count(s -> startswith(String(s), "H2_TMR_"), names(dfGen))


	if (setup["TimeMatchingRequirement"] == 1 || setup["TimeMatchingRequirement"] == 2)

		## Extract dual variables of constraints
		dfPrice = DataFrame(TMR = 1:nH2_TMR) # The unit is $/MWh

	# Dividing dual variable for each hour with corresponding hourly price
		if setup["ParameterScale"] == 1
			dfPrice = hcat(dfPrice, DataFrame(dual.(EP[:cH2TMR])./transpose(inputs["omega"]*ModelScalingFactor), :auto))
		else
			dfPrice = hcat(dfPrice, DataFrame(dual.(EP[:cH2TMR])./transpose(inputs["omega"]), :auto))
		end

		auxNew_Names=[Symbol("TMR_number");[Symbol("t$t") for t in 1:T]]
		rename!(dfPrice,auxNew_Names)

		## Linear configuration final output
		CSV.write(string(path,sep,"TMR_prices.csv"), dftranspose(dfPrice, false), writeheader=false)
	

	else # annual time matching scenario (TimeMatchingRequirement = 3)
		if setup["MultipleYears"]==0
			dfPrice = DataFrame(TMR_Price = convert(Array{Union{Missing, Float64}}, dual.(EP[:cH2TMR_Annual])))


			if setup["ParameterScale"] == 1
				dfPrice[!,:TMR_Price] = dfPrice[!,:TMR_Price] * ModelScalingFactor # Converting MillionUS$/GWh to US$/MWh

			end

		else # MultipleYears - multiple annual time matching requirements - one for each year
			dfTMR = DataFrame(TMR_number = 1:nH2_TMR) 

			# Dividing dual variable for each hour with corresponding hourly weight to retrieve marginal cost of generation
			if setup["ParameterScale"] == 1
				dfPrice = hcat(dfTMR, DataFrame(Dict(Symbol("p$t") => dual.(EP[:cH2TMR_Annual])[:,t]./ModelScalingFactor for t=1:Rep_Periods)))
			else
				dfPrice = hcat(dfTMR, DataFrame(Dict(Symbol("p$t") => dual.(EP[:cH2TMR_Annual])[:,t] for t=1:Rep_Periods)))
			end
		end
	
		CSV.write(string(path,sep,"TMR_prices.csv"), dftranspose(dfPrice,false),writeheader=false)

	end


#write out the H2_TMR_slack variable
#	if setup["TimeMatchingRequirement"] >= 1
#		dfH2_TMR_slack = DataFrame(TMR = 1:nH2_TMR) 
#		dfH2_TMR_slack = hcat(dfH2_TMR_slack, (EP[:vH2_TMR_slack]./inputs["omega"]))

#	CSV.write(string(path,sep,"H2_TMR_slack.csv"), dfH2_TMR_slack)

#	end


#	dfH2_TMR_slack = DataFrame()
#	if setup["ParameterScale"] == 1
#		dfCO2Price.CO2_Price .*= ModelScalingFactor # Convert Million$/kton to $/ton
#	end

#	if haskey(setup, "H2TMR_slack_cost")
#		dfH2_TMR_slack = hcat(dfH2_TMR_slack, convert(Array{Float64}, value.(EP[:vH2_TMR_slack])))
#		#if setup["ParameterScale"] == 1
		#	dfCO2Price.CO2_Mass_Slack .*= ModelScalingFactor # Convert ktons to tons
		#	dfCO2Price.CO2_Penalty .*= ModelScalingFactor^2 # Convert Million$ to $
		#end
#		CSV.write(joinpath(path, "H2_TMR_slack.csv"), dfH2_TMR_slack)
#	end

	

	

#	return dfPrice, dfH2_TMR_slack

end
