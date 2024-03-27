

@doc raw"""
	load_liquid_fuel_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

Function for reading input parameters related to liquid fuel load (demand) and emissions of each zone for each type of fuel (Gasoline, Jetfuel, Diesel).
"""
function load_liquid_fuel_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)
    
	data_directory_diesel = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_diesel,"Load_data.csv")) && isfile(joinpath(data_directory_diesel,"Generators_variability.csv")) && isfile(joinpath(data_directory_diesel,"Fuels_data.csv")) && isfile(joinpath(data_directory_diesel,"HSC_load_data.csv")) && isfile(joinpath(data_directory_diesel,"HSC_generators_variability.csv")) && isfile(joinpath(data_directory_diesel,"Liquid_Fuels_Diesel_Demand.csv")) # Use Time Domain Reduced data for GenX
		Liquid_Fuels_Diesel_demand_in = DataFrame(CSV.File(string(joinpath(data_directory_diesel,"Liquid_Fuels_Diesel_Demand.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		Liquid_Fuels_Diesel_demand_in = DataFrame(CSV.File(string(path,sep,"Liquid_Fuels_Diesel_Demand.csv"), header=true), copycols=true)
	end

    # Demand in tonnes per hour for each zone
	#println(names(load_in))
	start_diesel = findall(s -> s == "Load_mmbtu_z1", names(Liquid_Fuels_Diesel_demand_in))[1] #gets the start_dieseling column number of all the columns, with header "Load_H2_z1"
	
	# Demand in Tonnes per hour
	inputs["Liquid_Fuels_Diesel_D"] =Matrix(Liquid_Fuels_Diesel_demand_in[1:inputs["T"],start_diesel:start_diesel-1+inputs["Z"]]) #form a matrix with columns as the different zonal load H2 demand values and rows as the hours
    
    inputs["Conventional_diesel_co2_per_mmbtu"] = Liquid_Fuels_Diesel_demand_in[!, "Conventional_diesel_co2_per_mmbtu"][1]
    inputs["Conventional_diesel_price_per_mmbtu"] = Liquid_Fuels_Diesel_demand_in[!, "Conventional_diesel_price_per_mmbtu"][1]
    inputs["Syn_diesel_co2_per_mmbtu"] = Liquid_Fuels_Diesel_demand_in[!, "Syn_diesel_co2_per_mmbtu"][1]
	#inputs["Bio_diesel_co2_per_mmbtu"] = Liquid_Fuels_Diesel_demand_in[!, "Bio_diesel_co2_per_mmbtu"][1]

	println("Liquid_Fuels_Diesel_demand.csv Successfully Read!")

	###########################################################################################################################################

	data_directory_jetfuel = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_jetfuel,"Load_data.csv")) && isfile(joinpath(data_directory_jetfuel,"Generators_variability.csv")) && isfile(joinpath(data_directory_jetfuel,"Fuels_data.csv")) && isfile(joinpath(data_directory_jetfuel,"HSC_load_data.csv")) && isfile(joinpath(data_directory_jetfuel,"HSC_generators_variability.csv")) && isfile(joinpath(data_directory_jetfuel,"Liquid_Fuels_Jetfuel_Demand.csv")) # Use Time Domain Reduced data for GenX
		Liquid_Fuels_Jetfuel_demand_in = DataFrame(CSV.File(string(joinpath(data_directory_jetfuel,"Liquid_Fuels_Jetfuel_Demand.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		Liquid_Fuels_Jetfuel_demand_in = DataFrame(CSV.File(string(path,sep,"Liquid_Fuels_Jetfuel_Demand.csv"), header=true), copycols=true)
	end

	# Demand in tonnes per hour for each zone
	#println(names(load_in))
	start_jetfuel = findall(s -> s == "Load_mmbtu_z1", names(Liquid_Fuels_Jetfuel_demand_in))[1] #gets the start_jetfueling column number of all the columns, with header "Load_H2_z1"

	# Demand in Tonnes per hour
	inputs["Liquid_Fuels_Jetfuel_D"] =Matrix(Liquid_Fuels_Jetfuel_demand_in[1:inputs["T"],start_jetfuel:start_jetfuel-1+inputs["Z"]]) #form a matrix with columns as the different zonal load H2 demand values and rows as the hours

	inputs["Conventional_jetfuel_co2_per_mmbtu"] = Liquid_Fuels_Jetfuel_demand_in[!, "Conventional_jetfuel_co2_per_mmbtu"][1]
	inputs["Conventional_jetfuel_price_per_mmbtu"] = Liquid_Fuels_Jetfuel_demand_in[!, "Conventional_jetfuel_price_per_mmbtu"][1]
	inputs["Syn_jetfuel_co2_per_mmbtu"] = Liquid_Fuels_Jetfuel_demand_in[!, "Syn_jetfuel_co2_per_mmbtu"][1]
	#inputs["Bio_jetfuel_co2_per_mmbtu"] = Liquid_Fuels_Jetfuel_demand_in[!, "Bio_jetfuel_co2_per_mmbtu"][1]

	println("Liquid_Fuels_Jetfuel_demand.csv Successfully Read!")

	###########################################################################################################################################

	data_directory_gasoline = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_gasoline,"Load_data.csv")) && isfile(joinpath(data_directory_gasoline,"Generators_variability.csv")) && isfile(joinpath(data_directory_gasoline,"Fuels_data.csv")) && isfile(joinpath(data_directory_gasoline,"HSC_load_data.csv")) && isfile(joinpath(data_directory_gasoline,"HSC_generators_variability.csv")) && isfile(joinpath(data_directory_gasoline,"Liquid_Fuels_Gasoline_Demand.csv")) # Use Time Domain Reduced data for GenX
		Liquid_Fuels_Gasoline_Demand_in = DataFrame(CSV.File(string(joinpath(data_directory_gasoline,"Liquid_Fuels_Gasoline_Demand.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		Liquid_Fuels_Gasoline_Demand_in = DataFrame(CSV.File(string(path,sep,"Liquid_Fuels_Gasoline_Demand.csv"), header=true), copycols=true)
	end

    # Demand in tonnes per hour for each zone
	#println(names(load_in))
	start_gasoline = findall(s -> s == "Load_mmbtu_z1", names(Liquid_Fuels_Gasoline_Demand_in))[1] #gets the start_gasolineing column number of all the columns, with header "Load_H2_z1"
	
	# Demand in Tonnes per hour
	inputs["Liquid_Fuels_Gasoline_D"] = Matrix(Liquid_Fuels_Gasoline_Demand_in[1:inputs["T"],start_gasoline:start_gasoline-1+inputs["Z"]]) #form a matrix with columns as the different zonal load H2 demand values and rows as the hours
    
    inputs["Conventional_gasoline_co2_per_mmbtu"] = Liquid_Fuels_Gasoline_Demand_in[!, "Conventional_gasoline_co2_per_mmbtu"][1]
    inputs["Conventional_gasoline_price_per_mmbtu"] = Liquid_Fuels_Gasoline_Demand_in[!, "Conventional_gasoline_price_per_mmbtu"][1]
    inputs["Syn_gasoline_co2_per_mmbtu"] = Liquid_Fuels_Gasoline_Demand_in[!, "Syn_gasoline_co2_per_mmbtu"][1]
	#inputs["Bio_gasoline_co2_per_mmbtu"] = Liquid_Fuels_Gasoline_Demand_in[!, "Bio_gasoline_co2_per_mmbtu"][1]

	println("Liquid_Fuels_Gasoline_Demand.csv Successfully Read!")

    return inputs

end

