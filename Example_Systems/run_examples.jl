using Dolphyn

# This script will generate the models with HiGHS and Gurobi for the cases in the list below
# Force the code to use HiGHS using the flag below if you prefer

force_highs = false
gurobi_installed = Dolphyn.check_if_solver_installed("Gurobi")
use_TDR = true
force_TDR_recluster = true

highs_cases = [
    joinpath(@__DIR__, "SmallNewEngland", "OneZone"),
    joinpath(@__DIR__, "SmallNewEngland", "ThreeZones"),
    joinpath(@__DIR__, "SmallNewEngland", "ThreeZones_Liquid"),
    joinpath(@__DIR__, "Eastern_US_CSC", "ThreeZones"),
    joinpath(@__DIR__, "ERCOT_1stg_hourly_5GW_base_tmr"),
    joinpath(@__DIR__, "NorthSea_2030"),
    joinpath(@__DIR__, "NorthSea_2040_SF_Examples"),
]

gurobi_cases = [
    joinpath(@__DIR__, "SmallNewEngland", "ThreeZones_Gurobi"),
]

if gurobi_installed && !force_highs
    println("Gurobi is installed. Will use Gurobi for all cases")
    # Combine highs_cases and gurobi_cases
    gurobi_cases = vcat(highs_cases, gurobi_cases)
    highs_cases = String[]
else
    println("Gurobi is not installed. Will use HiGHS for all cases")
end

summary = []

if use_TDR
    println("Time Domain Reduction is enabled")
    force_TDR_on = true
    force_TDR_off = false
else
    println("Time Domain Reduction is disabled")
    force_TDR_on = false
    force_TDR_off = true
end

if force_TDR_recluster
    println("Forcing TDR recluster")
end

for case in highs_cases
    case_name = get_case_name(case, "Example_Systems")

    println(" ------ ------ ------")
    println("Generating and running model for $case_name ...")
    try
        (EP,_,mysetup,_) = run_case(case; force_TDR_on=force_TDR_on, force_TDR_off=force_TDR_off, force_TDR_recluster=force_TDR_recluster)
        scale_factor = mysetup["ParameterScale"] == 1 ? Dolphyn.ModelScalingFactor : 1 
        obj_value = value(EP[:eObj]) * scale_factor
        push!(summary, "🟢 $(case_name) | Obj = $(round(obj_value,digits=0))")
        println("Ran model for $case.")
    catch Exception
        println("Failed to run model for $case")
        push!(summary, "🔴 $(case_name)")
    end
end

if gurobi_installed
    using Gurobi
    
    for case in gurobi_cases
        case_name = get_case_name(case, "Example_Systems")

        println(" ------ ------ ------")
        println("Generating and running model for $case_name ...")
        try
            (EP,_,mysetup,_) = run_case(case; optimizer=Gurobi.Optimizer, force_TDR_on=force_TDR_on, force_TDR_off=force_TDR_off, force_TDR_recluster=force_TDR_recluster)
            scale_factor = mysetup["ParameterScale"] == 1 ? Dolphyn.ModelScalingFactor : 1 
            obj_value = Dolphyn.obj_value(EP, mysetup)
            push!(summary, "🟢 $(case_name) | Obj = $(round(obj_value,digits=0))")
            println("Ran model for $case.")
        catch Exception
            println(Exception)
            println("Failed to run model for $case")
            push!(summary, "🔴 $(case_name)")
        end
    end
else 
    println(" ------ ------ ------")
    println("Gurobi is not installed. Skipping those cases")
end

# In the summary array, split each on "|" and find the longest first element
# Then, right-pad all the first elements to that length with spaces
# Then recombine with the later elements and print
max_length = maximum([length(split(s,"|")[1]) for s in summary])
summary = [split(s,"|") for s in summary]
summary = ["$(s[1])$(repeat(" ", max_length - length(s[1]))) | $(s[2])" for s in summary]
println(" ------ ------ ------")
println("Summary of which cases were run successfully:")
for s in summary
    println(s)
end
println(" ------ ------ ------")