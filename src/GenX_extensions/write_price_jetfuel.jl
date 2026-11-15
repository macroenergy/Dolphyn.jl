function write_price_jetfuel(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    T = inputs["T"]     # Number of time steps
    Z = inputs["Z"]     # Number of zones
    omega = inputs["omega"]
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    # --- Select appropriate dual variable based on setup ---
    if setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 1
        dual_values = dual.(EP[:cLFJetfuelBalance_T_Z]) ./ omega * scale_factor
    elseif setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 0
        dual_values = dual.(EP[:cLFJetfuelBalance_Z]) ./ omega * scale_factor
    elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 1
        dual_values = dual.(EP[:cLFJetfuelBalance_T]) ./ omega * scale_factor
    else
        dual_values = dual.(EP[:cLFJetfuelBalance]) ./ omega * scale_factor
    end

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
    CSV.write(joinpath(path, "prices_jetfuel_permmbtu.csv"), dftranspose(dfPrice, false), writeheader = false)
    return dfPrice
end
