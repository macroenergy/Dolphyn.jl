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
	# Set of h2 resources eligible for unit committment - either continuous or discrete capacity -set by setup["H2GenCommit"]
	inputs_gen["H2_GEN_COMMIT"] = intersect(h2_gen_in[h2_gen_in.H2_GEN_TYPE.==1 ,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!=1 ,:R_ID])
	# Set of h2 resources eligible for unit committment
	inputs_gen["H2_GEN_NO_COMMIT"] = intersect(h2_gen_in[h2_gen_in.H2_GEN_TYPE.==0 ,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!=1 ,:R_ID])

	
    #Set of all H2 production Units - can be either commit or new commit
    inputs_gen["H2_GEN"] = union(inputs_gen["H2_GEN_COMMIT"],inputs_gen["H2_GEN_NO_COMMIT"])

    # Set of all resources eligible for new capacity
	# Dharik Qn: why do we need to check for H2_FLEX in all cases?
	inputs_gen["H2_GEN_NEW_CAP"] = intersect(h2_gen_in[h2_gen_in.New_Build.==1 ,:R_ID], h2_gen_in[h2_gen_in.Max_Cap_tonne_p_hr.!=0,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!= 1,:R_ID]) 
	# Set of all resources eligible for capacity retirements
	# Dharik Qn: why do we need to check for H2_FLEX in all cases?
	inputs_gen["H2_GEN_RET_CAP"] = intersect(h2_gen_in[h2_gen_in.New_Build.!=-1,:R_ID], h2_gen_in[h2_gen_in.Existing_Cap_Tonne_p_Hr.>=0,:R_ID], h2_gen_in[h2_gen_in.H2_FLEX.!=1,:R_ID])

	# Fixed cost per start-up ($ per MW per start) if unit commitment is modelled
	start_cost = convert(Array{Float64}, collect(skipmissing(inputs_gen["dfH2Gen"][!,:Start_Cost_per_tonne_p_hr])))
	#inputs_gen["C_H2_Start"] = zeros(Float64,  size(inputs_gen["H2_RES_ALL"],1), inputs_gen["T"])

	inputs_gen["C_H2_Start"] = inputs_gen["dfH2Gen"][!,:Cap_Size_tonne_p_hr].* start_cost
	
	# Direct CO2 emissions per tonne of H2 produced for various technologies
	inputs_gen["dfH2Gen"][!,:CO2_per_tonne] = zeros(Float64, inputs_gen["H2_RES_ALL"])

	
	#### TO DO LATER ON - CO2 constraints

	# for k in 1:inputs_gen["H2_RES_ALL"]
	# 	# NOTE: When Setup[ParameterScale] =1, fuel costs and emissions are scaled in fuels_data.csv, so no if condition needed to scale C_Fuel_per_MWh
	# 	# IF ParameterScale = 1, then CO2 emissions intensity Units ktonne/tonne
	# 	# If ParameterScale = 0 , then CO2 emission intensity units is tonne/tonne
	# 	inputs_gen["dfH2Gen"][!,:CO2_per_tonne][g] =inputs_gen["fuel_CO2"][dfH2Gen[!,:Fuel][k]][t] * dfH2Gen[!,:etaFuel_MMBtu_per_tonne][k]))

	# end

	println("H2_generation.csv Successfully Read!")

    return inputs_gen

end

