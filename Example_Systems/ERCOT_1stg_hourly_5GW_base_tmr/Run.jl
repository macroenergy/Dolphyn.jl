using Dolphyn

EP, myinputs, mysetup, adjusted_outpath = run_case(@__DIR__)

# Run MGA if the MGA flag is set to 1 else only save the least cost solution
# Only valid for power system analysis at this point
if mysetup["ModelingToGenerateAlternatives"] == 1
    println("Starting Model to Generate Alternatives (MGA) Iterations")
    mga(EP,inputs_path,mysetup,myinputs,outpath_GenX)
end