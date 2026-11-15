@doc raw"""
	write_price(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting marginal electricity price for each model zone and time step. Marginal electricity price is equal to the dual variable of the load balance constraint. If GenX is configured as a mixed integer linear program, then this output is only generated if `WriteShadowPrices` flag is activated. If configured as a linear program (i.e. linearized unit commitment or economic dispatch) then output automatically available.
"""
function write_price_propylene(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Extract dual variables of constraints
	omega = inputs["omega"]
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    dual_values = dual.(EP[:cPropylene_Balance_T]) ./ omega * scale_factor

    # --- Convert to array and fix shape automatically ---
    dual_array = Array(dual_values)
    nd = ndims(dual_array)

    if nd == 1
        len = length(dual_array)
        if len == T * Z
            dual_array = reshape(dual_array, (T, Z))'
        elseif len == Z * T
            dual_array = reshape(dual_array, (Z, T))
        elseif len == T
            dual_array = repeat(dual_array', Z, 1)  # same hourly value across zones
        elseif len == Z
            dual_array = repeat(dual_array, 1, T)   # same zonal value across hours
        else
            error("Unexpected size of dual array: length = $len, expected T=$T, Z=$Z")
        end
    elseif size(dual_array, 1) == T && size(dual_array, 2) == Z
        dual_array = dual_array'
    elseif size(dual_array, 1) != Z
        @warn "Dual array orientation uncertain; transposing to match Z×T"
        dual_array = dual_array'
    end

	    # --- Construct DataFrame ---
    dfPrice = DataFrame(Zone = 1:Z)
    dfPrice.AnnualMean = [mean(skipmissing(dual_array[z, :])) for z in 1:Z]

    for t in 1:T
        dfPrice[!, Symbol("t$t")] = dual_array[:, t]
    end

	    # --- Save and return ---
    CSV.write(joinpath(path, "prices_propylene_pertonne.csv"), dftranspose(dfPrice, false), writeheader = false)
    return dfPrice

	#=

	# Dividing dual variable for each hour with corresponding hourly weight to retrieve marginal cost of generation
	dfPrice = hcat(dfPrice, DataFrame(AnnualMean=Array{Union{Missing,Float32}}(undef, Z)), DataFrame(transpose(dual.(EP[:cEthylene_Balance_T_Z])./inputs["omega"]*scale_factor), :auto))

	auxNew_Names=[Symbol("Zone");Symbol("AnnualMean");[Symbol("t$t") for t in 1:T]]
	rename!(dfPrice,auxNew_Names)

        dfPrice.AnnualMean .= [sum(dfPrice[i, r"t"])/T for i in 1:Z]

	## Linear configuration final output
	CSV.write(joinpath(path, "prices_ethylene_pertonne.csv"), dftranspose(dfPrice, false), writeheader=false)
	return dfPrice
	=#
end
