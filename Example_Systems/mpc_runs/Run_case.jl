
using GenX
using JuMP
using CSV, DataFrames

# Save Run_case.jl directory 
Run_case_path = joinpath(@__DIR__, "Run_case.jl")
mpc_runs_dir = dirname(Run_case_path)  # This extracts the directory part from run_path
run_path = joinpath(mpc_runs_dir, "data_run") # .../mpc_runs/data_run
rolling_horizon_data_path = joinpath(run_path, "rolling_horizon_data") # .../mpc_runs/data_run/rolling_horizon_data_path
runs_results_path = joinpath(run_path, "runs_results") # .../mpc_runs/data_run/runs_results
data_year_path = joinpath(mpc_runs_dir, "data_year") #.../mpc_runs/data_year


## Set the rolling window (hrs) - currently set to 14 days (2 weeks)
window = 24 * 14

## Set the maximum number of hours in the model
max_hrs = 8760 

## Set the number of hours for which we will keep the data (set to 1 week)
keep_hrs = 24 * 7

## This gives you the number of runs
run_number = max_hrs / keep_hrs

####### This is setup for Supercloud so make sure to change your paths accordingly ########
for i in 1:run_number
    case = run_path

    function get_settings_path(case::AbstractString)
        return joinpath(case, "Settings")
    end

    function get_settings_path_yml(case::AbstractString, filename::AbstractString)
        return joinpath(get_settings_path(case), filename)
    end

    genx_settings = get_settings_path_yml(case, "genx_settings.yml") #Settings YAML file path
    mysetup = configure_settings(genx_settings) # mysetup dictionary stores settings and GenX-specific parameters

    inputs_path = case
    settings_path = get_settings_path(case)

    ### Modify the inputs to reflect the rolling window
    start_index = (i-1)*keep_hrs + 1
    end_index = (i-1)*keep_hrs + window
    idx_len = start_index:end_index

    ## Load 
    load_data_year_path = joinpath(run_path, "Load_data.csv")
    load_data = CSV.read(load_data_path)

    load_window = load_data[start_index:end_index, 'Load_MW_z1']

    run_load_data_path = joinpath(run_path, "Load_data.csv")
    run_load_data = CSV.read({run_load_data_path})
    delete!(run_load_data, :Load_MW_z1)
    delete!(run_load_data, :Time_Index)

    run_load_data['Load_MW_z1'] = load_window
    run_load_data['Time_Index'] = 1:window

    # PUT PATH TO WRITE LOAD DATA TO HERE
    CSV.write({joinpath(rolling_horizon_data_path, "Load_data.csv")}, run_load_data)

    ## Fuels_data: PUT PATH TO FUELS DATA FROM DATA_YEAR HERE
    fuels_data = CSV.read({joinpath(data_year_path, "Fuels_data.csv")})

    # Get the emissions intensities from the fuels_data
    fuels_one = fuels_data[1, :]

    # Create a new fuels_data with the emissions intensities
    fuels_window = filter(row -> row in idx_len, fuels_data)
    insert!(fuels_window, 1, fuels_one)
    
    fuels_time = 0:window
    fuels_window['Time_Index'] = fuels_time

    CSV.write({joinpath(rolling_horizon_data_path, "Fuels_data.csv")}, fuels_window)

    ## Generators_variability: PUT PATH TO GENERATORS VARIABILITY DATA FROM DATA_YEAR HERE
    genvar_data = CSV.read({joinpath(data_year_path, "Generators_variability.csv")})

    genvar_filter = filter(row -> row in idx_len, genvar_data)
    genvar_time = 0:window
    genvar_filter['Time_Index'] = genvar_time

    CSV.write({joinpath(rolling_horizon_data_path, "Generators_variability.csv")}, genvar_filter)

    

    ### Configure solver
    println("Configuring Solver")
    OPTIMIZER = configure_solver(mysetup["Solver"], settings_path)


    #### Running a case

    ### Load inputs
    println("Loading Inputs")
    myinputs = load_inputs(mysetup, case)

    println("Generating the Optimization Model")
    EP = generate_model(mysetup, myinputs, OPTIMIZER)

    println("Solving Model")
    EP, solve_time = solve_model(EP, mysetup)
    myinputs["solve_time"] = solve_time # Store the model solve time in myinputs

    # Run MGA if the MGA flag is set to 1 else only save the least cost solution
    println("Writing Output")
    # PUT THE PATH TO THE OUTPUTS FOLDER HERE
    outputs_path = {joinpath(runs_results_path, "Run_$i")}
    elapsed_time = @elapsed write_outputs(EP, outputs_path, mysetup, myinputs)
    println("Time elapsed for writing Run_$i is")
    println(elapsed_time)
end