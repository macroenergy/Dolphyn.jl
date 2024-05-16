using Dolphyn

# The directory containing your settings folder and files
settings_path = joinpath(@__DIR__, "Settings")

# The directory containing your input data
inputs_path = @__DIR__

# Load settings
mysetup = load_settings(settings_path)

# Setup logging 
global_logger = setup_logging(mysetup)

### Load DOLPHYN
println("Loading packages")
# push!(LOAD_PATH, src_path)

# Setup time domain reduction and cluster inputs if necessary
setup_TDR(inputs_path, settings_path, mysetup)

# ### Configure solver
print_and_log("Configuring Solver")

OPTIMIZER = configure_solver(mysetup["Solver"], settings_path)

# #### Running a case

# ### Load inputs
# print_and_log("Loading Inputs")
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
outpath = joinpath(inputs_path,"Results")
outpath_GenX = write_outputs(EP, outpath, mysetup, myinputs)

# Write hydrogen supply chain outputs
# outpath_H2 = joinpath(outpath_GenX,"Results_HSC")
if mysetup["ModelH2"] == 1
    write_HSC_outputs(EP, outpath_GenX, mysetup, myinputs)
end
