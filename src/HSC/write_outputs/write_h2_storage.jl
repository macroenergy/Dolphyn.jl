

@doc raw"""
	write_h2_storage(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)

Function for reporting the capacities of different hydrogen storage technologies, including hydro reservoir, flexible storage tech etc.
"""
function write_h2_storage(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)
	dfH2Gen = inputs["dfH2Gen"]::DataFrame
	T = inputs["T"]::Int     # Number of time steps (hours)
	H = inputs["H2_RES_ALL"]::Int  # Set of H2 storage resources

	# Storage level (state of charge) of each resource in each time step
	dfH2Storage = DataFrame(Resource = inputs["H2_RESOURCES_NAME"], Zone = dfH2Gen[!,:Zone])
	s = zeros(H,T)
	storagevcapvalue = zeros(H,T)
	for i in 1:H
		if i in inputs["H2_STOR_ALL"]
			s[i,:] = value.(EP[:vH2S])[i,:]
		elseif i in inputs["H2_FLEX"]
			s[i,:] = value.(EP[:vS_H2_FLEX])[i,:]
		end
	end

	# Incorporating effect of Parameter scaling (ParameterScale=1) on output values
	for y in 1:H
		storagevcapvalue[y,:] = s[y,:]
	end


	dfH2Storage = hcat(dfH2Storage, DataFrame(storagevcapvalue, :auto))
	auxNew_Names=[Symbol("Resource");Symbol("Zone");[Symbol("t$t") for t in 1:T]]
	rename!(dfH2Storage,auxNew_Names)
	CSV.write(string(path,sep,"HSC_storage.csv"), dftranspose(dfH2Storage, false), writeheader=false)
end
