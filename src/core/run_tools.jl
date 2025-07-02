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
        mysetup_lf = YAML.load(open(lf_settings_path)) # mysetup dictionary stores LF supply chain-specific parameters
    else
        mysetup_lf = Dict{String,Any}()
    end 

    besc_settings_path = joinpath(settings_path, "besc_settings.yml") #Settings YAML file path for Bioenergy model
    if isfile(besc_settings_path)
        mysetup_besc = YAML.load(open(besc_settings_path)) # mysetup dictionary stores bioenergy supply chain-specific parameters
    else
        mysetup_besc = Dict{String,Any}()
    end 

    ng_settings_path = joinpath(settings_path, "ng_settings.yml") #Settings YAML file path for NG model
    if isfile(ng_settings_path)
        mysetup_ng = YAML.load(open(ng_settings_path)) # mysetup dictionary stores NG supply chain-specific parameters
    else
        mysetup_ng = Dict{String,Any}()
    end 

    global_settings_path = joinpath(settings_path, "global_model_settings.yml") # Global settings for inte
    if isfile(global_settings_path)
        mysetup_global = YAML.load(open(global_settings_path)) # mysetup dictionary stores global settings
    else
        error("A global settings file is required to run Dolphyn")
    end

    tdr_settings_path = joinpath(settings_path, "time_domain_reduction_settings.yml") #Settings YAML file path for TDR
    if isfile(tdr_settings_path)
        mysetup_tdr = YAML.load(open(tdr_settings_path)) # mysetup dictionary stores TDR parameters
    else
        mysetup_tdr = Dict{String,Any}()
    end 

    mysetup = Dict{String,Any}()
    merge!(mysetup, mysetup_genx, mysetup_hsc, mysetup_csc, mysetup_lf, mysetup_besc, mysetup_ng, mysetup_global, mysetup_tdr) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings
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
    if mysetup["ModelLFSC"] == 1
        myinputs = load_liquid_fuels_inputs(myinputs, mysetup, inputs_path)
    end

    ### Load BESC inputs if modeling the bioenergy  supply chain
    if mysetup["ModelBESC"] == 1
        myinputs = load_bio_inputs(myinputs, mysetup, inputs_path)
    end

    ### Load NGSC inputs if modeling the bioenergy  supply chain
    if mysetup["ModelNGSC"] == 1
        myinputs = load_ng_inputs(myinputs, mysetup, inputs_path)
    end

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

function setup_TDR(inputs_path::AbstractString, settings_path::AbstractString, mysetup::Dict{String,Any}, optimizer::DataType=HiGHS.Optimizer, TDR_files::Union{Nothing, Vector{String}}=nothing)

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

        if mysetup["ModelBESC"] == 1
            print_and_log("Bioenergy TDR not implemented.")
        end

        if mysetup["ModelLFSC"] == 1
            print_and_log("Liquid Fuels TDR not implemented.")
        end

        if mysetup["ModelNGSC"] == 1
            print_and_log("Natural gas supply chain TDR not implemented.")
        end
    end

    TDR_path = joinpath(inputs_path, mysetup["TimeDomainReductionFolder"])
    TDR_filepaths = joinpath.(TDR_path, TDR_files)

    if mysetup["TimeDomainReduction"] == 1
        if mysetup["Force_TDR_recluster"] == 1
            # Delete the TDR folder to force a recluster
            # This seems more robust than using an OR statement below and calling run_time_domain_reduction
            println(" -- Deleting TDR folder to force recluster")
            if isdir(TDR_path)
                rm(TDR_path; recursive=true)
            end
        end
        # If any of the TDR files are missing, cluster the data
        if any(!isfile, TDR_filepaths)

            if mysetup["ClusterSubPeriodResults"] == 1
                println(" -- Running subperiod cases for TDR...")
                myinputs_sub = load_all_inputs(mysetup, inputs_path)
                run_subperiod_cases(mysetup, myinputs_sub, settings_path, optimizer, inputs_path)
                println(" -- Subperiod cases completed.")
            end

            print_and_log("Clustering Time Series Data...")
            run_time_domain_reduction(inputs_path, settings_path, mysetup)
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
    if mysetup["ModelLFSC"] == 1
        write_liquid_fuels_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end

    ### Write bioenergy supply chain outputs
    if mysetup["ModelBESC"] == 1
        write_bio_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end

    ### Write natural gas supply chain outputs
    if mysetup["ModelNGSC"] == 1
        write_ng_outputs(EP, adjusted_outpath, mysetup, myinputs)
    end

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
        setup_TDR(inputs_path, settings_path, mysetup, optimizer)
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

function run_subperiod_cases(mysetup::Dict, myinputs::Dict, settings_path::AbstractString, optimizer::DataType, inputs_path::AbstractString)

    function load_full_year_load(inputs_path::AbstractString)
        filepath = joinpath(inputs_path, "Load_data.csv")
        if !isfile(filepath)
            error("Full-year Load_data.csv not found at $filepath")
        end
        load_df = CSV.read(filepath, DataFrame)

        # Extract demand columns — adjust if your headers differ
        load_cols = names(load_df, r"Load_MW_z")  # or specify exact columns if needed
        pD_full = Matrix(load_df[:, load_cols])

        return pD_full
    end

    # Get full model horizon
    # Load the full-year load data
    pD_full_year = load_full_year_load(inputs_path)
    T_full = size(pD_full_year, 1)

    println(" -- Total timesteps ", T_full)

    hours_per_subperiod = mysetup["TimestepsPerRepPeriod"]
    num_subperiods = ceil(Int, T_full / hours_per_subperiod)

    println(" -- Running ", num_subperiods, " subperiod cases of ", hours_per_subperiod, " timesteps each.")

    for subp = 1:num_subperiods
        println(" -- Subperiod $subp / $num_subperiods")

        # Define indices for this subperiod
        t_start = (subp - 1) * hours_per_subperiod + 1
        t_end = min(subp * hours_per_subperiod, T_full)
        t_indices = t_start:t_end

        # Slice inputs
        sub_inputs = deepcopy(myinputs)

        sub_inputs["pD"] = myinputs["pD"][t_indices, :]
        sub_inputs["pP_Max"] = myinputs["pP_Max"][:, t_indices]

        sub_inputs["fuel_costs"] = Dict(f => myinputs["fuel_costs"][f][t_indices] for f in keys(myinputs["fuel_costs"]))
        sub_inputs["C_Fuel_per_MWh"] = myinputs["C_Fuel_per_MWh"][:, t_indices]

        if mysetup["ModelH2"] == 1
            sub_inputs["H2_D"] = myinputs["H2_D"][t_indices, :]
            sub_inputs["pH2_Max"] = myinputs["pH2_Max"][:, t_indices]

            if mysetup["ModelH2Liquid"] ==1
                sub_inputs["H2_D_L"] = myinputs["H2_D_L"][t_indices, :]
            end

            if mysetup["ModelH2G2P"] ==1
                sub_inputs["pH2_g2p_Max"] = myinputs["pH2_g2p_Max"][:, t_indices]
            end

        end
        
        sub_inputs["T"] = length(t_indices)
        println(" -- Time index ", t_indices,)

        sub_inputs["REP_PERIOD"] = 1
        sub_inputs["Weights"] = [sub_inputs["T"]]  # weight = actual hours covered
        sub_inputs["omega"] = ones(Float64, sub_inputs["T"])  # or normalized to sum to sub_inputs["T"]
        sub_inputs["hours_per_subperiod"] = sub_inputs["T"]
        sub_inputs["START_SUBPERIODS"] = [1]
        sub_inputs["INTERIOR_SUBPERIODS"] = 2:sub_inputs["T"]
        sub_inputs["Period_Map"] = nothing

        sub_setup = deepcopy(mysetup)
        sub_setup["TimeDomainReduction"] = 0

        # Build and solve model
        solver = configure_solver(settings_path, optimizer)
        EP = generate_model(sub_setup, sub_inputs, solver)
        EP, solve_time = solve_model(EP, sub_setup)
        sub_inputs["solve_time"] = solve_time # Store the model solve time in myinputs
        adjusted_outpath = write_all_outputs(EP, sub_setup, sub_inputs, inputs_path)

    end
end

function get_case_name(case::AbstractString, root_dirname::AbstractString="Example_Systems")
    split_case = splitpath(case)
    # If one of the entries is "Example_Systems", then use the last two entries
    if root_dirname in split_case
        start = findfirst(x -> x == root_dirname, split_case)
        case_name = joinpath(split_case[start+1:end]...)
    else
        case_name = split_case[end]
    end
    return case_name
end

function obj_value(EP::Model, mysetup::Dict{String, Any})
    scale_factor = mysetup["ParameterScale"] == 1 ? ModelScalingFactor : 1 
    obj_value = value(EP[:eObj]) * scale_factor
    return obj_value
end
