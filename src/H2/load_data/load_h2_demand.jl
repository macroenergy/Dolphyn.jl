function load_h2_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs_gen::Dict)
    
    H2_load_in = DataFrame(CSV.File(string(path,sep,"H2_Load_data.csv"), header=true), copycols=true)

    # Number of demand curtailment/lost load segments
	inputs_load["H2_SEG"]=size(collect(skipmissing(H2_load_in[!,:Demand_Segment])),1)

    # Demand in MW for each zone
	#println(names(load_in))
	start = findall(s -> s == "Load_H2_z1", names(H2_load_in))[1] #gets the starting column number of all the columns, with header "Load_H2_z1"
	
	# Max value of non-served energy
	inputs_load["H2_Voll"] = collect(skipmissing(H2_load_in[!,:Voll]))
	# Demand in Tons
	inputs_load["H2_D"] =Matrix(H2_load_in[1:inputs_load["T"],start:start-1+inputs_load["Z"]]) #form a matrix with columns as the different zonal load H2 demand values and rows as the hours
	

    # Cost of non-served energy/demand curtailment (for each segment)
	H2_SEG = inputs_load["H2_SEG"]  # Number of demand segments
	inputs_load["pC_H2_D_Curtail"] = zeros(H2_SEG)
	inputs_load["pMax_H2_D_Curtail"] = zeros(H2_SEG)
	for s in 1:H2_SEG
		# Cost of each segment reported as a fraction of value of non-served energy - scaled implicitly
		inputs_load["pC_H2_D_Curtail"][s] = collect(skipmissing(H2_load_in[!,:Cost_of_Demand_Curtailment_per_Tonne]))[s]*inputs_load["Voll"][1]
		# Maximum hourly demand curtailable as % of the max demand (for each segment)
		inputs_load["pMax_H2_D_Curtail"][s] = collect(skipmissing(H2_load_in[!,:Max_Demand_Curtailment]))[s]
	end
    
    # #Read in H2 generation related inputs
    # h2_dr_var_in = DataFrame(CSV.File(string(path,sep,"H2_dr_variability.csv"), header=true), copycols=true)
    # #Read in H2 generation related inputs
    # h2_dr_in = DataFrame(CSV.File(string(path,sep,"H2_dr.csv"), header=true), copycols=true)
    # #Read in H2 generation related inputs
    # h2_trans_demand = DataFrame(CSV.File(string(path,sep,"hydrogen_transportation_demand.csv"), header=true), copycols=true)

    # # Store DataFrame of generators/resources input data for use in model
	# inputs_gen["dfH2DR"] = h2_gen_in
    # # Store DataFrame of generators/resources input data for use in model
	# inputs_gen["dfH2DRVar"] = h2_gen_in
    # # Store DataFrame of generators/resources input data for use in model
	# inputs_gen["dfH2TransDemand"] = h2_gen_in

    # # Number of H2 Generation resources
	# inputs_gen["H"] = size(collect(skipmissing(h2_gen_in[!,:R_ID])),1)

   
    # #Set of all H2 Generation Units
    # inputs_gen["H2_GEN_ALL"] = union(inputs_gen["H2_GEN_COMMIT"],inputs_gen["H2_GEN_NO_COMMIT"])

    # # Set of all resources eligible for new capacity
	# inputs_gen["H2_GEN_NEW_CAP"] = intersect(h2_gen_in[h2_gen_in.New_Build.==1,:R_ID], h2_gen_in[h2_gen_in.Max_Cap_Tonne_Hr.!=0,:R_ID])
	# # Set of all resources eligible for capacity retirements
	# inputs_gen["H2_GEN_RET_CAP"] = intersect(h2_gen_in[h2_gen_in.New_Build.!=-1,:R_ID], h2_gen_in[h2_gen_in.Existing_Cap_Tonne_Hr.>=0,:R_ID])

    return inputs_gen

end

