

@doc raw"""
    write_h2_pipeline_expansion(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the expansion of hydrogen pipelines.    
"""
function write_h2_pipeline_expansion(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

    L = inputs["H2_P"]     # Number of H2 pipelines

    Existing_Trans_Cap = zeros(L)
    transcap = zeros(L) # Transmission network reinforcements in tonne/hour
    Pipes = zeros(L)
    Fixed_Cost = zeros(L)

    for i in 1:L
        Existing_Trans_Cap = inputs["pH2_Pipe_Max_Flow"].*inputs["pH2_Pipe_No_Curr"]
        transcap[i] = (value.(EP[:vH2NPipe][i]) - inputs["pH2_Pipe_No_Curr"][i]).*inputs["pH2_Pipe_Max_Flow"][i]
        Pipes[i] = value.(EP[:vH2NPipe][i])
        Fixed_Cost[i] = (value.(EP[:vH2NPipe][i]) - inputs["pH2_Pipe_No_Curr"][i]) * inputs["pCAPEX_H2_Pipe"][i]
    end
    
    dfTransCap = DataFrame(
    Line = 1:L,
    Existing_Trans_Capacity = convert(Array{Union{Missing,Float32}}, Existing_Trans_Cap),
    New_Trans_Capacity = convert(Array{Union{Missing,Float32}}, transcap),
    Total_Pipes = convert(Array{Union{Missing,Float32}}, Pipes),
    Fixed_Cost_Pipes = convert(Array{Union{Missing,Float32}}, Fixed_Cost),
    )
    
    CSV.write(joinpath(path, "HSC_pipeline_expansion.csv"), dfTransCap)
end
