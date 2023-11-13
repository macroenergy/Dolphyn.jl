@doc raw"""
	load_ccs_rate(setup::Dict, path::AbstractString, inputs_gen::Dict, fuel_costs::Dict, fuel_CO2::Dict)

"""
function load_ccs_rate(setup::Dict, inputs_gen::Dict )

    filename = "Generators_data.csv"
    gen_in = inputs_gen["dfGen"]

	fuel_costs = inputs_gen["fuel_costs"]
	fuel_CO2 = inputs_gen["fuel_CO2"]

    # Set indices for internal use
	G = inputs_gen["G"]   # Number of resources (generators, storage, DR, and DERs)

    # Heat rate of all resources (million BTUs/MWh)
	heat_rate = convert(Array{Float64}, collect(skipmissing(gen_in[!,:Heat_Rate_MMBTU_per_MWh])) )
	# Fuel used by each resource
	fuel_type = collect(skipmissing(gen_in[!,:Fuel]))
	# Maximum fuel cost in $ per MWh and CO2 emissions in tons per MWh
	inputs_gen["C_Fuel_per_MWh"] = zeros(Float64, G, inputs_gen["T"])
	inputs_gen["dfGen"][!,:CO2_per_MWh] = zeros(Float64, G)
	inputs_gen["dfGen"][!,:CO2_captured_per_MWh] = zeros(Float64, G)

	#CO2 capture rate of all resources (%)
	ccs_rate = convert(Array{Float64}, collect(skipmissing(gen_in[!,:CCS_Rate])) )

	for g in 1:G
		# NOTE: When Setup[ParameterScale] =1, fuel costs are scaled in fuels_data.csv, so no if condition needed to scale C_Fuel_per_MWh
		inputs_gen["C_Fuel_per_MWh"][g,:] = fuel_costs[fuel_type[g]].*heat_rate[g]

		inputs_gen["dfGen"][!,:CO2_per_MWh][g] = fuel_CO2[fuel_type[g]]*heat_rate[g]*(1-ccs_rate[g])
		inputs_gen["dfGen"][!,:CO2_captured_per_MWh][g] = fuel_CO2[fuel_type[g]]*heat_rate[g]*(ccs_rate[g])

		if setup["ParameterScale"] ==1
			inputs_gen["dfGen"][!,:CO2_per_MWh][g] = inputs_gen["dfGen"][!,:CO2_per_MWh][g] * ModelScalingFactor
			inputs_gen["dfGen"][!,:CO2_captured_per_MWh][g] = inputs_gen["dfGen"][!,:CO2_captured_per_MWh][g] * ModelScalingFactor
		end

    end
  
	println(filename * " CCS Rate Successfully Read!")

	return inputs_gen
end
