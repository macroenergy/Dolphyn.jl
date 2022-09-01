"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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
	load_syn_fuels_gen(path::AbstractString, setup::Dict, inputs::Dict)

"""
function load_syn_fuels_gen(path::AbstractString, setup::Dict, inputs::Dict)

    # Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)
    Zones = inputs["Zones"] # List of modeled zones

    # Read in H2 generation related inputs
    Syn_gen_in = DataFrame(
        CSV.File(joinpath(path, "Syn_generation.csv"), header = true),
        copycols = true,
    )

    # Filter resources in modeled zones
    Syn_gen_in = filter(row -> (row.Zone in Zones), Syn_gen_in)

    # Add Resource IDs after reading to prevent user errors
    Syn_gen_in[!, :R_ID] = 1:size(collect(skipmissing(Syn_gen_in[!, 1])), 1)

    # Store DataFrame of generators/resources input data for use in model
    inputs["dfSynGen"] = Syn_gen_in

    # Index of H2 resources - can be either commit, no_commit production technologies, demand side, G2P, or storage resources
    inputs["SYN_RES_ALL"] = size(collect(skipmissing(Syn_gen_in[!, :R_ID])), 1)

    # Name of H2 Generation resources
    inputs["SYN_RESOURCES_NAME"] =
        collect(skipmissing(Syn_gen_in[!, :H2_Resource][1:inputs["H2_RES_ALL"]]))

    # Resource identifiers by zone (just zones in resource order + resource and zone concatenated)
    syn_zones = collect(skipmissing(Syn_gen_in[!, :Zone][1:inputs["SYN_RES_ALL"]]))
    inputs["SYN_R_ZONES"] = syn_zones
    inputs["SYN_RESOURCE_ZONES"] =
        inputs["SYN_RESOURCES_NAME"] .* "_z" .* string.(syn_zones)

    # Set of flexible demand-side resources
    inputs["SYN_FLEX"] = Syn_gen_in[Syn_gen_in.SYN_FLEX.==1, :R_ID]

    # To do - will add a list of storage resources or we can keep them separate
    # Set of H2 storage resources
    inputs["SYN_STOR_SYMMETRIC"] = Syn_gen_in[Syn_gen_in.SYN_STOR.==1, :R_ID]
    inputs["SYN_STOR_ASYMMETRIC"] = Syn_gen_in[Syn_gen_in.SYN_STOR.==2, :R_ID]
    inputs["SYN_STOR_ALL"] =
        union(inputs["SYN_STOR_SYMMETRIC"], inputs["SYN_STOR_ASYMMETRIC"])

    # Defining whether H2 storage is modeled as long-duration (inter-period energy transfer allowed) or short-duration storage (inter-period energy transfer disallowed)
    inputs["SYN_STOR_LONG_DURATION"] =
        Syn_gen_in[(Syn_gen_in.LDS.==1).&(Syn_gen_in.SYN_STOR.==1), :R_ID]
    inputs["SYN_STOR_SHORT_DURATION"] =
        Syn_gen_in[(Syn_gen_in.LDS.==0).&(Syn_gen_in.SYN_STOR.==1), :R_ID]

    # Set of hydrogen generation plants with CCS
    inputs["SYN_CCS"] = Syn_gen_in[Syn_gen_in.CCS.==1, :R_ID]

    # Set of all storage resources eligible for new energy capacity
    inputs["NEW_CAP_SYN_ENERGY"] = intersect(
        Syn_gen_in[Syn_gen_in.New_Build.==1, :R_ID],
        Syn_gen_in[Syn_gen_in.Max_Energy_Cap_tonne.!=0, :R_ID],
        inputs["SYN_STOR_ALL"],
    )
    # Set of all storage resources eligible for energy capacity retirements
    inputs["RET_CAP_SYN_ENERGY"] = intersect(
        Syn_gen_in[Syn_gen_in.New_Build.!=-1, :R_ID],
        Syn_gen_in[Syn_gen_in.Existing_Energy_Cap_tonne.>0, :R_ID],
        inputs["SYN_STOR_ALL"],
    )

    # Set of asymmetric charge/discharge storage resources eligible for new charge capacity, which for H2 storage refers to compression power requirements
    inputs["NEW_CAP_SYN_CHARGE"] = intersect(
        Syn_gen_in[Syn_gen_in.New_Build.==1, :R_ID],
        Syn_gen_in[Syn_gen_in.Max_Charge_Cap_tonne_p_hr.!=0, :R_ID],
        inputs["SYN_STOR_ALL"],
    )
    # Set of asymmetric charge/discharge storage resources eligible for charge capacity retirements
    inputs["RET_CAP_SYN_CHARGE"] = intersect(
        Syn_gen_in[Syn_gen_in.New_Build.!=-1, :R_ID],
        Syn_gen_in[Syn_gen_in.Existing_Charge_Cap_tonne_p_hr.>0, :R_ID],
        inputs["SYN_STOR_ALL"],
    )

    # Set of H2 generation resources
    # Set of h2 resources eligible for unit committment - either continuous or discrete capacity -set by setup["SYNGenCommit"]
    inputs["SYN_GEN_COMMIT"] = intersect(
        Syn_gen_in[Syn_gen_in.SYN_GEN_TYPE.==1, :R_ID],
        Syn_gen_in[Syn_gen_in.SYN_FLEX.!=1, :R_ID],
    )
    # Set of h2 resources eligible for unit committment
    inputs["SYN_GEN_NO_COMMIT"] = intersect(
        Syn_gen_in[Syn_gen_in.SYN_GEN_TYPE.==2, :R_ID],
        Syn_gen_in[Syn_gen_in.SYN_FLEX.!=1, :R_ID],
    )

    #Set of all H2 production Units - can be either commit or new commit
    inputs["SYN_GEN"] = union(inputs["SYN_GEN_COMMIT"], inputs["SYN_GEN_NO_COMMIT"])

    # Set of all resources eligible for new capacity - includes both storage and generation
    # DEV NOTE: Should we allow investment in flexible demand capacity later on?
    inputs["SYN_GEN_NEW_CAP"] = intersect(
        Syn_gen_in[Syn_gen_in.New_Build.==1, :R_ID],
        Syn_gen_in[Syn_gen_in.Max_Cap_tonne_p_hr.!=0, :R_ID],
        Syn_gen_in[Syn_gen_in.SYN_FLEX.!=1, :R_ID],
    )
    # Set of all resources eligible for capacity retirements
    # DEV NOTE: Should we allow retirement of flexible demand capacity later on?
    inputs["SYN_GEN_RET_CAP"] = intersect(
        Syn_gen_in[Syn_gen_in.New_Build.!=-1, :R_ID],
        Syn_gen_in[Syn_gen_in.Existing_Cap_tonne_p_hr.>=0, :R_ID],
        Syn_gen_in[Syn_gen_in.SYN_FLEX.!=1, :R_ID],
    )

    # Fixed cost per start-up ($ per MW per start) if unit commitment is modelled
    start_cost = convert(
        Array{Float64},
        collect(skipmissing(inputs["dfSynGen"][!, :Start_Cost_per_tonne_p_hr])),
    )

    inputs["C_Syn_Start"] = inputs["dfSynGen"][!, :Cap_Size_tonne_p_hr] .* start_cost

    # Direct CO2 emissions per tonne of H2 produced for various technologies
    inputs["dfSynGen"][!, :CO2_per_tonne] = zeros(Float64, inputs["SYN_RES_ALL"])


    #### TO DO LATER ON - CO2 constraints

    # for k in 1:inputs["H2_RES_ALL"]
    # 	# NOTE: When Setup[ParameterScale] =1, fuel costs and emissions are scaled in fuels_data.csv, so no if condition needed to scale C_Fuel_per_MWh
    # 	# IF ParameterScale = 1, then CO2 emissions intensity Units ktonne/tonne
    # 	# If ParameterScale = 0 , then CO2 emission intensity units is tonne/tonne
    # 	inputs["dfSynGen"][!,:CO2_per_tonne][g] =inputs["fuel_CO2"][dfSynGen[!,:Fuel][k]][t] * dfSynGen[!,:etaFuel_MMBtu_p_tonne][k]))

    # end

    println("Syn_generation.csv Successfully Read!")

    return inputs

end
