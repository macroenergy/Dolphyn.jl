@doc raw"""
	write_nse(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

Function for reporting non-served energy for every model zone, time step and cost-segment.
"""
function write_co2_nse(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
    CO2_SEG = inputs["CO2_SEG"] # Number of load curtailment segments
	# Non-served energy/demand curtailment by segment in each time step
	dfNse = DataFrame()
	dfTemp = Dict()
	for z in 1:Z
		dfTemp = DataFrame(Segment=zeros(CO2_SEG), Zone=zeros(CO2_SEG), AnnualSum = Array{Union{Missing,Float32}}(undef, CO2_SEG))
		dfTemp[!,:Segment] = (1:CO2_SEG)
		dfTemp[!,:Zone] = fill(z,(CO2_SEG))
		
			for i in 1:CO2_SEG
				dfTemp[!,:AnnualSum][i] = sum(inputs["omega"].* (value.(EP[:vCO2NSE])[i,:,z]))
			end
			dfTemp = hcat(dfTemp, DataFrame(value.(EP[:vCO2NSE])[:,:,z], :auto))
		
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
		elseif v"1.4" <= VERSION < v"1.8"
			total[:,t+3] .= sum(dfNse[:,Symbol("t$t")][1:Z])
		end
	end
	rename!(total,auxNew_Names)
	dfNse = vcat(dfNse, total)

	CSV.write(joinpath(path, "CSC_nse.csv"),  dftranspose(dfNse, false), writeheader=false)
end