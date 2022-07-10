"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	load_co2_demand(setup::Dict, path::AbstractString, sep::AbstractString, CSC_inputs_load::Dict)


"""
function load_co2_demand(setup::Dict, path::AbstractString, sep::AbstractString, CSC_inputs_load::Dict)
    
	#data_directory = chop(replace(path, pwd() => ""), head = 1, tail = 0)
	data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory,"Load_data.csv")) && isfile(joinpath(data_directory,"Generators_variability.csv")) && isfile(joinpath(data_directory,"Fuels_data.csv")) && isfile(joinpath(data_directory,"HSC_load_data.csv")) && isfile(joinpath(data_directory,"HSC_generators_variability.csv")) && isfile(joinpath(data_directory,"CSC_load_data.csv")) && isfile(joinpath(data_directory,"CSC_capture_variability.csv")) # Use Time Domain Reduced data for GenX
		CO2_load_in = DataFrame(CSV.File(string(joinpath(data_directory,"CSC_load_data.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		CO2_load_in = DataFrame(CSV.File(string(path,sep,"CSC_load_data.csv"), header=true), copycols=true)
	end

    # Number of demand curtailment/lost load segments
	CSC_inputs_load["CO2_SEG"]=size(collect(skipmissing(CO2_load_in[!,:Demand_Segment])),1)

    # Demand in tonnes per hour for each zone
	start = findall(s -> s == "Load_CO2_tonne_per_hr_z1", names(CO2_load_in))[1] #gets the starting column number of all the columns, with header "Load_CO2_z1"
	
	# Max value of non-served energy in $/(tonne)
	CSC_inputs_load["CO2_Voll"] = collect(skipmissing(CO2_load_in[!,:Voll]))
	# Demand in Tonnes per hour
	CSC_inputs_load["CO2_D"] =Matrix(CO2_load_in[1:CSC_inputs_load["T"],start:start-1+CSC_inputs_load["Z"]]) #form a matrix with columns as the different zonal load CO2 demand values and rows as the hours
    
	# Cost of non-served energy/demand curtailment (for each segment)
	CO2_SEG = CSC_inputs_load["CO2_SEG"]  # Number of demand segments
	CSC_inputs_load["pC_CO2_D_Curtail"] = zeros(CO2_SEG)
	CSC_inputs_load["pMax_CO2_D_Curtail"] = zeros(CO2_SEG)
	for s in 1:CO2_SEG
		# Cost of each segment reported as a fraction of value of non-served energy - scaled implicitly
		CSC_inputs_load["pC_CO2_D_Curtail"][s] = collect(skipmissing(CO2_load_in[!,:Cost_of_Demand_Curtailment_per_Tonne]))[s]*CSC_inputs_load["Voll"][1]
		# Maximum hourly demand curtailable as % of the max demand (for each segment)
		CSC_inputs_load["pMax_CO2_D_Curtail"][s] = collect(skipmissing(CO2_load_in[!,:Max_Demand_Curtailment]))[s]
	end

	println("CSC_load_data.csv Successfully Read!")

    return CSC_inputs_load

end
