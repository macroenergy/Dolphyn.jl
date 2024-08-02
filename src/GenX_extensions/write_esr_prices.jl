function write_esr_prices(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	dfGen = inputs["dfGen"] # Power sector inputs
	
	hours_per_subperiod = Int(inputs["hours_per_subperiod"])
	Rep_Periods = inputs["REP_PERIOD"] # number of representative periods


	# Identify number of time matching requirements
	nESR = count(s -> startswith(String(s), "ESR_"), names(dfGen))


	if setup["MultipleYears"] ==0
		dfESR = DataFrame(ESR_Price = convert(Array{Float64}, dual.(EP[:cESRShare])))
		if setup["ParameterScale"] == 1
			dfESR[!,:ESR_Price] = dfESR[!,:ESR_Price] * ModelScalingFactor # Converting MillionUS$/GWh to US$/MWh
		end

		if haskey(inputs, "dfESR_slack") # SKIP FOR THE CASE OF MULTIPLE YEARS OF OPERATION
			dfESR[!,:ESR_AnnualSlack] = convert(Array{Float64}, value.(EP[:vESR_slack]))
			dfESR[!,:ESR_AnnualPenalty] = convert(Array{Float64}, value.(EP[:eCESRSlack]))
			if setup["ParameterScale"] == 1
				dfESR[!,:ESR_AnnualSlack] *= ModelScalingFactor # Converting GWh to MWh
				dfESR[!,:ESR_AnnualPenalty] *= (ModelScalingFactor^2) # Converting MillionUSD to USD
			end
		end
		CSV.write(joinpath(path, "ESR_prices_and_penalties.csv"), dfESR)

	else
		dfESR = DataFrame(ESR = 1:nESR) 

		# Dividing dual variable for each hour with corresponding hourly weight to retrieve marginal cost of generation
		if setup["ParameterScale"] == 1
			dfESR = hcat(dfESR, DataFrame(dual.(EP[:cESRSharePerPeriod])./ModelScalingFactor, :auto))
		else
			dfESR = hcat(dfESR, DataFrame(dual.(EP[:cESRSharePerPeriod]), :auto))
		end

		auxNew_Names=[Symbol("Representative_Periods");[Symbol("p$t") for t in 1:Rep_Periods]]
		#[Symbol("p$t") for t in 1:Rep_Periods]
		rename!(dfESR,auxNew_Names)
		# dfESR = DataFrame(ESR_Price = vec(convert(Array{Float64}, dual.(EP[:cESRSharePerPeriod]))))

		# dfESR = DataFrame(ESR_Price = convert(Array{Float64}, dual.(EP[:cESRSharePerPeriod])))
	

		CSV.write(joinpath(path, "ESR_prices_and_penalties.csv"), dftranspose(dfESR, false), writeheader=false)

	end
	return dfESR
end
