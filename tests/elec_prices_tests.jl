using DOLPHYN
using Test

example_path = joinpath(dirname(@__DIR__), "Example_Systems", "DistDolphyn_ThreeZones")
if !isdir(example_path)
    error("Example directory not found")
end 
println("Testing using data from $example_path")

# Test without parameter scaling
setup = Dict{String, Any}(
    "TimeDomainReduction" => 0,
    "TimeDomainReductionFolder" => "TDR_Results",
    "ParameterScale" => 0,
)
inputs = Dict{String, Any}()
DOLPHYN.load_elec_import_prices(setup, example_path, inputs)
DOLPHYN.load_elec_import_limits(setup, example_path, inputs)

# Test with parameter scaling
setup = Dict{String, Any}(
    "TimeDomainReduction" => 0,
    "TimeDomainReductionFolder" => "TDR_Results",
    "ParameterScale" => 1,
)
inputs = Dict{String, Any}()
DOLPHYN.load_elec_import_prices(setup, example_path, inputs)
DOLPHYN.load_elec_import_limits(setup, example_path, inputs)

# Test that load_elec_import_limits fails gracefull
DOLPHYN.load_elec_import_limits(setup, example_path, inputs, "file_that_does_not_exist.csv")

