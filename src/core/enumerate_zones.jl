

@doc raw"""
    enumerate_zones(setup::Dict,path::AbstractString)

Loads various data inputs from multiple input .csv files in path directory and parse zonal information.

inputs:
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing updated zonal information
"""
function enumerate_zones(setup::Dict,path::AbstractString)

    print_and_log("Enumerating Zones")

    # if isfile(joinpath(path,"Network.csv"))
    #     network_var = DataFrame(CSV.File(joinpath(path,"Network.csv")))
    #     Zones = unique(union(network_var.Start_Zone, network_var.End_Zone))
    # end

    if setup["ModelH2"] == 1
        h2_gen = DataFrame(CSV.File(joinpath(path,"HSC_generation.csv")))
        Zones = unique(h2_gen.Zone)
        # if setup["ModelH2Pipelines"] == 1
        #     if isfile(joinpath(path,"HSC_pipelines.csv"))
        #         network_var = DataFrame(CSV.File(joinpath(path,"HSC_pipelines.csv")))
        #         # Zones = unique(union(network_var.Start_Zone, network_var.End_Zone, Zones))
        #         Zones = unique(union(network_var.Start_Zone, network_var.End_Zone))
        #     end
        # end
        ##TODO: add truck zone filter
    end

    print_and_log("Using Zones $(Zones)")
    return Zones
end
