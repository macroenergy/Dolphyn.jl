

################################################################################
## function output
##
## description: Writes results to multiple .csv output files in path directory
##
## returns: n/a
################################################################################
@doc raw"""
  write_liquid_fuels_outputs(EP::Model, genx_path::AbstractString, setup::Dict, inputs::Dict)

Function (entry-point) for reporting the different output files of liquid fuels supply chain. From here, onward several other functions are called, each for writing specific output files, like costs, capacities, etc.
"""
function write_liquid_fuels_outputs(EP::Model, genx_path::AbstractString, setup::Dict, inputs::Dict)

  ## Use appropriate directory separator depending on Mac or Windows config
  if Sys.isunix()
    sep = "/"
    elseif Sys.iswindows()
    sep = "\U005c"
    else
        sep = "/"
  end

  if !haskey(setup, "OverwriteResults") || setup["OverwriteResults"] == 1
    # Overwrite existing results if dir exists
    # This is the default behaviour when there is no flag, to avoid breaking existing code
    # Create directory if it does not exist
    path = joinpath(genx_path, "Results_LF");
  if !(isdir(path))
          mkpath(path)
      end
  else
    # Find closest unused ouput directory name
    path = choose_lf_output_dir(genx_path)
    # Create directory if it does not exist
    if !(isdir(path))
        mkpath(path)
    end
  end

  write_synfuel_capacity(path, sep, inputs, setup, EP)
  write_synfuel_gen(path, sep, inputs, setup, EP)
  write_liquid_fuel_demand_balance(path, sep, inputs, setup, EP)
  write_liquid_fuel_balance_dual(path, sep, inputs, setup, EP)
  write_synfuel_balance(path, sep, inputs, setup, EP)
  write_synfuel_costs(path, sep, inputs, setup, EP)
  write_synfuel_emissions(path,sep,inputs, setup, EP)

  ## Print confirmation
  println("Wrote SF outputs to $path$sep")

end # END output()
