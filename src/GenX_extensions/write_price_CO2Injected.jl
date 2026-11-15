function write_price_CO2Injected(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

    con = EP[:cMax_CO2_Injected_per_type_per_year_Kt]
    idx = collect(keys(con))

    # Detect dimension using k.I
    idxlen = length(first(idx).I)

    if idxlen == 1
        # ---------------------
        # 1-D CONSTRAINT (only k)
        # ---------------------
        Ks = sort(unique(k.I[1] for k in idx))
        K = length(Ks)
        T = inputs["T"]  # required for scaling

        dual_matrix = zeros(K, T)

        for (i, k) in enumerate(Ks)
            d = dual(con[k])
            dual_matrix[i, :] .= d ./ inputs["omega"]
        end

    elseif idxlen == 2
        # ------------------------------
        # 2-D CONSTRAINT (k,t)
        # ------------------------------
        Ks = sort(unique(k.I[1] for k in idx))
        Ts = sort(unique(k.I[2] for k in idx))
        K = length(Ks)
        T = length(Ts)

        dual_vec = [dual(con[(k, t)]) for k in Ks for t in Ts]
        dual_matrix = reshape(dual_vec, K, T)

        # scale by omega[t]
        for j in 1:T
            dual_matrix[:, j] ./= inputs["omega"][j]
        end

    else
        error("Unsupported constraint index dimension = $idxlen")
    end

    # Apply scaling
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1
    dual_matrix .*= scale_factor

    # Build DataFrame
    dfDual = DataFrame(Resource = 1:K)
    dfDual = hcat(dfDual,
                  DataFrame(AnnualMean = zeros(K)),
                  DataFrame(dual_matrix, :auto))

    colNames = [Symbol("Resource"); Symbol("AnnualMean"); [Symbol("t$t") for t in 1:T]...]
    rename!(dfDual, colNames)

    dfDual.AnnualMean .= [mean(dfDual[i, r"t"]) for i in 1:K]

    CSV.write(joinpath(path, "prices_CO2Injected.csv"),
              dftranspose(dfDual, false),
              writeheader = false)

    return dfDual
end
