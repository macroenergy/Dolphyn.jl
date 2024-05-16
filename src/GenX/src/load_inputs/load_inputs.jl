@doc raw"""
	load_inputs(setup::Dict,path::AbstractString)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing all data inputs
"""
function load_inputs(setup::Dict,path::AbstractString)

	## Read input files
	println("Reading Input CSV Files")
	## Declare Dict (dictionary) object used to store parameters
	inputs = Dict()
	# Read input data about power network topology, operating and expansion attributes
    system_path = joinpath(path, "inputs/genx", setup["SystemFolder"])
    policies_path = joinpath(path, "inputs/genx", setup["PoliciesFolder"])
    resources_path = joinpath(path, "inputs/genx", setup["ResourcesFolder"])

	if isfile(joinpath(system_path,"Network.csv"))
		network_var = load_network_data!(setup, system_path, inputs)
	else
		inputs["Z"] = 1
		inputs["L"] = 0
	end

	# Read temporal-resolved load data, and clustering information if relevant
	load_load_data!(setup, system_path, path, inputs)
	# Read fuel cost data, including time-varying fuel costs
	cost_fuel, CO2_fuel = load_fuels_data!(setup, system_path, path, inputs)
	# Read in generator/resource related inputs
	load_generators_data!(setup, resources_path, inputs, cost_fuel, CO2_fuel)
	# Read in generator/resource availability profiles
	load_generators_variability!(setup, system_path, path, inputs)

    validatetimebasis(inputs)

	if setup["CapacityReserveMargin"]==1
		load_cap_reserve_margin!(setup, policies_path, inputs)
		if inputs["Z"] >1
			load_cap_reserve_margin_trans!(setup, inputs, network_var)
		end
	end

	# Read in general configuration parameters for reserves (resource-specific reserve parameters are read in generators_data())
	if setup["Reserves"]==1
		load_reserves!(setup, policies_path, inputs)
	end

	if setup["MinCapReq"] == 1
		load_minimum_capacity_requirement!(policies_path, inputs, setup)
	end

	if setup["MaxCapReq"] == 1
		load_maximum_capacity_requirement!(policies_path, inputs, setup)
	end

	if setup["EnergyShareRequirement"]==1
		load_energy_share_requirement!(setup, policies_path, inputs)
	end

	if setup["CO2Cap"] >= 1
		load_co2_cap!(setup, policies_path, inputs)
	end

	# Read in mapping of modeled periods to representative periods
	if is_period_map_necessary(inputs) && is_period_map_exist(setup, system_path, inputs)
		load_period_map!(setup, system_path, inputs)
	end

	println("CSV Files Successfully Read In From $path/inputs/genx/system, $path/inputs/genx/resources and $path/inputs/policies")

	return inputs
end

function is_period_map_necessary(inputs::Dict)
	multiple_rep_periods = inputs["REP_PERIOD"] > 1
	has_stor_lds = !isempty(inputs["STOR_LONG_DURATION"])
	has_hydro_lds = !isempty(inputs["STOR_HYDRO_LONG_DURATION"])
    multiple_rep_periods && (has_stor_lds || has_hydro_lds)
end

function is_period_map_exist(setup::Dict, path::AbstractString, inputs::Dict)
	filename = "Period_map.csv"
	is_here = isfile(joinpath(system_path, filename))
	is_in_folder = isfile(joinpath(path, setup["TimeDomainReductionFolder"], filename))
	is_here || is_in_folder
end
