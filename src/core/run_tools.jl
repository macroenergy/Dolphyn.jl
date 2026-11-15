# Methods to simplify the process of running DOLPHYN cases
using HiGHS

"""
    load_settings(settings_path::AbstractString) :: Dict{String, Any}

Loads Global, GenX and HSC settings and returns a merged settings dict called mysetup
"""
function load_settings(settings_path::AbstractString)
    genx_settings_path = joinpath(settings_path, "genx_settings.yml") #Settings YAML file path for GenX
    if isfile(genx_settings_path)
        mysetup_genx = configure_settings(genx_settings_path) # mysetup dictionary stores GenX-specific parameters
    else
        mysetup_genx = Dict{String,Any}()
    end

    hsc_settings_path = joinpath(settings_path, "hsc_settings.yml") #Settings YAML file path for HSC  model
    if isfile(hsc_settings_path)
        mysetup_hsc = YAML.load(open(hsc_settings_path)) # mysetup dictionary stores H2 supply chain-specific parameters
    else
        mysetup_hsc = Dict{String,Any}()
    end

    csc_settings_path = joinpath(settings_path, "csc_settings.yml") #Settings YAML file path for CSC model
    if isfile(csc_settings_path)
        mysetup_csc = YAML.load(open(csc_settings_path)) # mysetup dictionary stores CSC supply chain-specific parameters
    else
        mysetup_csc = Dict{String,Any}()
    end 

    lf_settings_path = joinpath(settings_path, "lf_settings.yml") #Settings YAML file path for LF model
    if isfile(lf_settings_path)
        mysetup_lf = YAML.load(open(lf_settings_path)) # mysetup dictionary stores CSC supply chain-specific parameters
    else
        mysetup_lf = Dict{String,Any}()
    end 

<<<<<<< Updated upstream
=======
    besc_settings_path = joinpath(settings_path, "besc_settings.yml") #Settings YAML file path for LF model
    if isfile(besc_settings_path)
        mysetup_besc = YAML.load(open(besc_settings_path)) # mysetup dictionary stores CSC supply chain-specific parameters
    else
        mysetup_besc = Dict{String,Any}()
    end 

    ng_settings_path = joinpath(settings_path, "ng_settings.yml") #Settings YAML file path for LF model
    if isfile(ng_settings_path)
        mysetup_ng = YAML.load(open(ng_settings_path)) # mysetup dictionary stores CSC supply chain-specific parameters
    else
        mysetup_ng = Dict{String,Any}()
    end 

    ethylene_settings_path = joinpath(settings_path, "Chemical_settings.yml") #Settings YAML file path for Chemical model
    if isfile(ethylene_settings_path)
        mysetup_ethylene = YAML.load(open(ethylene_settings_path)) # mysetup dictionary stores Chemical supply chain-specific parameters
    else
        mysetup_ethylene = Dict{String,Any}()
    end 

>>>>>>> Stashed changes
    global_settings_path = joinpath(settings_path, "global_model_settings.yml") # Global settings for inte
    if isfile(global_settings_path)
        mysetup_global = YAML.load(open(global_settings_path)) # mysetup dictionary stores global settings
    else
        error("A global settings file is required to run Dolphyn")
    end

    mysetup = Dict{String,Any}()
<<<<<<< Updated upstream
    merge!(mysetup, mysetup_genx, mysetup_hsc, mysetup_csc, mysetup_lf, mysetup_global) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings
=======
    merge!(mysetup, mysetup_genx, mysetup_hsc, mysetup_csc, mysetup_lf, mysetup_besc, mysetup_ng, mysetup_ethylene, mysetup_global) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings
>>>>>>> Stashed changes
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

    ### Load LF inputs if modeling the synthetic fuels supply chain
    if mysetup["ModelLiquidFuels"] == 1
        myinputs = load_liquid_fuels_inputs(myinputs, mysetup, inputs_path)
    end

<<<<<<< Updated upstream
=======
    ### Load BESC inputs if modeling the bioenergy  supply chain
    if mysetup["ModelBESC"] == 1
        myinputs = load_bio_inputs(myinputs, mysetup, inputs_path)
    end

    ### Load BESC inputs if modeling the bioenergy  supply chain
    if mysetup["ModelNGSC"] == 1
        myinputs = load_ng_inputs(myinputs, mysetup, inputs_path)
    end

    ## Load Ethylene inputs if modeling the ethylene production
    if mysetup["ModelChemicalProduction"] == 1
        myinputs = load_ethylene_inputs(myinputs, mysetup, inputs_path)	    
    end

    if mysetup["ModelEthanol"] == 1
        myinputs = load_ethanol_inputs(myinputs, mysetup, inputs_path)	    
    end

    if mysetup["ModelEthanePurchase"] == 1
        myinputs = load_ethane_inputs(myinputs, mysetup, inputs_path)	    
    end

    if mysetup["ModelPropylenePurchase"] == 1
        myinputs = load_propylene_inputs(myinputs, mysetup, inputs_path)	    
    end

>>>>>>> Stashed changes
    return myinputs

end

function setup_logging(mysetup::Dict{String, Any})
    # Start logging
    global Log = mysetup["Log"]
    if Log
        logger = FileLogger(mysetup["LogFile"])
        return global_logger(logger)
    end
    return nothing
end

function setup_TDR(inputs_path::AbstractString, settings_path::AbstractString, mysetup::Dict{String,Any}, TDR_files::Union{Nothing, Vector{String}}=nothing)

    if isnothing(TDR_files)
        TDR_files = String[]
        # Need to add check if electricity is being modelled
            append!(TDR_files, [
                "Load_data.csv",
                "Generators_variability.csv",
                "Fuels_data.csv"
            ])
        if mysetup["ModelH2"] == 1
            append!(TDR_files, [
                "HSC_generators_variability.csv",
                "HSC_load_data.csv"
            ])
        end
        if mysetup["ModelCSC"] == 1
            print_and_log("Carbon supply chain TDR not implemented.")
        end
        if mysetup["ModelLiquidFuels"] == 1
            print_and_log("Liquid Fuels TDR not implemented.")
        end

        if mysetup["ModelChemicalProduction"] == 1
            print_and_log("Chemical Production TDR not implemented.")
        end

        if mysetup["ModelEthanol"] == 1
            print_and_log("Ethanol Production TDR not implemented.")
        end

        if mysetup["ModelEthanePurchase"] == 1
            print_and_log("Ethane Production TDR not implemented.")
        end

        if mysetup["ModelPropylenePurchase"] == 1
            print_and_log("Propylene Production TDR not implemented.")
        end
    end

    TDR_path = joinpath(inputs_path, mysetup["TimeDomainReductionFolder"])
    TDR_filepaths = joinpath.(TDR_path, TDR_files)

    if mysetup["TimeDomainReduction"] == 1
        # If any of the TDR files are missing, cluster the data
        if any(!isfile, TDR_filepaths) || mysetup["Force_TDR_recluster"] == 1
            print_and_log("Clustering Time Series Data...")
            cluster_inputs(inputs_path, settings_path, mysetup)
        else
            print_and_log("Time Series Data Already Clustered.")
        end
    end
end

function write_all_outputs(EP::Model, mysetup::Dict{String, Any}, myinputs::Dict{String, Any}, inputs_path::AbstractString)
    outpath = joinpath(inputs_path, "Results")
    adjusted_outpath = write_outputs(EP, outpath, mysetup, myinputs)

    # Write hydrogen supply chain outputs
    if mysetup["ModelH2"] == 1
        write_HSC_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end

    # Write carbon supply chain outputs
    if mysetup["ModelCSC"] == 1
        write_CSC_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end

    # Write synthetic fuels supply chain outputs
    if mysetup["ModelLiquidFuels"] == 1
        write_liquid_fuels_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end

<<<<<<< Updated upstream
=======
    ### Write natural gas supply chain outputs
    if mysetup["ModelNGSC"] == 1
        write_ng_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end

    ### Write bioenergy supply chain outputs
    if mysetup["ModelBESC"] == 1
        write_bio_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end

    ### Ethylene outputs
    if mysetup["ModelChemicalProduction"] == 1
        write_ethylene_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end

    ### Ethylene outputs
    if mysetup["ModelEthanol"] == 1
        write_ethanol_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end

    if mysetup["ModelEthanePurchase"] == 1
        write_ethane_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end

    if mysetup["ModelPropylenePurchase"] == 1
        write_propylene_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end
    
>>>>>>> Stashed changes
    return adjusted_outpath

end

function generate_model(inputs_path::AbstractString, settings_path::AbstractString; optimizer::DataType=HiGHS.Optimizer, force_TDR_off::Bool=false, force_TDR_on::Bool=false, force_TDR_recluster::Bool=false)
    mysetup = load_settings(settings_path)
    global_logger = setup_logging(mysetup)

    # Check if TDR is forced on or off
    # If both are set to on, force_TDR_on will take precedence
    if force_TDR_on
        mysetup["TimeDomainReduction"] = 1
    elseif force_TDR_off
        mysetup["TimeDomainReduction"] = 0
    end

    if force_TDR_recluster
        mysetup["Force_TDR_recluster"] = 1
    end

    if mysetup["TimeDomainReduction"] == 1
        setup_TDR(inputs_path, settings_path, mysetup)
    end
    
    solver = configure_solver(settings_path, optimizer)
    myinputs = load_all_inputs(mysetup, inputs_path)
    EP = generate_model(mysetup, myinputs, solver)
    return EP, mysetup, myinputs
end

function generate_model(local_dir::AbstractString=@__DIR__; optimizer::DataType=HiGHS.Optimizer, force_TDR_off::Bool=false, force_TDR_on::Bool=false, force_TDR_recluster::Bool=false)
    settings_path = joinpath(local_dir, "Settings")
    inputs_path = local_dir
    return generate_model(inputs_path, settings_path; optimizer=optimizer, force_TDR_off=force_TDR_off, force_TDR_on=force_TDR_on, force_TDR_recluster=force_TDR_recluster)
end

function run_case(inputs_path::AbstractString, settings_path::AbstractString; optimizer::DataType=HiGHS.Optimizer, force_TDR_off::Bool=false, force_TDR_on::Bool=false, force_TDR_recluster::Bool=false)
    EP, mysetup, myinputs = generate_model(inputs_path, settings_path; optimizer=optimizer, force_TDR_off=force_TDR_off, force_TDR_on=force_TDR_on, force_TDR_recluster=force_TDR_recluster)
    EP, solve_time = solve_model(EP, mysetup)
    myinputs["solve_time"] = solve_time # Store the model solve time in myinputs
    adjusted_outpath = write_all_outputs(EP, mysetup, myinputs, inputs_path)
    return EP, myinputs, mysetup, adjusted_outpath
end

function run_case(local_dir::AbstractString=@__DIR__; optimizer::DataType=HiGHS.Optimizer, force_TDR_off::Bool=false, force_TDR_on::Bool=false, force_TDR_recluster::Bool=false)
    settings_path = joinpath(local_dir, "Settings")
    inputs_path = local_dir
    EP, myinputs, mysetup, adjusted_outpath = run_case(inputs_path, settings_path; optimizer=optimizer, force_TDR_off=force_TDR_off, force_TDR_on=force_TDR_on, force_TDR_recluster=force_TDR_recluster)
    return EP, myinputs, mysetup, adjusted_outpath
end

