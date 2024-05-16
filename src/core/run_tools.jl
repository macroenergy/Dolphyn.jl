# Methods to simplify the process of running DOLPHYN cases

"""
    load_settings(settings_path::AbstractString) :: Dict{Any, Any}

Loads Global, GenX and HSC settings and returns a merged settings dict called mysetup
"""
function load_settings(settings_path::AbstractString)
    genx_settings_path = joinpath(settings_path, "genx_settings.yml") #Settings YAML file path for GenX
    if isfile(genx_settings_path)
        mysetup_genx = configure_settings(genx_settings_path) # mysetup dictionary stores GenX-specific parameters
    else
        mysetup_genx = Dict()
    end

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

    besc_settings_path = joinpath(settings_path, "besc_settings.yml") #Settings YAML file path for BESC model
    if isfile(lf_settings_path)
        mysetup_besc = YAML.load(open(besc_settings_path)) # mysetup dictionary stores CSC supply chain-specific parameters
    else
        mysetup_besc = Dict()
    end 

    global_settings_path = joinpath(settings_path, "global_model_settings.yml") # Global settings for inte
    if isfile(global_settings_path)
        mysetup_global = YAML.load(open(global_settings_path)) # mysetup dictionary stores global settings
    else
        error("A global settings file is required to run Dolphyn")
    end

    mysetup = Dict{Any,Any}()
    mysetup = merge(mysetup_hsc, mysetup_genx, mysetup_csc, mysetup_lf, mysetup_besc, mysetup_global) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings
    mysetup = configure_settings(mysetup)

    return mysetup
end

function load_all_inputs(mysetup::Dict{String, Any}, inputs_path::AbstractString)
    myinputs = Dict{String, Any}() # myinputs dictionary will store read-in data and computed parameters

    # To do: make this conditional on modelling the electricity sector
    myinputs = load_inputs(mysetup, inputs_path)

    # ### Load H2 inputs if modeling the hydrogen supply chain
    if mysetup["ModelH2"] == 1
        myinputs = load_h2_inputs(myinputs, mysetup, inputs_path)
    end

    # ### Load CO2 inputs if modeling the carbon supply chain
    if mysetup["ModelCSC"] == 1
        myinputs = load_co2_inputs(myinputs, mysetup, inputs_path)
    end

    ### Load LF inputs if modeling the liquid fuels supply chain
    if mysetup["ModelLiquidFuels"] == 1
        myinputs = load_liquid_fuels_inputs(myinputs, mysetup, inputs_path)
    end

    ### Load BESC inputs if modeling the bioenergy supply chain
    if mysetup["ModelBESC"] == 1
        myinputs = load_bio_inputs(myinputs, mysetup, inputs_path)
    end

    return myinputs

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

function setup_TDR(inputs_path::String, settings_path::String, mysetup::Dict{Any,Any})
    TDRpath = joinpath(inputs_path, mysetup["TimeDomainReductionFolder"])
    if mysetup["TimeDomainReduction"] == 1
        if mysetup["ModelH2"] == 1
            if (!isfile(TDRpath*"/Load_data.csv")) || (!isfile(TDRpath*"/Generators_variability.csv")) || (!isfile(TDRpath*"/Fuels_data.csv")) || (!isfile(TDRpath*"/HSC_generators_variability.csv")) || (!isfile(TDRpath*"/HSC_load_data.csv"))
                print_and_log("Clustering Time Series Data...")
                cluster_inputs(inputs_path, settings_path, mysetup)
            else
                print_and_log("Time Series Data Already Clustered.")
            end
        else
            if (!isfile(TDRpath*"/Load_data.csv")) || (!isfile(TDRpath*"/Generators_variability.csv")) || (!isfile(TDRpath*"/Fuels_data.csv"))
                print_and_log("Clustering Time Series Data...")
                cluster_inputs(inputs_path, settings_path, mysetup)
            else
                print_and_log("Time Series Data Already Clustered.")
            end
        end
    end

    if mysetup["ModelCSC"] == 1
        print_and_log("CSC TDR not implemented.")
    end

    if mysetup["ModelLiquidFuels"] == 1
        print_and_log("LFSC TDR not implemented.")
    end

    if mysetup["ModelBESC"] == 1
        print_and_log("BESC TDR not implemented.")
    end
end

function write_all_outputs(EP::Model, mysetup::Dict{Any, Any}, myinputs::Dict{Any, Any}, inputs_path::String)
    outpath = joinpath(inputs_path, "Results")
    outpath_GenX = write_outputs(EP, outpath, mysetup, myinputs)

    # Write hydrogen supply chain outputs
    if mysetup["ModelH2"] == 1
        write_HSC_outputs(EP, outpath_GenX, mysetup, myinputs)
    end

    # Write carbon supply chain outputs
    if mysetup["ModelCSC"] == 1
        write_CSC_outputs(EP, outpath_GenX, mysetup, myinputs)
    end

    # Write liquid fuels supply chain outputs
    if mysetup["ModelLiquidFuels"] == 1
        write_liquid_fuels_outputs(EP, outpath_GenX, mysetup, myinputs)
    end

    ### Write bioenergy  supply chain outputs
    if mysetup["ModelBESC"] == 1
        myinputs = write_bio_outputs(myinputs, mysetup, inputs_path)
    end

    return nothing

end