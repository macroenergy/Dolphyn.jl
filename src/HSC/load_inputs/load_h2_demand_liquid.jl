"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
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
    load_h2_demand_liquid(setup::Dict, path::AbstractString, sep::AbstractString, inputs_load::Dict)

Function for reading input parameters related to liquid hydrogen load (demand) of each zone. The columns should be labeled as "Load_liqH2_tonne_per_hr_zX" where X is the zone number.
"""
function load_h2_demand_liquid(setup::Dict, path::AbstractString, sep::AbstractString, inputs_load::Dict)
    
    data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
    if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory,"HSC_load_data_liquid.csv")) # Use Time Domain Reduced data for GenX
        H2_load_in = DataFrame(CSV.File(joinpath(data_directory,"HSC_load_data_liquid.csv"), header=true), copycols=true)
    else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
        H2_load_in = DataFrame(CSV.File(joinpath(path, "HSC_load_data_liquid.csv"), header=true), copycols=true)
    end

    # Number of demand curtailment/lost load segments
    inputs_load["H2_SEG_L"]=size(collect(skipmissing(H2_load_in[!,:Demand_Segment])),1)

    # Demand in tonnes per hour for each zone
    start = findall(s -> s == "Load_liqH2_tonne_per_hr_z1", names(H2_load_in))[1] #gets the starting column number of all the columns, with header "Load_H2_z1"
    
    # Max value of non-served energy in $/(tonne)
    inputs_load["H2_Voll_L"] = collect(skipmissing(H2_load_in[!,:Voll]))
    # Demand in Tonnes per hour
    inputs_load["H2_D_L"] =Matrix(H2_load_in[1:inputs_load["T"],start:start-1+inputs_load["Z"]]) #form a matrix with columns as the different zonal load H2 demand values and rows as the hours
    

    # Cost of non-served energy/demand curtailment (for each segment)
    H2_SEG = inputs_load["H2_SEG_L"]  # Number of demand segments
    inputs_load["pC_H2_D_Curtail_L"] = zeros(H2_SEG)
    inputs_load["pMax_H2_D_Curtail_L"] = zeros(H2_SEG)
    for s in 1:H2_SEG
        # Cost of each segment reported as a fraction of value of non-served energy - scaled implicitly
        inputs_load["pC_H2_D_Curtail_L"][s] = collect(skipmissing(H2_load_in[!,:Cost_of_Demand_Curtailment_per_Tonne]))[s]*inputs_load["Voll"][1]
        # Maximum hourly demand curtailable as % of the max demand (for each segment)
        inputs_load["pMax_H2_D_Curtail_L"][s] = collect(skipmissing(H2_load_in[!,:Max_Demand_Curtailment]))[s]
    end
    
    print_and_log(" -- HSC_load_data_liquid.csv Successfully Read!")

    return inputs_load

end

