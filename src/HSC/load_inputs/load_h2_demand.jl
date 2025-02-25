

@doc raw"""
    load_h2_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

Function for reading input parameters related to hydrogen load (demand) of each zone.
"""
function load_h2_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

    data_directory = joinpath(path, setup["TimeDomainReductionFolder"])
    
    if setup["TimeDomainReduction"] == 1 && isfile(joinpath(data_directory,"HSC_load_data.csv")) # Use Time Domain Reduced data for GenX
        H2_load_in = DataFrame(CSV.File(string(joinpath(data_directory,"HSC_load_data.csv")), header=true), copycols=true)
    else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
        H2_load_in = DataFrame(CSV.File(joinpath(path, "HSC_load_data.csv"), header=true), copycols=true)
    end

    # Number of demand curtailment/lost load segments
    inputs["H2_SEG"]=size(collect(skipmissing(H2_load_in[!,:Demand_Segment])),1)

    # Set T and Z if GenX hasn't run
    if !haskey(inputs, "T")
        inputs["T"] = size(H2_load_in, 1)
    end
    if !haskey(inputs, "Z")
        inputs["Z"] = count(s -> occursin("Load_H2_MW_z", s), names(H2_load_in))
    end

    T = inputs["T"]
    Z = inputs["Z"]

    # Demand in MWh per hour for each zone
    start = findall(s -> s == "Load_H2_MW_z1", names(H2_load_in))[1]
    # Max value of non-served energy in $/MWh
    inputs["H2_Voll"] = collect(skipmissing(H2_load_in[!,:Voll]))
    # Demand in MWh per hour      
    inputs["H2_D"] =Matrix(H2_load_in[1:T,start:start-1+Z])    

    # Cost of non-served energy/demand curtailment (for each segment)
    H2_SEG = inputs["H2_SEG"]  # Number of demand segments
    inputs["pC_H2_D_Curtail"] = zeros(H2_SEG)
    inputs["pMax_H2_D_Curtail"] = zeros(H2_SEG)
    for s in 1:H2_SEG
        # Cost of each segment reported as a fraction of value of non-served energy - scaled implicitly
        inputs["pC_H2_D_Curtail"][s] = collect(skipmissing(H2_load_in[!,:Segment_Cost_of_Demand_Curtailment_Fraction]))[s]*inputs["H2_Voll"][1]
        # Maximum hourly demand curtailable as % of the max demand (for each segment)
        inputs["pMax_H2_D_Curtail"][s] = collect(skipmissing(H2_load_in[!,:Max_Demand_Curtailment]))[s]

    end

    if !haskey(inputs, "omega")
        as_vector(col::Symbol) = collect(skipmissing(H2_load_in[!, col]))

        inputs["omega"] = zeros(Float64, T) # weights associated with operational sub-period in the model - sum of weight = 8760
        # Weights for each period - assumed same weights for each sub-period within a period
        inputs["Weights"] = as_vector(:Sub_Weights) # Weights each period

        # Total number of periods and subperiods
        inputs["REP_PERIOD"] = convert(Int16, as_vector(:Rep_Periods)[1])
        inputs["H"] = convert(Int64, as_vector(:Timesteps_per_Rep_Period)[1])

        # Creating sub-period weights from weekly weights
        for w in 1:inputs["REP_PERIOD"]
            for h in 1:inputs["H"]
                t = inputs["H"]*(w-1)+h
                inputs["omega"][t] = inputs["Weights"][w]/inputs["H"]
            end
        end

        # Create time set steps indicies
        inputs["hours_per_subperiod"] = div.(T,inputs["REP_PERIOD"]) # total number of hours per subperiod
        hours_per_subperiod = inputs["hours_per_subperiod"] # set value for internal use

        inputs["START_SUBPERIODS"] = 1:hours_per_subperiod:T 	# set of indexes for all time periods that start a subperiod (e.g. sample day/week)
        inputs["INTERIOR_SUBPERIODS"] = setdiff(1:T, inputs["START_SUBPERIODS"]) # set of indexes for all time periods that do not start a subperiod

    end
    
    print_and_log(" -- HSC_load_data.csv Successfully Read!")

    return inputs

end

function h2_demand_search_str(Zones::Union{Vector{Int64}, Vector{String}})
    if typeof(Zones[1]) == Int64
        # Zones are of the form 1, 2, 3, ...
        search_str = "Load_H2_MW_z"
    elseif typeof(Zones[1]) == String
        # Zones are of the form z1, z2, z3, ...
        search_str = "Load_H2_MW_"
    else
        error("Zones are neither of type Int64 nor String")
    end
    return search_str
end
