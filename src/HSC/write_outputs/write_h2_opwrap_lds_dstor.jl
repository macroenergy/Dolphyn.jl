function write_h2_opwrap_lds_dstor(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Extract data frames from input dictionary
	W = inputs["REP_PERIOD"]     # Number of subperiods
	dfH2Gen = inputs["dfH2Gen"]
	H = inputs["H2_RES_ALL"]

	#Excess inventory of storage period built up during representative period w
	dfdStorage = DataFrame(Resource = inputs["H2_RESOURCES_NAME"], Zone = dfH2Gen[!,:Zone])
	dsoc = zeros(H,W)
	for i in 1:H
		if i in inputs["H2_STOR_LONG_DURATION"]
			dsoc[i,:] = value.(EP[:vdH2SOC])[i,:]
		end
	end
	dfdStorage = hcat(dfdStorage, DataFrame(dsoc, :auto))
	auxNew_Names=[Symbol("Resource");Symbol("Zone");[Symbol("w$t") for t in 1:W]]
	rename!(dfdStorage,auxNew_Names)	
	CSV.write(string(path,sep,"HSC_dStorage.csv"), dftranspose(dfdStorage, false), writeheader=false)
end
