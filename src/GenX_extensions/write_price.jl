@doc raw"""
	write_price(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting marginal electricity price for each model zone and time step. Marginal electricity price is equal to the dual variable of the load balance constraint. If GenX is configured as a mixed integer linear program, then this output is only generated if `WriteShadowPrices` flag is activated. If configured as a linear program (i.e. linearized unit commitment or economic dispatch) then output automatically available.
"""
function write_price(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	T = inputs["T"]::Int     # Number of time steps (hours)
	Z = inputs["Z"]::Int     # Number of zones

	## Extract dual variables of constraints
	# Electricity price: Dual variable of hourly power balance constraint = hourly price
	dfPrice = DataFrame(Zone = 1:Z) # The unit is $/MWh
	scale_factor = setup["scaling"]::Float64
	# Dividing dual variable for each hour with corresponding hourly weight to retrieve marginal cost of generation
	dfPrice = hcat(dfPrice, DataFrame(AnnualMean=Array{Union{Missing,Float32}}(undef, Z)), DataFrame(transpose(dual.(EP[:cPowerBalance])./inputs["omega"]*scale_factor), :auto))

	auxNew_Names=[Symbol("Zone");Symbol("AnnualMean");[Symbol("t$t") for t in 1:T]]
	rename!(dfPrice,auxNew_Names)

        dfPrice.AnnualMean .= [sum(dfPrice[i, r"t"])/T for i in 1:Z]

	## Linear configuration final output
	CSV.write(joinpath(path, "prices.csv"), dftranspose(dfPrice, false), writeheader=false)
	return dfPrice
end
