

@doc raw"""
    write_h2_nse(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting non-served hydrogen for every model zone, time step and cost-segment.
"""
function write_h2_nse(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    dfGen = inputs["dfGen"]
    T = inputs["T"]::Int     # Number of time steps (hours)
    Z = inputs["Z"]::Int     # Number of zones
    H2_SEG = inputs["H2_SEG"] # Number of load curtailment segments
    # Non-served energy/demand curtailment by segment in each time step
    dfNse = DataFrame()
    dfTemp = Dict()
    for z in 1:Z
        dfTemp = DataFrame(Segment=zeros(H2_SEG), Zone=zeros(H2_SEG), AnnualSum = Array{Union{Missing,Float32}}(undef, H2_SEG))
        dfTemp[!,:Segment] = (1:H2_SEG)
        dfTemp[!,:Zone] = fill(z,(H2_SEG))

        h2nse = value.(EP[:vH2NSE][:, :, z])
    
        dfTemp.AnnualSum .= h2nse * inputs["omega"] 

        dfTemp = hcat(dfTemp, DataFrame(h2nse, :auto))
        
        if z == 1
            dfNse = dfTemp
        else
            dfNse = vcat(dfNse,dfTemp)
        end
    end

    auxNew_Names=[Symbol("Segment");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
    rename!(dfNse,auxNew_Names)
    total = DataFrame(["Total" 0 sum(dfNse[!,:AnnualSum]) fill(0.0, (1,T))], :auto)
    for t in 1:T
        if v"1.3" <= VERSION < v"1.4"
            total[!,t+3] .= sum(dfNse[!,Symbol("t$t")][1:Z])
        elseif v"1.4" <= VERSION < v"1.9"
            total[:,t+3] .= sum(dfNse[:,Symbol("t$t")][1:Z])
        end
    end
    rename!(total,auxNew_Names)
    dfNse = vcat(dfNse, total)

    CSV.write(joinpath(path, "HSC_nse.csv"),  dftranspose(dfNse, false), writeheader=false)
    return dfTemp
end
