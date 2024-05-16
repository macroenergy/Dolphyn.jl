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

# Methods to simplify the process of running DOLPHYN cases

"""
    load_settings(settings_path::AbstractString) :: Dict{Any, Any}

Loads Global, GenX and HSC settings and returns a merged settings dict called mysetup
"""
function load_settings(settings_path::AbstractString)
    genx_settings_path = joinpath(settings_path, "genx_settings.yml") #Settings YAML file path for GenX
    mysetup_genx = configure_settings(genx_settings_path) # mysetup dictionary stores GenX-specific parameters

    hsc_settings_path = joinpath(settings_path, "hsc_settings.yml") #Settings YAML file path for HSC  model
    if isfile(hsc_settings_path)
        mysetup_hsc = YAML.load(open(hsc_settings_path)) # mysetup dictionary stores H2 supply chain-specific parameters
    else
        mysetup_hsc = Dict()
    end

    csc_settings_path = joinpath(settings_path, "csc_settings.yml") #Settings YAML file path for CSC model
    if isfile(csc_settings_path)
        mysetup_csc = YAML.load(open(csc_settings_path)) # mysetup dictionary stores CSC supply chain-specific parameters
    else
        mysetup_csc = Dict()
    end 

    lf_settings_path = joinpath(settings_path, "lf_settings.yml") #Settings YAML file path for LF model
    if isfile(lf_settings_path)
        mysetup_lf = YAML.load(open(lf_settings_path)) # mysetup dictionary stores CSC supply chain-specific parameters
    else
        mysetup_lf = Dict()
    end 

    global_settings_path = joinpath(settings_path, "global_model_settings.yml") # Global settings for inte
    mysetup_global = YAML.load(open(global_settings_path)) # mysetup dictionary stores global settings

    mysetup = Dict{Any,Any}()
    mysetup = merge(mysetup_hsc, mysetup_genx, mysetup_csc, mysetup_lf, mysetup_global) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings
    mysetup = configure_settings(mysetup)

    return mysetup
end

function setup_logging(mysetup::Dict{Any, Any})
    # Start logging
    global Log = mysetup["Log"]
    if Log
        logger = FileLogger(mysetup["LogFile"])
        return global_logger(logger)
    end
    return nothing
end

function notAllFilesExist(path::String, f_list::Vector{String})
    v_c = findall(ispath(joinpath(path,f)) for f in f_list)
    if length(v_c) < length(f_list) 
        return true
    end
    return false
end

function setup_TDR(inputs_path::String, settings_path::String, mysetup::Dict{Any,Any})
    TDRpath = joinpath(inputs_path, mysetup["TimeDomainReductionFolder"])
    genx_tdr_file_list = ["Load_data.csv", "Generators_variability.csv", "Fuels_data.csv"]
    H2_tdr_file_list = append!(genx_tdr_file_list, ["HSC_generators_variability.csv", "HSC_load_data.csv", "HSC_g2p_variability"])

    if mysetup["TimeDomainReduction"] == 1
        if mysetup["ModelH2"] == 1
	        if notAllFilesExist(TDRpath, H2_tdr_file_list)
                print_and_log("Clustering Time Series Data...")
                cluster_inputs(inputs_path, settings_path, mysetup)
            else
                print_and_log("Time Series Data Already Clustered.")
            end
        else
	    if notAllFilesExist(TDRpath, genx_tdr_file_list)
                print_and_log("Clustering Time Series Data...")
                cluster_inputs(inputs_path, settings_path, mysetup)
            else
                print_and_log("Time Series Data Already Clustered.")
            end
        end
    end

    if mysetup["ModelCSC"] == 1
        print_and_log("CSC and SF TDR not implemented.")
    end
end
