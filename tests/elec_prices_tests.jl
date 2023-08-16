using DOLPHYN
using Test

example_path = joinpath(dirname(@__DIR__), "Example_Systems", "DistDolphyn_ThreeZones")
if !isdir(example_path)
    error("Example directory not found. Run `git submodule update --init` to download the example data.")
end 
println("Testing using data from $example_path")

# Test without parameter scaling
setup = Dict{String, Any}(
    "TimeDomainReduction" => 0,
    "TimeDomainReductionFolder" => "TDR_Results",
    "ParameterScale" => 0,
)
inputs = Dict{String, Any}()
DOLPHYN.load_external_elec_prices!(setup, example_path, inputs)

# Test with parameter scaling
setup = Dict{String, Any}(
    "TimeDomainReduction" => 0,
    "TimeDomainReductionFolder" => "TDR_Results",
    "ParameterScale" => 1,
)
inputs = Dict{String, Any}()
DOLPHYN.load_external_elec_prices!(setup, example_path, inputs)
