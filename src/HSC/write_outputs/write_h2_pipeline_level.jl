

@doc raw"""
    write_h2_pipeline_level(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)

Function for reporting hydrogen storage level for each pipeline.
"""
function write_h2_pipeline_level(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)

    P = inputs["H2_P"]  # Number of H2 pipelines
    T = inputs["T"]::Int  # Model operating time steps

    p = zeros(P, T)
    dfH2PipelineLevel = DataFrame(Pipelines = 1:P)

    for i in 1:P
        p[i, :] = value.(EP[:vH2PipeLevel][i, :])
    end

    dfH2PipelineLevel = hcat(dfH2PipelineLevel, DataFrame(p, :auto))
    auxNew_Names=[Symbol("Pipelines");[Symbol("t$t") for t in 1:T]]
    rename!(dfH2PipelineLevel, auxNew_Names)
    CSV.write(joinpath(path, "HSC_h2_pipeline_level.csv"), dftranspose(dfH2PipelineLevel, false), writeheader=false)
end