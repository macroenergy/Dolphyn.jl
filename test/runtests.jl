

using Test

println("Test One Zone Case")
@test include("../Example_Systems/SmallNewEngland/OneZone/Run.jl") === nothing
println("One Zone Case Test Passed")

println("Test Three Zones Case")
@test include("../Example_Systems/SmallNewEngland/ThreeZones/Run.jl") === nothing
println("Three Zones Case Test Passed")

# println("Test Three Zones Case with Liquid Hydrogen")
# @test include("../Example_Systems/SmallNewEngland/ThreeZones_Liquid/Run.jl") === nothing
# println("Three Zones with Liquid Hydrogen Case Test Passed")
