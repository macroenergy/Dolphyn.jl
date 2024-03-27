

@doc raw"""
    write_h2_pipeline_flow(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the hydrogen flow via pipeliens.    
"""
function write_h2_pipeline_flow(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    dfH2Gen = inputs["dfH2Gen"]::DataFrame
    T = inputs["T"]::Int     # Number of time steps (hours)
    Z = inputs["Z"]::Int     # Number of zones
    H2_P= inputs["H2_P"] # Number of Hydrogen Pipelines
    H2_Pipe_Map = inputs["H2_Pipe_Map"]

    ## Power balance for each zone
    dfPowerBalance = Array{Any}
    rowoffset=3
    for p in 1:H2_P
        dfTemp1 = Array{Any}(nothing, T+rowoffset, 3)
        dfTemp1[1,1:size(dfTemp1,2)] = ["Source_Zone_H2_Net", "Sink_Zone_H2_Net", "Pipe_Level"]

        dfTemp1[2,1:size(dfTemp1,2)] = repeat([p],size(dfTemp1,2))
        
        zone_value1 = filter.(isdigit, ([H2_Pipe_Map[(H2_Pipe_Map[!,:d] .== 1) .& (H2_Pipe_Map[!,:pipe_no] .== p), :][!,:zone_str][1]][1]))
        zone_value2 = filter.(isdigit, ([H2_Pipe_Map[(H2_Pipe_Map[!,:d] .== -1) .& (H2_Pipe_Map[!,:pipe_no] .== p), :][!,:zone_str][1]][1])) 
        dfTemp1[3,1:size(dfTemp1,2)] = [zone_value1,zone_value2,"NA"]

        for t in 1:T
            dfTemp1[t+rowoffset,1]= value.(EP[:eH2PipeFlow_net][p,t,1])
            dfTemp1[t+rowoffset,2] = value.(EP[:eH2PipeFlow_net][p,t,-1])
            dfTemp1[t+rowoffset,3] = value.(EP[:vH2PipeLevel][p,t])
        end

        if p==1
            dfPowerBalance =  hcat(vcat(["", "Pipe", "Zone"], ["t$t" for t in 1:T]), dfTemp1)
        else
            dfPowerBalance = hcat(dfPowerBalance, dfTemp1)
        end
    end

    dfPowerBalance = DataFrame(dfPowerBalance, :auto)
    CSV.write(joinpath(path, "HSC_h2_pipeline_flow.csv"), dfPowerBalance, writeheader=false)
end
