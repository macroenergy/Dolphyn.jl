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

		if haskey(inputs, "dfESR_slack") 
			dfESR[!,:ESR_AnnualSlack] = convert(Array{Float64}, value.(EP[:vESR_slack]))
			dfESR[!,:ESR_AnnualPenalty] = convert(Array{Float64}, value.(EP[:eCESRSlack]))
			if setup["ParameterScale"] == 1
				dfESR[!,:ESR_AnnualSlack] *= ModelScalingFactor # Converting GWh to MWh
				dfESR[!,:ESR_AnnualPenalty] *= (ModelScalingFactor^2) # Converting MillionUSD to USD
			end
		end
		CSV.write(joinpath(path, "ESR_prices_and_penalties.csv"), dfESR)

	else # setup["MultipleYears"]==1
		if haskey(inputs, "dfESR_slack") 
			dfESR = DataFrame(:ESR => Int[], :Rep_Periods => String[] ,:ESR_Price => Float64[], :ESR_AnnualSlack => Float64[], :ESR_AnnualPenalty => Float64[])
			i=1
			while i <= nESR
				df1 = DataFrame(ESR = i, 
				Rep_Periods=1:Rep_Periods, 
				ESR_Price = convert(Array{Float64}, dual.(EP[:cESRSharePerPeriod])[i,:]),
				ESR_AnnualSlack = convert(Array{Float64}, value.(EP[:vESR_slack])[i,:]),
				ESR_AnnualPenalty = convert(Array{Float64}, value.(EP[:eCESRSlack])[i,:])
				)	
				dfESR =vcat(dfESR, df1)
				i += 1
			end
		else
			dfESR = DataFrame(:ESR => Int[], :Rep_Periods => String[] ,:ESR_Price => Float64[])
			i=1
			while i <= nESR
				df1 = DataFrame(ESR = i, 
				Rep_Periods=1:Rep_Periods, 
				ESR_Price = convert(Array{Float64}, dual.(EP[:cESRSharePerPeriod])[i,:])
				)	
				dfESR =vcat(dfESR, df1)
				i += 1
			end
		end
		CSV.write(joinpath(path, "ESR_prices_and_penalties.csv"), dfESR)

	end
	return dfESR
end
