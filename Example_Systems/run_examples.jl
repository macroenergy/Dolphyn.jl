cases = [
    joinpath(@__DIR__, "SmallNewEngland", "OneZone", "Run.jl"),
    joinpath(@__DIR__, "SmallNewEngland", "ThreeZones", "Run.jl"),
    joinpath(@__DIR__, "SmallNewEngland", "ThreeZones_Liquid", "Run.jl"),
    joinpath(@__DIR__, "SmallNewEngland", "ThreeZones_Gurobi", "Run.jl"),
    joinpath(@__DIR__, "Eastern_US_CSC", "ThreeZones", "Run.jl"),
    joinpath(@__DIR__, "ERCOT_1stg_hourly_5GW_base_tmr", "Run.jl"),
    joinpath(@__DIR__, "NorthSea_2030", "Run.jl"),
    joinpath(@__DIR__, "NorthSea_2040_SF_Examples", "Run.jl"),
]

for case in cases
    include(case)
end