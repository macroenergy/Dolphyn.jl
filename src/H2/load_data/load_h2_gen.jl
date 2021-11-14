function load_h2_gen(setup::Dict, path::AbstractString, sep::AbstractString, inputs_gen::Dict)
    #Read in H2 generation related inputs
    h2_gen_in = DataFrame(CSV.File(string(path,sep,"h2_generation.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	h2_gen_in[!,:R_ID] = 1:size(collect(skipmissing(h2_gen_in[!,1])),1)

    # Store DataFrame of generators/resources input data for use in model
	inputs_gen["dfH2Gen"] = h2_gen_in

    # Number of H2 Generation resources
	inputs_gen["H"] = size(collect(skipmissing(h2_gen_in[!,:R_ID])),1)

    # Set of thermal generator resources
	if setup["UCommit"]>=1
		# Set of h2 resources eligible for unit committment
		inputs_gen["H2_GEN_COMMIT"] = h2_gen_in[h2_gen_in.unit_commit.==1,:R_ID]
		# Set of h2 resources eligible for unit committment
		inputs_gen["H2_GEN_NO_COMMIT"] = h2_gen_in[h2_gen_in.unit_commit.==0,:R_ID]
	else # When UCommit == 0, no thermal resources are eligible for unit committment
		inputs_gen["H2_GEN_COMMIT"]= Int64[]
		inputs_gen["H2_GEN_NO_COMMIT"] = union(h2_gen_in[h2_gen_in.unit_commit.==1,:R_ID], h2_gen_in[h2_gen_in.unit_commit.==0,:R_ID])
	end
	
    #Set of all H2 Generation Units
    inputs_gen["H2_GEN_ALL"] = union(inputs_gen["H2_GEN_COMMIT"],inputs_gen["H2_GEN_NO_COMMIT"])

    # Set of all resources eligible for new capacity
	inputs_gen["H2_GEN_NEW_CAP"] = intersect(h2_gen_in[h2_gen_in.New_Build.==1,:R_ID], h2_gen_in[h2_gen_in.Max_Cap_Tonne_Hr.!=0,:R_ID])
	# Set of all resources eligible for capacity retirements
	inputs_gen["H2_GEN_RET_CAP"] = intersect(h2_gen_in[h2_gen_in.New_Build.!=-1,:R_ID], h2_gen_in[h2_gen_in.Existing_Cap_Tonne_Hr.>=0,:R_ID])

    return inputs_gen

end

inpath = pwd()
myinputs = Dict() # myinputs dictionary will store read-in data and computed parameters

settings_path = joinpath(pwd(), "Settings")
genx_settings = joinpath(settings_path, "genx_settings.yml") #Settings YAML file path
mysetup = YAML.load(open(genx_settings)) # mysetup dictionary stores settings and GenX-specific parameters


inputs = load_h2_gen(mysetup, inpath, "/", myinputs)