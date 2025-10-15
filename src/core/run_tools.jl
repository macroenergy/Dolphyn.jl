# Methods to simplify the process of running DOLPHYN cases
using HiGHS
using Dates
using Base.Threads

using LinearAlgebra
BLAS.set_num_threads(1) # prevent BLAS from using >1 thread per Julia thread

const PRINT_LOCK = ReentrantLock()

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

            # For input and output TDR clustering
            if mysetup["ClusterSubPeriodResults"] == 1
                h2_file = joinpath(inputs_path, "ClusterSubPeriod_H2Gen.csv")
                power_file = joinpath(inputs_path, "ClusterSubPeriod_Power.csv")

                if mysetup["ModelH2"] == 1
                    if isfile(h2_file) && isfile(power_file)
                        println(" -- Subperiod results already exist, skipping subperiod cases.")
                    else
                        println(" -- Running subperiod cases for TDR...")
                        myinputs_sub = load_all_inputs(mysetup, inputs_path)
                        run_subperiod_cases(mysetup, myinputs_sub, settings_path, optimizer, inputs_path)
                        println(" -- Subperiod cases completed.")
                    end
                else
                    if isfile(power_file)
                        println(" -- Subperiod results already exist, skipping subperiod cases.")
                    else
                        println(" -- Running subperiod cases for TDR...")
                        myinputs_sub = load_all_inputs(mysetup, inputs_path)
                        run_subperiod_cases(mysetup, myinputs_sub, settings_path, optimizer, inputs_path)
                        println(" -- Subperiod cases completed.")
                    end
                end
            end
            print_and_log("Clustering Time Series Data...")
            run_time_domain_reduction(inputs_path, settings_path, mysetup)
        end
    end
end

function write_all_outputs(EP::Model, mysetup::Dict{String, Any}, myinputs::Dict{String, Any}, inputs_path::AbstractString; output_folder::String = "Results")
    outpath = joinpath(inputs_path, output_folder)
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


function obj_value(EP::Model, mysetup::Dict{String, Any})
    scale_factor = mysetup["ParameterScale"] == 1 ? ModelScalingFactor : 1 
    obj_value = value(EP[:eObj]) * scale_factor
    return obj_value
end

################################################################################################
###################### Prepare Subperiod Results for Input + Output TDR  #######################
################################################################################################

function run_subperiod_cases(mysetup::Dict, myinputs::Dict, settings_path::AbstractString, optimizer::DataType, inputs_path::AbstractString)

    function load_full_year_load(inputs_path::AbstractString)
        filepath = joinpath(inputs_path, "Load_data.csv")
        if !isfile(filepath)
            error("Full-year Load_data.csv not found at $filepath")
        end
        load_df = CSV.read(filepath, DataFrame)

        load_cols = names(load_df, r"Load_MW_z")
        pD_full = Matrix(load_df[:, load_cols])

        return pD_full
    end

    pD_full_year = load_full_year_load(inputs_path)
    T_full = size(pD_full_year, 1)
    println(" -- Total timesteps ", T_full)

    hours_per_subperiod = mysetup["TimestepsPerRepPeriod"]
    num_subperiods = ceil(Int, T_full / hours_per_subperiod)
    println(" -- Running ", num_subperiods, " subperiod cases of ", hours_per_subperiod, " timesteps each.")

    G = myinputs["G"]
    RESOURCES = myinputs["RESOURCES"]
    power_matrix = zeros(Float64, T_full, G)

    STOR_ALL = myinputs["STOR_ALL"]
    charge_matrix = zeros(Float64, T_full, G)

    H2_RESOURCES_NAME = nothing
    if mysetup["ModelH2"] == 1
        H = myinputs["H2_RES_ALL"]
        H2_RESOURCES_NAME = myinputs["H2_RESOURCES_NAME"]
        h2_matrix = zeros(Float64, T_full, H)

        H2_STOR_ALL = myinputs["H2_STOR_ALL"]
        h2_charge_matrix = zeros(Float64, T_full, H)

    end

    println("Julia threads available: ", Threads.nthreads())

    # store solve times from each subperiod
    solve_times = Vector{Float64}(undef, num_subperiods)

    # total wall time (everything inside threads)
    subperiod_run_time = @elapsed begin
        @threads for subp in 1:num_subperiods
            # — print safely (threads may interleave) —
            t_start = (subp - 1) * hours_per_subperiod + 1
            t_end   = min(subp * hours_per_subperiod, T_full)
            t_indices = t_start:t_end

            lock(PRINT_LOCK) do
                println(" -- Subperiod $subp / $num_subperiods (thread $(threadid()), t=$t_start:$t_end)")
            end

            # Prepare sub-inputs (deepcopy keeps threads isolated)
            sub_inputs = deepcopy(myinputs)
            sub_inputs["pD"] = myinputs["pD"][t_indices, :]
            sub_inputs["pP_Max"] = myinputs["pP_Max"][:, t_indices]
            sub_inputs["fuel_costs"] = Dict(f => myinputs["fuel_costs"][f][t_indices] for f in keys(myinputs["fuel_costs"]))
            sub_inputs["C_Fuel_per_MWh"] = myinputs["C_Fuel_per_MWh"][:, t_indices]

            if mysetup["ModelH2"] == 1
                sub_inputs["H2_D"] = myinputs["H2_D"][t_indices, :]
                sub_inputs["pH2_Max"] = myinputs["pH2_Max"][:, t_indices]
                if mysetup["ModelH2Liquid"] == 1
                    sub_inputs["H2_D_L"] = myinputs["H2_D_L"][t_indices, :]
                end
                if mysetup["ModelH2G2P"] == 1
                    sub_inputs["pH2_g2p_Max"] = myinputs["pH2_g2p_Max"][:, t_indices]
                end
            end

            sub_inputs["T"] = length(t_indices)
            sub_inputs["REP_PERIOD"] = 1
            sub_inputs["Weights"] = [sub_inputs["T"]]

            subperiod_hours = length(t_indices)
            weight_per_hour = T_full / subperiod_hours
            sub_inputs["omega"] = fill(weight_per_hour, subperiod_hours)

            sub_inputs["hours_per_subperiod"] = sub_inputs["T"]
            sub_inputs["START_SUBPERIODS"] = [1]
            sub_inputs["INTERIOR_SUBPERIODS"] = 2:sub_inputs["T"]
            sub_inputs["Period_Map"] = nothing

            sub_setup = deepcopy(mysetup)
            sub_setup["TimeDomainReduction"] = 0

            # Single-threaded solver inside parallel loop
            solver = configure_solver(settings_path, optimizer)

            EP = generate_model(sub_setup, sub_inputs, solver)
            EP, solve_time = solve_model(EP, sub_setup)
            solve_times[subp] = solve_time

            sub_inputs["solve_time"] = solve_time

            # Unique folder per subperiod
            outfolder = joinpath("SubPeriod_Results", "Sub_$(lpad(subp, 3, '0'))")
            _ = write_all_outputs(EP, sub_setup, sub_inputs, inputs_path; output_folder = outfolder)

            # Store results
            power = value.(EP[:vP])
            @views power_matrix[t_indices, :] = power'

            if !isempty(STOR_ALL)
                charge = Array(value.(EP[:vCHARGE]))
                @views charge_matrix[t_indices, STOR_ALL] = charge'
            end

            if mysetup["ModelH2"] == 1
                h2gen = value.(EP[:vH2Gen])
                @views h2_matrix[t_indices, :] = h2gen'

                if !isempty(H2_STOR_ALL)
                    h2_charge = Array(value.(EP[:vH2_CHARGE_STOR]))
                    @views h2_charge_matrix[t_indices, H2_STOR_ALL] = h2_charge'
                end
            end
        end
    end 

    # Write power matrix
    dfPower = DataFrame(t = 1:T_full)
    for (i, r) in enumerate(RESOURCES)
        dfPower[!, Symbol(r)] = power_matrix[:, i]
    end

    # Set very small values to zero
    M_Power = Matrix(dfPower[:, Not(:t)])
    M_Power = ifelse.(abs.(M_Power) .< 1e-5, 0.0, M_Power)

    for (j, name) in enumerate(names(dfPower)[2:end])
        dfPower[!, name] = M_Power[:, j]
    end

    CSV.write(joinpath(inputs_path, "ClusterSubPeriod_Power.csv"), dfPower)
    println(" -- ClusterSubPeriod_Power.csv written.")


    # Write charge matrix
    if !isempty(STOR_ALL)
        dfCharge = DataFrame(t = 1:T_full)
        for (i, r) in enumerate(RESOURCES)
            dfCharge[!, Symbol(r)] = charge_matrix[:, i]
        end

        M_Charge = Matrix(dfCharge[:, Not(:t)])
        M_Charge = ifelse.(abs.(M_Charge) .< 1e-5, 0.0, M_Charge)

        for (j, name) in enumerate(names(dfCharge)[2:end])
            dfCharge[!, name] = M_Charge[:, j]
        end

        CSV.write(joinpath(inputs_path, "ClusterSubPeriod_Charge.csv"), dfCharge)
        println(" -- ClusterSubPeriod_Charge.csv written.")
    end


    # Write H2 matrix
    if mysetup["ModelH2"] == 1
        dfH2 = DataFrame(t = 1:T_full)
        for (i, r) in enumerate(H2_RESOURCES_NAME)
            dfH2[!, Symbol(r)] = h2_matrix[:, i]
        end

        M_H2 = Matrix(dfH2[:, Not(:t)])
        M_H2 = ifelse.(abs.(M_H2) .< 1e-5, 0.0, M_H2)
        
        for (j, name) in enumerate(names(dfH2)[2:end])
            dfH2[!, name] = M_H2[:, j]
        end

        CSV.write(joinpath(inputs_path, "ClusterSubPeriod_H2Gen.csv"), dfH2)
        println(" -- ClusterSubPeriod_H2Gen.csv written.")

        if !isempty(H2_STOR_ALL)
            dfH2Charge = DataFrame(t = 1:T_full)
            for (i, r) in enumerate(H2_RESOURCES_NAME)
                dfH2Charge[!, Symbol(r)] = h2_charge_matrix[:, i]
            end

            M_H2_Charge = Matrix(dfH2Charge[:, Not(:t)])
            M_H2_Charge = ifelse.(abs.(M_H2_Charge) .< 1e-5, 0.0, M_H2_Charge)
            
            for (j, name) in enumerate(names(dfH2Charge)[2:end])
                dfH2Charge[!, name] = M_H2_Charge[:, j]
            end

            CSV.write(joinpath(inputs_path, "ClusterSubPeriod_H2Charge.csv"), dfH2Charge)
            println(" -- ClusterSubPeriod_H2Charge.csv written.")
        end
    end
end

