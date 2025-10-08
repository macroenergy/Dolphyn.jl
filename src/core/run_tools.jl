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

            if mysetup["ClusterSubPeriodResults"] == 1
                h2_file = joinpath(inputs_path, "ClusterSubPeriod_H2Gen.csv")
                power_file = joinpath(inputs_path, "ClusterSubPeriod_Power.csv")

                if mysetup["ModelH2"] == 1
                    if isfile(h2_file) && isfile(power_file)
                        println(" -- Subperiod results already exist, skipping subperiod cases.")
                        subperiod_run_time = "Using Existing Subperiod Results"
                    else
                        println(" -- Running subperiod cases for TDR...")
                        myinputs_sub = load_all_inputs(mysetup, inputs_path)
                        subperiod_run_time, parallel_solve_time, total_solver_time = run_subperiod_cases(mysetup, myinputs_sub, settings_path, optimizer, inputs_path)
                        println(" -- Subperiod cases completed.")
                    end
                else
                    if isfile(power_file)
                        println(" -- Subperiod results already exist, skipping subperiod cases.")
                        subperiod_run_time = "Using Existing Subperiod Results"
                    else
                        println(" -- Running subperiod cases for TDR...")
                        myinputs_sub = load_all_inputs(mysetup, inputs_path)
                        subperiod_run_time, parallel_solve_time, total_solver_time = run_subperiod_cases(mysetup, myinputs_sub, settings_path, optimizer, inputs_path)
                        println(" -- Subperiod cases completed.")
                    end
                end
            else
                subperiod_run_time = "NA"
                parallel_solve_time = "NA"
                total_solver_time = "NA"
            end

            print_and_log("Clustering Time Series Data...")
            FinalOutputData, W, RMSE, col_to_zone_map, autoencoder_training_time, clustering_time = run_time_domain_reduction(inputs_path, settings_path, mysetup)
        else
            print_and_log("Time Series Data Already Clustered.")
            autoencoder_training_time = "Time Series Data Already Clustered"
            clustering_time = "Time Series Data Already Clustered"
            subperiod_run_time = "Time Series Data Already Clustered"
            parallel_solve_time = "Time Series Data Already Clustered"
            total_solver_time = "Time Series Data Already Clustered"
        end
    end

    return autoencoder_training_time, clustering_time, subperiod_run_time, parallel_solve_time, total_solver_time
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
        autoencoder_training_time, clustering_time, subperiod_run_time, parallel_solve_time, total_solver_time = setup_TDR(inputs_path, settings_path, mysetup, optimizer)
    else
        autoencoder_training_time = "NA"
        clustering_time = "NA"
        subperiod_run_time = "NA"
        parallel_solve_time = "NA"
        total_solver_time = "NA"
    end
    
    solver = configure_solver(settings_path, optimizer)
    myinputs = load_all_inputs(mysetup, inputs_path)
    EP = generate_model(mysetup, myinputs, solver)
    return EP, mysetup, myinputs, autoencoder_training_time, clustering_time, subperiod_run_time, parallel_solve_time, total_solver_time
end

function generate_model(local_dir::AbstractString=@__DIR__; optimizer::DataType=HiGHS.Optimizer, force_TDR_off::Bool=false, force_TDR_on::Bool=false, force_TDR_recluster::Bool=false)
    settings_path = joinpath(local_dir, "Settings")
    inputs_path = local_dir
    return generate_model(inputs_path, settings_path; optimizer=optimizer, force_TDR_off=force_TDR_off, force_TDR_on=force_TDR_on, force_TDR_recluster=force_TDR_recluster)
end

function run_case(inputs_path::AbstractString, settings_path::AbstractString; optimizer::DataType=HiGHS.Optimizer, force_TDR_off::Bool=false, force_TDR_on::Bool=false, force_TDR_recluster::Bool=false)

    EP, mysetup, myinputs, autoencoder_training_time, clustering_time, subperiod_run_time, parallel_solve_time, total_solver_time = generate_model(inputs_path, settings_path; optimizer=optimizer, force_TDR_off=force_TDR_off, force_TDR_on=force_TDR_on, force_TDR_recluster=force_TDR_recluster)
    EP, solve_time = solve_model(EP, mysetup)

    myinputs["solve_time"] = solve_time # Store the model solve time in myinputs
    adjusted_outpath = write_all_outputs(EP, mysetup, myinputs, inputs_path)

    base_setup = load_settings(settings_path)
    ClusterMethod = base_setup["ClusterMethod"]
    MaxPeriods = base_setup["MaxPeriods"]

    # Write to CSV
    logfile = joinpath(inputs_path, "run_times.csv")

    if base_setup["TimeDomainReduction"] == 1
        df = DataFrame(
            Case = [basename(inputs_path)],
            Rep_Periods = [MaxPeriods],
            Clustering_Method = [ClusterMethod],
            Subperiod_Run_Time = [subperiod_run_time],
            Subperiod_Parallel_Solve_Time = [parallel_solve_time],
            Subperiod_Total_Solve_Time = [total_solver_time],
            Autoencoder_Training_Time = [autoencoder_training_time],
            TDR_Clustering_Time = [clustering_time],
            Model_Solve_Time = [solve_time],
            Objval = objective_value(EP),
        )
    else
        df = DataFrame(
            Case = [basename(inputs_path)],
            Rep_Periods = ["Full"],
            Clustering_Method = ["NA"],
            Subperiod_Run_Time = [subperiod_run_time],
            Subperiod_Parallel_Solve_Time = [parallel_solve_time],
            Subperiod_Total_Solve_Time = [total_solver_time],
            Autoencoder_Training_Time = [autoencoder_training_time],
            TDR_Clustering_Time = [clustering_time],
            Model_Solve_Time = [solve_time],
            Objval = objective_value(EP),
        )
    end

    # append if file exists
    if isfile(logfile)
        old = CSV.read(logfile, DataFrame)
        df = vcat(old, df)
    end
    CSV.write(logfile, df)

    return EP, myinputs, mysetup, adjusted_outpath
end

function run_case(local_dir::AbstractString=@__DIR__; optimizer::DataType=HiGHS.Optimizer, force_TDR_off::Bool=false, force_TDR_on::Bool=false, force_TDR_recluster::Bool=false)
    settings_path = joinpath(local_dir, "Settings")
    inputs_path = local_dir
    base_setup = load_settings(settings_path)

    # Run multiple TDR experiments
    if base_setup["TimeDomainReduction"] == 1 && base_setup["RunMultipleTDR"] == 1
        println("RunMultipleTDR = 1, running multiple cases with list of user-defined representative weeks")
        return run_multiple_TDR(inputs_path, settings_path, optimizer)
    end

    # AE Auto-Tuning by MAPE
    if base_setup["AutoTuneAE"] == 1 && base_setup["TimeDomainReduction"] == 1 && 
        (base_setup["ClusterMethod"] == "autoencoder_sequential" ||
        base_setup["ClusterMethod"] == "autoencoder_simultaneous")

        println("AutoTuneAE = 1 → running AE hyperparameter tuning by MAPE")

        if base_setup["ClusterSubPeriodResults"] == 1
            h2_file = joinpath(inputs_path, "ClusterSubPeriod_H2Gen.csv")
            power_file = joinpath(inputs_path, "ClusterSubPeriod_Power.csv")

            if base_setup["ModelH2"] == 1
                if isfile(h2_file) && isfile(power_file)
                    println(" -- Subperiod results already exist, skipping subperiod cases.")
                    subperiod_run_time = "Using Existing Subperiod Results"
                else
                    println(" -- Running subperiod cases for TDR...")
                    myinputs_sub = load_all_inputs(base_setup, inputs_path)
                    subperiod_run_time, parallel_solve_time, total_solver_time = run_subperiod_cases(base_setup, myinputs_sub, settings_path, optimizer, inputs_path)
                    println(" -- Subperiod cases completed.")
                end
            else
                if isfile(power_file)
                    println(" -- Subperiod results already exist, skipping subperiod cases.")
                    subperiod_run_time = "Using Existing Subperiod Results"
                else
                    println(" -- Running subperiod cases for TDR...")
                    myinputs_sub = load_all_inputs(base_setup, inputs_path)
                    subperiod_run_time, parallel_solve_time, total_solver_time = run_subperiod_cases(base_setup, myinputs_sub, settings_path, optimizer, inputs_path)
                    println(" -- Subperiod cases completed.")
                end
            end
        end

        return run_autotune_AE(local_dir, settings_path, inputs_path, optimizer, base_setup)
    end

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

            # Important: keep each Optimizer single-threaded to avoid oversubscription
            # e.g., for Gurobi: set "Threads" => 1 inside your configure_solver()

            # single-threaded solver inside parallel loop
            solver = configure_solver(settings_path, optimizer)

            EP = generate_model(sub_setup, sub_inputs, solver)
            EP, solve_time = solve_model(EP, sub_setup)
            solve_times[subp] = solve_time

            sub_inputs["solve_time"] = solve_time

            # Unique folder per subperiod to avoid I/O collisions
            outfolder = joinpath("SubPeriod_Results", "Sub_$(lpad(subp, 3, '0'))")
            _ = write_all_outputs(EP, sub_setup, sub_inputs, inputs_path; output_folder = outfolder)

            # Store results (non-overlapping row blocks => thread-safe)
            power = value.(EP[:vP])             # size ~ (G, T_sub)
            @views power_matrix[t_indices, :] = power'   # (T_sub, G)

            if !isempty(STOR_ALL)
                charge = Array(value.(EP[:vCHARGE])) # (|STOR_ALL|, T_sub)
                @views charge_matrix[t_indices, STOR_ALL] = charge'
            end

            if mysetup["ModelH2"] == 1
                h2gen = value.(EP[:vH2Gen])     # size ~ (H, T_sub)
                @views h2_matrix[t_indices, :] = h2gen'

                if !isempty(H2_STOR_ALL)
                    h2_charge = Array(value.(EP[:vH2_CHARGE_STOR]))   # (|H2_STOR_ALL|, T_sub)
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

    # Vectorized thresholding: set very small values to zero
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

    # aggregate solver times across threads
    parallel_solve_time = maximum(solve_times)   # wall-clock contribution from solves
    total_solver_time   = sum(solve_times)       # total effort if sequential

    return subperiod_run_time, parallel_solve_time, total_solver_time
end


function run_multiple_TDR(inputs_path::AbstractString, settings_path::AbstractString,
                            optimizer::DataType=HiGHS.Optimizer)

    base_setup = load_settings(settings_path)

    if base_setup["RunMultipleTDR"] != 1
        return nothing
    end

    ClusterMethod = base_setup["ClusterMethod"]
    max_list = base_setup["MaxPeriodsList"]
    min_list = base_setup["MinPeriodsList"]

    # Step 1: Subperiod results (if required)

    if base_setup["ClusterSubPeriodResults"] == 1
        power_file = joinpath(inputs_path, "ClusterSubPeriod_Power.csv")
        h2_file    = joinpath(inputs_path, "ClusterSubPeriod_H2Gen.csv")

        need_subperiod = !isfile(power_file)
        if !need_subperiod && !isfile(h2_file) && base_setup["ModelH2"] == 1
            need_subperiod = true
        end

        if need_subperiod
            println("Step 1: Running subperiod cases once (parallel inside run_subperiod_cases)")
            base_inputs = load_all_inputs(base_setup, inputs_path)
            subperiod_run_time, parallel_solve_time, total_solver_time = run_subperiod_cases(base_setup, base_inputs, settings_path, optimizer, inputs_path)

            append_log_multiple_TDR(inputs_path; 
                        Case="Running Subperiod Cases for $(basename(inputs_path))",
                        Rep_Periods="NA",
                        Clustering_Method="NA",
                        Subperiod_Run_Time=subperiod_run_time,
                        Subperiod_Parallel_Solve_Time=parallel_solve_time,
                        Subperiod_Total_Solve_Time=total_solver_time,
                        Autoencoder_Training_Time="NA",
                        TDR_Clustering_Time="NA",
                        Model_Run_Time="NA",
                        Objval="NA")

            println("Subperiod results completed.")
        else
            println("Step 1: Subperiod results already exist, skipping.")
        end
    end

    # Step 2: Autoencoder latent space results (if required)

    if base_setup["ClusterMethod"] == "autoencoder_sequential"

        if get(base_setup, "AutoTuneAE", 0) == 1
            println("Step 1b: Running AE AutoTune before multiple TDR cases...")
            bestN, bestD, _, _ = autotune_seq_AE_by_MAPE(inputs_path, settings_path, optimizer)

            # Inject tuned hyperparameters
            AE = get!(base_setup, "AutoEncoder", Dict{String,Any}())
            AE["n_filters"]  = Int(bestN)
            AE["latent_dim"] = Int(bestD)

            println(" -- Tuned AE hyperparams chosen: n_filters=$(bestN), latent_dim=$(bestD)")

            # Train autoencoder once with tuned settings
            FinalOutputData_initial, W_initial, RMS_initial, col_to_zone_map_initial, 
            autoencoder_training_time_initial, clustering_time_initial =
                run_time_domain_reduction(inputs_path, settings_path, base_setup)

            append_log_multiple_TDR(inputs_path;
                Case="Autoencoder AutoTune Training for $(basename(inputs_path))",
                Rep_Periods="NA",
                Clustering_Method="autoencoder (AutoTune)",
                Subperiod_Run_Time="NA",
                Subperiod_Parallel_Solve_Time="NA",
                Subperiod_Total_Solve_Time="NA",
                Autoencoder_Training_Time=autoencoder_training_time_initial,
                TDR_Clustering_Time="NA",
                Model_Run_Time="NA",
                Objval="NA")
        
        else
    
            println("Step 1b: Precomputing autoencoder latent space...")
            FinalOutputData_initial, W_initial, RMS_initial, col_to_zone_map_initial, autoencoder_training_time_initial, clustering_time_initial = run_time_domain_reduction(inputs_path, settings_path, base_setup)

            append_log_multiple_TDR(inputs_path; 
                        Case="Autoencoder Training for $(basename(inputs_path))",
                        Rep_Periods="NA",
                        Clustering_Method=ClusterMethod,
                        Subperiod_Run_Time="NA",
                        Subperiod_Parallel_Solve_Time="NA",
                        Subperiod_Total_Solve_Time="NA",
                        Autoencoder_Training_Time=autoencoder_training_time_initial,
                        TDR_Clustering_Time="NA",
                        Model_Run_Time="NA",
                        Objval="NA")
        end

    elseif base_setup["ClusterMethod"] == "autoencoder_simultaneous"

        if get(base_setup, "AutoTuneAE", 0) == 1
            println("Step 1b: Running Simultaneous AE AutoTune before multiple TDR cases...")
            bestL, bestN, bestD, _, _ = autotune_sim_AE_by_MAPE(inputs_path, settings_path, optimizer)
    
            # Inject tuned hyperparameters
            AE = get!(base_setup, "AutoEncoder", Dict{String,Any}())
            AE["n_filters"]  = Int(bestN)
            AE["latent_dim"] = Int(bestD)
            AE["lambda"]     = bestL
    
            println(" -- Tuned Simultaneous AE hyperparams: n_filters=$(bestN), latent_dim=$(bestD), lambda=$(bestL)")

            #Latent space will change with each week and cannot be reused as in the case of seqeuntial autoencoders
        end

    end

    # Step 2: Parallel TDR experiments
    println("Step 2: Running multiple TDR cases")
    println("Max representative weeks: ", max_list)
    println("Min representative weeks: ", min_list)

    logs = Vector{NamedTuple}(undef, length(min_list))  # hold logs in memory

    use_threads = get(base_setup, "UseThreads", 1) == 1  # default = use threads

    if use_threads
        @threads for i in eachindex(min_list)
            run_TDR_case!(i, min_list, max_list, base_setup, inputs_path, settings_path, optimizer, ClusterMethod)
        end
    else
        for i in eachindex(min_list)
            run_TDR_case!(i, min_list, max_list, base_setup, inputs_path, settings_path, optimizer, ClusterMethod)
        end
    end
end

function run_TDR_case!(i, min_list, max_list, base_setup, inputs_path, settings_path, optimizer, ClusterMethod)
    maxp, minp = max_list[i], min_list[i]

    mysetup = deepcopy(base_setup)
    mysetup["MaxPeriods"] = maxp
    mysetup["MinPeriods"] = minp
    mysetup["TimeDomainReductionFolder"] = "TDR_Results_$(minp)_Weeks"

    lock(PRINT_LOCK) do
        println("Starting clustering and solving model for $minp weeks (thread $(threadid()))")
    end

    FinalOutputData, W, RMSE, col_to_zone_map, autoencoder_training_time, clustering_time =
        run_time_domain_reduction(inputs_path, settings_path, mysetup)

    solver   = configure_solver(settings_path, optimizer)
    myinputs = load_all_inputs(mysetup, inputs_path)
    EP       = generate_model(mysetup, myinputs, solver)
    EP, solve_time = solve_model(EP, mysetup)
    myinputs["solve_time"] = solve_time

    lock(PRINT_LOCK) do
        println(">>> Finished $minp weeks model in $(round(solve_time,digits=1)) seconds")
    end

    subperiod_run_time = base_setup["ClusterSubPeriodResults"] == 1 ?
                       "Using Existing Subperiod Results" : "NA"

    subperiod_parallel_solve_time = base_setup["ClusterSubPeriodResults"] == 1 ?
                       "Using Existing Subperiod Results" : "NA"

    subperiod_total_solve_time = base_setup["ClusterSubPeriodResults"] == 1 ?
                       "Using Existing Subperiod Results" : "NA"

    append_log_multiple_TDR(inputs_path;
        Case=basename(inputs_path),
        Rep_Periods=minp,
        Clustering_Method=ClusterMethod,
        Subperiod_Run_Time=subperiod_run_time,
        Subperiod_Parallel_Solve_Time=subperiod_parallel_solve_time,
        Subperiod_Total_Solve_Time=subperiod_total_solve_time,
        Autoencoder_Training_Time=autoencoder_training_time,
        TDR_Clustering_Time=clustering_time,
        Model_Run_Time=solve_time,
        Objval=objective_value(EP))

    outfolder = "Results_$(minp)_Weeks"
    _ = write_all_outputs(EP, mysetup, myinputs, inputs_path; output_folder=outfolder)
end

function append_log_multiple_TDR(inputs_path::AbstractString; Case::AbstractString, Rep_Periods, Clustering_Method, Subperiod_Run_Time, Subperiod_Parallel_Solve_Time, Subperiod_Total_Solve_Time, Autoencoder_Training_Time, TDR_Clustering_Time, Model_Run_Time, Objval)

    logfile = joinpath(inputs_path, "run_times_TDR.csv")

    df = DataFrame(
        Case = [Case],
        Rep_Periods = [Rep_Periods],
        Clustering_Method = [Clustering_Method],
        Subperiod_Run_Time = [Subperiod_Run_Time],
        Subperiod_Parallel_Solve_Time = [Subperiod_Parallel_Solve_Time],
        Subperiod_Total_Solve_Time = [Subperiod_Total_Solve_Time],
        Autoencoder_Training_Time = [Autoencoder_Training_Time],
        TDR_Clustering_Time = [TDR_Clustering_Time],
        Model_Run_Time = [Model_Run_Time],
        Objval = [Objval],
    )

    if isfile(logfile)
    old = CSV.read(logfile, DataFrame)
    df = vcat(old, df; cols=:union)   # union ensures schema alignment
    end

    CSV.write(logfile, df)
end


function obj_value(EP::Model, mysetup::Dict{String, Any})
    scale_factor = mysetup["ParameterScale"] == 1 ? ModelScalingFactor : 1 
    obj_value = value(EP[:eObj]) * scale_factor
    return obj_value
end


################################################################################################
#################################### AutoTune AE Sequential ####################################
################################################################################################

function run_autotune_AE(local_dir::AbstractString, settings_path::AbstractString, inputs_path::AbstractString, optimizer::DataType, base_setup::Dict{String,Any})

    if base_setup["ClusterMethod"] == "autoencoder_sequential"
        bestN, bestD, _, _ = autotune_seq_AE_by_MAPE(local_dir, settings_path, optimizer)
    elseif base_setup["ClusterMethod"] == "autoencoder_simultaneous"
        bestL, bestN, bestD, _, _ = autotune_sim_AE_by_MAPE(local_dir, settings_path, optimizer)
    end

    # --- ensure AutoEncoder dict exists and inject tuned hyperparams ---
    AE = get!(base_setup, "AutoEncoder", Dict{String,Any}())
    AE["n_filters"]  = Int(bestN)
    AE["latent_dim"] = Int(bestD)

    if base_setup["ClusterMethod"] == "autoencoder_simultaneous"
        AE["lambda"]  = bestL
    end

    # force retraining (don’t reuse old latent file)
    base_setup["TimeDomainReduction"] = 1
    #base_setup["ForceAutoencoderTraining"] = 1
    
    # Proceed to build/solve
    FinalOutputData, W, RMSE, col_to_zone_map, ae_time, clus_time = run_time_domain_reduction(inputs_path, settings_path, base_setup)
    solver   = configure_solver(settings_path, optimizer)
    myinputs = load_all_inputs(base_setup, inputs_path)
    EP = generate_model(base_setup, myinputs, solver)

    EP, solve_time = solve_model(EP, base_setup)
    myinputs["solve_time"] = solve_time
    adjusted_outpath = write_all_outputs(EP, base_setup, myinputs, inputs_path)

    return EP, myinputs, base_setup, adjusted_outpath
end

"""
Auto-tune AE hyperparameters by minimizing average MAPE vs Full Year.
- Respects setup["AutoTuneFilters"], ["AutoTuneLatents"], ["AutoTuneWeeks"], ["AutoTuneMetrics"].
- Runs in parallel with Threads.@threads.
- Returns (bestN, bestD, bestMAPE, log_df::DataFrame)
"""

function autotune_seq_AE_by_MAPE(inputs_path::AbstractString,
                             settings_path::AbstractString,
                             optimizer::DataType)

    base_setup  = load_settings(settings_path)

    filters     = base_setup["AutoTuneFilters"]
    latents     = base_setup["AutoTuneLatents"]
    train_weeks = base_setup["AutoTuneTrainWeeks"]
    valid_weeks = base_setup["AutoTuneValidWeeks"]
    metrics     = base_setup["AutoTuneMetrics"]

    full_dir = ensure_full_year_baseline(inputs_path, settings_path, optimizer)
    full_csv = joinpath(full_dir, "capacity_multi_sector.csv")

    logs = Vector{NamedTuple{(:NFilters,:Latent,:Weeks,:Role,:MAPE,:Seconds,:ResultsDir),
                             Tuple{Int,Int,Int,String,Float64,Float64,String}}}()
    log_lock = ReentrantLock()

    println(" -- AE AutoTune: training on weeks $(train_weeks), validating on weeks $(valid_weeks)")

    combos = collect(Iterators.product(filters, latents))

    @threads for (nf, ld) in combos
        t0 = time()
        try
            # Loop over training + validation weeks for this (nf, ld)
            for (k, role) in vcat([(w,"train") for w in train_weeks],
                                  [(w,"valid") for w in valid_weeks])

                out_dir, _ = run_one_seq_AE_config!(inputs_path, settings_path,
                                                optimizer, base_setup, nf, ld, k)
                rep_csv = joinpath(out_dir, "capacity_multi_sector.csv")
                mape    = avg_mape(rep_csv, full_csv, metrics)
                dt      = time() - t0

                lock(log_lock) do
                    push!(logs, (NFilters=nf, Latent=ld, Weeks=k, Role=role,
                                 MAPE=mape, Seconds=dt, ResultsDir=out_dir))
                end
                lock(PRINT_LOCK) do
                    println("   [$role N=$(nf), D=$(ld), k=$(k)] " *
                            "MAPE=$(round(mape,digits=3))  ($(round(dt,digits=1)) s)")
                end
            end
        catch e
            lock(PRINT_LOCK) do
                @warn "Tuning failed for N=$nf, D=$ld" exception=(e, catch_backtrace())
            end
            lock(log_lock) do
                push!(logs, (NFilters=nf, Latent=ld, Weeks=-1, Role="error",
                             MAPE=NaN, Seconds=0.0, ResultsDir="ERROR"))
            end
        end
    end

    df = DataFrame(logs)

    # Separate train and valid results
    train_df = filter(:Role => ==("train"), df)
    valid_df = filter(:Role => ==("valid"), df)

    # Aggregate by hyperparameters
    agg_train = combine(groupby(train_df, [:NFilters, :Latent]),
                        :MAPE => (x -> mean(skipmissing(x))) => :TrainMAPE)
    agg_valid = combine(groupby(valid_df, [:NFilters, :Latent]),
                        :MAPE => (x -> mean(skipmissing(x))) => :ValidMAPE)

    agg = innerjoin(agg_train, agg_valid, on=[:NFilters, :Latent])

    # Apply selection rule: ValidMAPE must be <= TrainMAPE
    filtered = filter(row -> row.ValidMAPE <= row.TrainMAPE, agg)

    if nrow(filtered) == 0
        @warn "No configs passed validation (ValidMAPE ≤ TrainMAPE). Falling back to best ValidMAPE overall."
        bestrow = first(sort(agg, :ValidMAPE))
    else
        bestrow = first(sort(filtered, :ValidMAPE))
    end

    bestN, bestD, bestTrain, bestValid =
        bestrow.NFilters, bestrow.Latent, bestrow.TrainMAPE, bestrow.ValidMAPE

    CSV.write(joinpath(inputs_path, "Autoencoder_Tuning_Log.csv"), df)
    CSV.write(joinpath(inputs_path, "Autoencoder_Tuning_Summary.csv"), agg)

    println(" -- AE AutoTune best: N=$(bestN), D=$(bestD), " *
            "TrainMAPE=$(round(bestTrain,digits=3)), " *
            "ValidMAPE=$(round(bestValid,digits=3))")

    return bestN, bestD, bestValid, df, agg
end

"""
Run a single AE configuration (n_filters, latent_dim) with k representative weeks.
Returns: (out_dir::String, solve_time::Float64)
"""
function run_one_seq_AE_config!(inputs_path::AbstractString, settings_path::AbstractString, optimizer::DataType, base_setup::Dict{String,Any}, n_filters::Int, latent_dim::Int, k_weeks::Int)

    mysetup = deepcopy(base_setup)
    mysetup["TimeDomainReduction"] = 1

    # inject hyperparams (adjust key names to what run_time_domain_reduction reads)
    AE = mysetup["AutoEncoder"]

    # inject tuned hyperparameters
    AE["n_filters"]  = n_filters
    AE["latent_dim"] = latent_dim

    # fix number of rep periods
    mysetup["MinPeriods"] = k_weeks
    mysetup["MaxPeriods"] = k_weeks
    mysetup["TimeDomainReductionFolder"] = "TDR_Results_$(k_weeks)_Weeks_AE_N$(n_filters)_D$(latent_dim)"

    # TDR: trains AE + clusters
    FinalOutputData, W, RMSE, col_to_zone_map, ae_time, clus_time = run_time_domain_reduction(inputs_path, settings_path, mysetup)

    # Build & solve
    solver   = configure_solver(settings_path, optimizer)
    myinputs = load_all_inputs(mysetup, inputs_path)
    EP       = generate_model(mysetup, myinputs, solver)
    EP, solve_time = solve_model(EP, mysetup)
    myinputs["solve_time"] = solve_time

    outfolder = "Results_$(k_weeks)_Weeks_AE_N$(n_filters)_D$(latent_dim)"
    outpath = write_all_outputs(EP, mysetup, myinputs, inputs_path; output_folder=outfolder)

    return joinpath(inputs_path, outfolder), solve_time
end

################################################################################################
#################################### AutoTune AE Simultaneous ##################################
################################################################################################

function autotune_sim_AE_by_MAPE(inputs_path::AbstractString,
                                 settings_path::AbstractString,
                                 optimizer::DataType)

    base_setup  = load_settings(settings_path)

    filters     = base_setup["AutoTuneFilters"]
    latents     = base_setup["AutoTuneLatents"]
    lambdas     = base_setup["AutoTuneLambdas"]
    train_weeks = base_setup["AutoTuneTrainWeeks"]
    valid_weeks = base_setup["AutoTuneValidWeeks"]
    metrics     = base_setup["AutoTuneMetrics"]

    full_dir = ensure_full_year_baseline(inputs_path, settings_path, optimizer)
    full_csv = joinpath(full_dir, "capacity_multi_sector.csv")

    logs = Vector{NamedTuple{(:NFilters,:Latent,:Lambda,:Weeks,:Role,:MAPE,:Seconds,:ResultsDir),
                             Tuple{Int,Int,Float64,Int,String,Float64,Float64,String}}}()
    log_lock = ReentrantLock()

    println(" -- Simultaneous AE AutoTune: training on weeks $(train_weeks), validating on weeks $(valid_weeks)")

    combos = collect(Iterators.product(filters, latents, lambdas))

    @threads for (nf, ld, lam) in combos
        t0 = time()
        try
            for (k, role) in vcat([(w,"train") for w in train_weeks],
                                  [(w,"valid") for w in valid_weeks])

                out_dir, _ = run_one_sim_AE_config!(inputs_path, settings_path,
                                                optimizer, base_setup, nf, ld, lam, k)

                rep_csv = joinpath(out_dir, "capacity_multi_sector.csv")
                mape    = avg_mape(rep_csv, full_csv, metrics)
                dt      = time() - t0

                lock(log_lock) do
                    push!(logs, (NFilters=nf, Latent=ld, Lambda=lam, Weeks=k, Role=role,
                                 MAPE=mape, Seconds=dt, ResultsDir=out_dir))
                end
                lock(PRINT_LOCK) do
                    println("   [$role N=$(nf), D=$(ld), lambda=$(lam), k=$(k)] " *
                            "MAPE=$(round(mape,digits=3))  ($(round(dt,digits=1)) s)")
                end
            end
        catch e
            lock(PRINT_LOCK) do
                @warn "Tuning failed for N=$nf, D=$ld, lambda=$lam" exception=(e, catch_backtrace())
            end
            lock(log_lock) do
                push!(logs, (NFilters=nf, Latent=ld, Lambda=lam, Weeks=-1,
                             Role="error", MAPE=NaN, Seconds=0.0, ResultsDir="ERROR"))
            end
        end
    end

    df = DataFrame(logs)

    # train/valid aggregation
    train_df = filter(:Role => ==("train"), df)
    valid_df = filter(:Role => ==("valid"), df)

    agg_train = combine(groupby(train_df, [:NFilters,:Latent,:Lambda]),
                        :MAPE => mean ∘ skipmissing => :TrainMAPE)
    agg_valid = combine(groupby(valid_df, [:NFilters,:Latent,:Lambda]),
                        :MAPE => mean ∘ skipmissing => :ValidMAPE)

    agg = innerjoin(agg_train, agg_valid, on=[:NFilters,:Latent,:Lambda])

    # selection rule
    filtered = filter(row -> row.ValidMAPE <= row.TrainMAPE, agg)

    bestrow = nrow(filtered) == 0 ? first(sort(agg, :ValidMAPE)) :
                                    first(sort(filtered, :ValidMAPE))

    bestN, bestD, bestL, bestTrain, bestValid =
        bestrow.NFilters, bestrow.Latent, bestrow.Lambda, bestrow.TrainMAPE, bestrow.ValidMAPE

    CSV.write(joinpath(inputs_path, "Simultaneous_AE_Tuning_Log.csv"), df)
    CSV.write(joinpath(inputs_path, "Simultaneous_AE_Tuning_Summary.csv"), agg)

    println(" -- Simultaneous AE AutoTune best: N=$(bestN), D=$(bestD), λ=$(bestL), " *
            "TrainMAPE=$(round(bestTrain,digits=3)), " *
            "ValidMAPE=$(round(bestValid,digits=3))")

    return bestL, bestN, bestD, df, agg
end


function run_one_sim_AE_config!(inputs_path, settings_path, optimizer, base_setup, n_filters, latent_dim, lambda, k_weeks)
    mysetup = deepcopy(base_setup)
    mysetup["TimeDomainReduction"] = 1

    # inject hyperparams (adjust key names to what run_time_domain_reduction reads)
    AE = mysetup["AutoEncoder"]

    # inject tuned hyperparameters
    AE["n_filters"]  = n_filters
    AE["latent_dim"] = latent_dim
    AE["lambda"]      = lambda  

    # fix number of rep periods
    mysetup["MinPeriods"] = k_weeks
    mysetup["MaxPeriods"] = k_weeks
    mysetup["TimeDomainReductionFolder"] = "TDR_Results_$(k_weeks)_Weeks_N$(n_filters)_D$(latent_dim)_L$(lambda)"

    FinalOutputData, W, RMSE, col_to_zone_map, ae_time, clus_time =
        run_time_domain_reduction(inputs_path, settings_path, mysetup)

    solver   = configure_solver(settings_path, optimizer)
    myinputs = load_all_inputs(mysetup, inputs_path)
    EP       = generate_model(mysetup, myinputs, solver)
    EP, solve_time = solve_model(EP, mysetup)
    myinputs["solve_time"] = solve_time

    outfolder = "Results_$(k_weeks)_Weeks_N$(n_filters)_D$(latent_dim)_L$(lambda)"
    outpath = write_all_outputs(EP, mysetup, myinputs, inputs_path; output_folder=outfolder)

    return joinpath(inputs_path, outfolder), solve_time
end


################################################################################################
#################################### AutoTune AE Secondary Functions ###########################
################################################################################################

function ensure_full_year_baseline(inputs_path::AbstractString, settings_path::AbstractString, optimizer::DataType)
    full_dir = joinpath(inputs_path, "Results_Full_Year")
    csv_path = joinpath(full_dir, "capacity_multi_sector.csv")

    if isfile(csv_path)
        println(" -- Using existing full-year baseline at $(csv_path)")
        return full_dir
    end

    println(" -- Full-year baseline not found. Running full year (TDR=0)...")
    base_setup = load_settings(settings_path)
    base_setup["TimeDomainReduction"] = 0

    solver   = configure_solver(settings_path, optimizer)
    myinputs = load_all_inputs(base_setup, inputs_path)
    EP       = generate_model(base_setup, myinputs, solver)
    EP, solve_time = solve_model(EP, base_setup)
    myinputs["solve_time"] = solve_time
    outpath = write_all_outputs(EP, base_setup, myinputs, inputs_path; output_folder="Results_Full_Year")

    return full_dir
end


function load_cap_multi_sector(csv::AbstractString)
    if !isfile(csv)
        error("capacity_multi_sector.csv not found: $csv")
    end
    df = CSV.read(csv, DataFrame)
    if :Resource ∈ names(df)
        df.Resource = string.(df.Resource)
        # Drop 'Total' if present
        df = filter(row -> lowercase(strip(string(row.Resource))) != "total", df)
    end
    for col in (:AnnualGeneration, :EndCap, :EndEnergyCap)
        if col ∈ names(df)
            df[!, col] = coalesce.(parse.(Float64, string.(df[!, col])), 0.0)
        end
    end
    return df
end


function mape_by_resource(rep_df::DataFrame, full_df::DataFrame, value_col::Symbol)

    rep = combine(groupby(rep_df, :Resource), value_col => sum => :rep)[:, [:Resource, :rep]]
    println(rep)

    ful = combine(groupby(full_df, :Resource), value_col => sum => :ful)[:, [:Resource, :ful]]
    println(ful)

    merged = outerjoin(rep, ful, on=:Resource)
    println(merged)

    replace!(merged.rep, missing=>0.0); replace!(merged.ful, missing=>0.0)
    num = sum(abs.(merged.rep .- merged.ful))
    println(num)

    den = sum(abs.(merged.ful))
    println(den)
    return den == 0.0 ? 0.0 : (num/den) * 100.0
end

# Wrap for multiple metrics; returns average MAPE over chosen metrics
function avg_mape(rep_csv::AbstractString, full_csv::AbstractString, metrics::Vector{String})
    # Load
    rep  = load_cap_multi_sector(rep_csv)
    full = load_cap_multi_sector(full_csv)

    # Drop the last row (assumed "Total") if present
    rep  = rep[1:end-1, :]
    full = full[1:end-1, :]

    # Compute MAPE for each metric (accept metrics as Strings)
    syms = Symbol.(metrics)
    vals = [mape_by_resource(rep, full, s) for s in syms]

    println("\nMAPE values for metrics = ", metrics, " → ", vals)

    # Mean over valid entries (skip NaN)
    valid = filter(!isnan, vals)
    return isempty(valid) ? NaN : mean(valid)
end

