

@doc raw"""
    write_h2_charge(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the h2 storage charging values of the different hydrogen storage technologies.
"""
function write_h2_charge(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    dfH2Gen = inputs["dfH2Gen"]::DataFrame
    H = inputs["H2_RES_ALL"]::Int     # Number of resources (generators, storage, DR, and DERs)
    T = inputs["T"]::Int     # Number of time steps (hours)
    # Power withdrawn to charge each resource in each time step
    dfCharge = DataFrame(Resource = inputs["H2_RESOURCES_NAME"], Zone = dfH2Gen[!,:Zone], AnnualSum =  Array{Union{Missing,Float32}}(undef, H))
    charge = zeros(H,T)
    if !isempty(inputs["H2_STOR_ALL"])
        charge[inputs["H2_STOR_ALL"],:] = value.(EP[:vH2_CHARGE_STOR][inputs["H2_STOR_ALL"],:])
    end
    if !isempty(inputs["H2_FLEX"])
        charge[inputs["H2_FLEX"],:] = value.(EP[:vH2_CHARGE_FLEX][inputs["H2_FLEX"],:])
    end

    dfCharge.AnnualSum .= charge * inputs["omega"]

    dfCharge = hcat(dfCharge, DataFrame(charge, :auto))
    auxNew_Names=[Symbol("Resource");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
    rename!(dfCharge,auxNew_Names)
    total = DataFrame(["Total" 0 sum(dfCharge[!,:AnnualSum]) fill(0.0, (1,T))], :auto)
    for t in 1:T
        if v"1.3" <= VERSION < v"1.4"
            total[!,t+3] .= sum(dfCharge[!,Symbol("t$t")][union(inputs["H2_STOR_ALL"],inputs["H2_FLEX"])])
        elseif v"1.4" <= VERSION < v"1.9"
            total[:,t+3] .= sum(dfCharge[:,Symbol("t$t")][union(inputs["H2_STOR_ALL"],inputs["H2_FLEX"])])
        end
    end
    rename!(total,auxNew_Names)
    dfCharge = vcat(dfCharge, total)
    CSV.write(joinpath(path, "HSC_charge.csv"), dftranspose(dfCharge, false), writeheader=false)
    return dfCharge
end
