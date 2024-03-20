using Dolphyn

function test_generate_model()
    inputs_path = @__DIR__
    settings_path = joinpath(@__DIR__, "Settings")
    benchmark_generate_case(inputs_path, settings_path)
    println("Model generation benchmark completed")
    return nothing
end

# function test_model()
#     inputs_path = @__DIR__
#     settings_path = joinpath(@__DIR__, "Settings")
#     benchmark_single_case(inputs_path, settings_path)
#     println("Full benchmark completed")
#     return nothing
# end

# test_model()
test_generate_model()