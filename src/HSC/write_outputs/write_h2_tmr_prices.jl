

@doc raw"""
	write_h2_tmr_prices(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting prices related to time matching requirement.	
"""
function write_h2_tmr_prices(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	dfGen = inputs["dfGen"] # Power sector inputs
	dfH2Gen = inputs["dfH2Gen"]::DataFrame
	T = inputs["T"]::Int     # Number of time steps (hours)

	SCALING = setup["scaling"]::Float64

	# Identify number of time matching requirements
	nH2_TMR = count(s -> startswith(String(s), "H2_TMR_"), names(dfGen))


	if (setup["TimeMatchingRequirement"] == 1 || setup["TimeMatchingRequirement"] == 2)

			## Extract dual variables of constraints
	# Electricity price: Dual variable of hourly power balance constraint = hourly price
		dfPrice = DataFrame(TMR = 1:nH2_TMR) # The unit is $/MWh

	# Dividing dual variable for each hour with corresponding hourly weight to retrieve marginal cost of generation
	dfPrice = hcat(dfPrice, DataFrame(dual.(EP[:cH2TMR])./transpose(inputs["omega"] * SCALING), :auto))

	auxNew_Names=[Symbol("Zone");[Symbol("t$t") for t in 1:T]]
	rename!(dfPrice,auxNew_Names)

	## Linear configuration final output
	CSV.write(string(path,sep,"TMR_prices.csv"), dftranspose(dfPrice, false), writeheader=false)
	

	else # annual time matching scenario (TimeMatchingRequirement = 3)
	
		dfPrice = DataFrame(TMR_Price = convert(Array{Union{Missing, Float64}}, dual.(EP[:cH2TMR_Annual])))

		if setup["ParameterScale"] == 1
			dfPrice[!,:TMR_Price] = dfPrice[!,:TMR_Price] * SCALING # Converting MillionUS$/GWh to US$/MWh
		end
	
	
	CSV.write(string(path,sep,"TMR_prices.csv"), dfPrice)

	end
	
	return dfPrice

end
