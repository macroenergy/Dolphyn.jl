function load_h2_gen(setup::Dict, path::AbstractString, sep::AbstractString, inputs_gen::Dict)

	#Read in H2 generation related inputs
    h2_gen_in = DataFrame(CSV.File(string(path,sep,"h2_generation.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	h2_gen_in[!,:R_ID] = 1:size(collect(skipmissing(h2_gen_in[!,1])),1)

    # Store DataFrame of generators/resources input data for use in model
	inputs_gen["dfH2Gen"] = h2_gen_in

    # Index of H2 resources - can be either commit, no_commit production technologies, demand side or storage resources
	inputs_gen["H2_RES_ALL"] = size(collect(skipmissing(h2_gen_in[!,:R_ID])),1)

	# Name of H2 Generation resources
	inputs_gen["H2_RESOURCES_NAME"] = collect(skipmissing(h2_gen_in[!,:H2_Resource][1:inputs_gen["H2_RES_ALL"]]))

	# Set of flexible demand-side resources
	inputs_gen["H2_FLEX"] = h2_gen_in[h2_gen_in.H2_FLEX.==1,:R_ID]

	# To do - will add a list of storage resources or we can keep them separate

    # Set of thermal generator resources
	if setup["UCommit"]>=1
		# Set of h2 resources eligible for unit committment
		inputs_gen["H2_GEN_COMMIT"] = intersect(h2_gen_in[h2_gen_in.unit_commit.==1 ,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!=1 ,:R_ID])
		# Set of h2 resources eligible for unit committment
		inputs_gen["H2_GEN_NO_COMMIT"] = intersect(h2_gen_in[h2_gen_in.unit_commit.==0 ,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!=1 ,:R_ID])
	else # When UCommit == 0, no thermal resources are eligible for unit committment
		inputs_gen["H2_GEN_COMMIT"]= Int64[]
		inputs_gen["H2_GEN_NO_COMMIT"] = h2_gen_in[h2_gen_in.H2_FLEX.!=1 ,:R_ID]
	end
	
    #Set of all H2 production Units - can be either commit or new commit
    inputs_gen["H2_PROD"] = union(inputs_gen["H2_GEN_COMMIT"],inputs_gen["H2_GEN_NO_COMMIT"])

    # Set of all resources eligible for new capacity
	# Dharik Qn: why do we need to check for H2_FLEX in all cases?
	inputs_gen["H2_GEN_NEW_CAP"] = intersect(h2_gen_in[h2_gen_in.New_Build.==1 ,:R_ID], h2_gen_in[h2_gen_in.Max_Cap_Tonne_Hr.!=0,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!= 1,:R_ID]) 
	# Set of all resources eligible for capacity retirements
	# Dharik Qn: why do we need to check for H2_FLEX in all cases?
	inputs_gen["H2_GEN_RET_CAP"] = intersect(h2_gen_in[h2_gen_in.New_Build.!=-1,:R_ID], h2_gen_in[h2_gen_in.Existing_Cap_Tonne_Hr.>=0,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!=1,:R_ID])

	if setup["UCommit"]>=1
		# Fixed cost per start-up ($ per MW per start) if unit commitment is modelled
		start_cost = convert(Array{Float64}, collect(skipmissing(inputs_gen["dfH2Gen"][!,:Start_Cost_per_tonne_hr])))
		inputs_gen["C_H2_Start"] = zeros(Float64, inputs_gen["H2_GEN"], inputs_gen["T"])
	end
	println(inputs_gen["H2_PROD"])
	for k in inputs_gen["H2_PROD"]

		# kton/MMBTU * MMBTU/MWh = kton/MWh, to get kton/GWh, we need to mutiply 1000
		if k in inputs_gen["H2_GEN_COMMIT"]
			# Start-up cost is sum of fixed cost per start plus cost of fuel consumed on startup.

			inputs_gen["C_H2_Start"][k,:] .= inputs_gen["dfH2Gen"][!,:Cap_Size][k] * start_cost[k]
			
		end
	end

	println("H2_generation.csv Successfully Read!")

    return inputs_gen

end

