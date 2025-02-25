

@doc raw"""
    load_h2_generators_variability(setup::Dict, path::AbstractString, sep::AbstractString, inputs_genvar::Dict)

Function for reading input parameters related to hourly maximum capacity factors for all hydrogen generators (plus storage).
"""
function load_h2_generators_variability(setup::Dict, path::AbstractString, sep::AbstractString, inputs_genvar::Dict)

    # Hourly capacity factors
    #data_directory = data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
    data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
    if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory,"HSC_generators_variability.csv")) # Use Time Domain Reduced data for GenX
        gen_var = DataFrame(CSV.File(string(joinpath(data_directory,"HSC_generators_variability.csv")), header=true), copycols=true)
    else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
        gen_var = DataFrame(CSV.File(joinpath(path, "HSC_generators_variability.csv"), header=true), copycols=true)
    end

    # Reorder DataFrame to R_ID order (order provided in Generators_data.csv)
    select!(gen_var, [:Time_Index; Symbol.(inputs_genvar["H2_RESOURCES_NAME"]) ])

    # Maximum power output and variability of each energy resource
    inputs_genvar["pH2_Max"] = transpose(Matrix{Float64}(gen_var[1:inputs_genvar["T"],2:(inputs_genvar["H2_RES_ALL"]+1)]))

    print_and_log(" -- HSC_generators_variability.csv Successfully Read!")

    return inputs_genvar
end
