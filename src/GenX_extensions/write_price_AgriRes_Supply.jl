@doc raw"""
	write_price(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting marginal electricity price for each model zone and time step. Marginal electricity price is equal to the dual variable of the load balance constraint. If GenX is configured as a mixed integer linear program, then this output is only generated if `WriteShadowPrices` flag is activated. If configured as a linear program (i.e. linearized unit commitment or economic dispatch) then output automatically available.
"""
function write_price_AgriRes_Supply(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    T = inputs["T"]
    K = inputs["AGRI_RES_SUPPLY_RES_ALL"]
    omega = inputs["omega"]

    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    # Extract dual values as a matrix (K × T)
    dual_matrix = Array(dual.(EP[:cAgri_Res_biomass_Max]))

    # Scale each column by omega[t]
    for t in 1:T
        dual_matrix[:, t] .= dual_matrix[:, t] ./ omega[t]
    end

    dual_matrix .*= scale_factor

    # Build DataFrame
    dfDual = DataFrame(Resource = 1:K)
    dfDual = hcat(dfDual,
                  DataFrame(AnnualMean = Vector{Float64}(undef, K)),
                  DataFrame(dual_matrix, :auto)
                 )

    # Rename time columns
    colNames = [Symbol("Resource"); Symbol("AnnualMean"); [Symbol("t$t") for t in 1:T]...]
    rename!(dfDual, colNames)

    # Compute annual mean per resource
    dfDual.AnnualMean .= [sum(dfDual[i, r"t"]) / T for i in 1:K]

    # Write transposed CSV
    CSV.write(joinpath(path, "prices_AgriRes_Supply.csv"),
              dftranspose(dfDual, false),
              writeheader = false)

    return dfDual
end