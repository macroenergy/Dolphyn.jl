function load_h2_flex(setup::Dict, path::AbstractString, sep::AbstractString, inputs_gen::Dict)

	#Read in H2 generation related inputs
    h2_flex_in = DataFrame(CSV.File(string(path,sep,"h2_flex_demand.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	h2_flex_in[!,:R_ID] = 1:size(collect(skipmissing(h2_flex_in[!,1])),1)

    # Store DataFrame of generators/resources input data for use in model
	inputs_gen["dfH2Flex"] = h2_flex_in

	# Set of flexible demand-side resources
	inputs_gen["H2_FLEX"] = h2_flex_in[h2_flex_in.H2_FLEX.==1,:R_ID]
  
	println("H2_flex_demand.csv Successfully Read!")

    return inputs_gen

end

