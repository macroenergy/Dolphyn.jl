using DOLPHYN
using YAML
using LoggingExtras

# Walk into current directory
case_dir = @__DIR__

settings_path = joinpath(case_dir, "Settings")
inputs_path = case_dir

# Loading settings
genx_settings = joinpath(settings_path, "genx_settings.yml") #Settings YAML file path for GenX
hsc_settings = joinpath(settings_path, "hsc_settings.yml") #Settings YAML file path for HSC modelgrated model
mysetup_genx = YAML.load(open(genx_settings)) # mysetup dictionary stores GenX-specific parameters
mysetup_hsc = YAML.load(open(hsc_settings)) # mysetup dictionary stores H2 supply chain-specific parameters
global_settings = joinpath(settings_path, "global_model_settings.yml") # Global settings for inte
mysetup_global = YAML.load(open(global_settings)) # mysetup dictionary stores global settings
mysetup = Dict()
mysetup = merge(mysetup_hsc, mysetup_genx, mysetup_global) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings

# Start logging
global Log = mysetup["Log"]

if Log
    logger = FileLogger(mysetup["LogFile"])
    global_logger(logger)
end

### Load DOLPHYN
println("Loading packages")
# push!(LOAD_PATH, src_path)

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

# ### Configure solver
print_and_log("Configuring Solver")
OPTIMIZER = configure_solver(mysetup["Solver"], settings_path)

# #### Running a case

# ### Load inputs
# print_and_log("Loading Inputs")
 myinputs = Dict() # myinputs dictionary will store read-in data and computed parameters
 myinputs = load_inputs(mysetup, inputs_path)

# ### Load H2 inputs if modeling the hydrogen supply chain
if mysetup["ModelH2"] == 1
    myinputs = load_h2_inputs(myinputs, mysetup, inputs_path)
end

# ### Generate model
# print_and_log("Generating the Optimization Model")
EP = generate_model(mysetup, myinputs, OPTIMIZER)

### Solve model
print_and_log("Solving Model")
EP, solve_time = solve_model(EP, mysetup)
myinputs["solve_time"] = solve_time # Store the model solve time in myinputs

### Write power system output

print_and_log("Writing Output")
outpath = "$inputs_path/Results"
outpath=write_outputs(EP, outpath, mysetup, myinputs)

# Write hydrogen supply chain outputs
outpath_H2 = "$outpath/Results_HSC"
if mysetup["ModelH2"] == 1
    write_HSC_outputs(EP, outpath_H2, mysetup, myinputs)
end
