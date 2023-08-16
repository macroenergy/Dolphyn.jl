@doc raw"""
    load_external_elec_prices!(setup::Dict, path::AbstractString, inputs::Dict)

Read fixed electricity prices available to the HSC sector
"""
function load_external_elec_prices!(setup::Dict, path::AbstractString, inputs::Dict)

    data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
    if setup["TimeDomainReduction"] == 1  && time_domain_reduced_files_exist(data_directory)
        my_dir = data_directory
    else
        my_dir = path
    end
    filename = "HSC_elec_prices.csv"

    print("Reading $filename ... ")

    elec_prices_in = load_dataframe(joinpath(my_dir, filename))
    # For now we'll assume elec_prices_in has the same timeseries as everything else
    # so we can drop the first column
    elec_prices = Matrix{Float64}(elec_prices_in[:, 2:end])

    # If the model is scaled, then prices become $ / GWhe, not MWhe
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1
    if scale_factor != 1.0
        elec_prices .*= scale_factor
    end

    inputs["HSC_external_elec_price"] = elec_prices

    print("done!\n")

    return elec_prices
end