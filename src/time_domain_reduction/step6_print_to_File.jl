#include("helper_files.jl")
function step6_print_to_File(inpath, TimeDomainReductionFolder, W, TimestepsPerRepPeriod, LoadCols, LPOutputData, Load_Outfile, GVOutputData, GVar_Outfile, FPOutputData, Fuel_Outfile, PeriodMap, PMap_Outfile, myTDRsetup, YAML_Outfile, myinputs, FuelCols, H2LoadCols, HLPOutputData, H2Load_Outfile, HRVOutputData, H2RVar_Outfile, HG2POutputData, H2G2PVar_Outfile, mysetup, v)
    if Sys.isunix()
		sep = "/"
    elseif Sys.iswindows()
		sep = "\U005c"
    else
        sep = "/"
	end

    mkpath(joinpath(inpath, TimeDomainReductionFolder))

    ### Load_data_clustered.csv
    load_in = DataFrame(CSV.File(string(inpath,sep,"Load_data.csv"), header=true), copycols=true) #Setting header to false doesn't take the names of the columns; not including it, not including copycols, or, setting copycols to false has no effect
    load_in[!,:Sub_Weights] = load_in[!,:Sub_Weights] * 1.
    load_in[1:length(W),:Sub_Weights] .= W
    load_in[!,:Rep_Periods][1] = length(W)
    load_in[!,:Timesteps_per_Rep_Period][1] = TimestepsPerRepPeriod
    select!(load_in, Not(LoadCols))
    select!(load_in, Not(:Time_Index))
    Time_Index_M = Union{Int64, Missings.Missing}[missing for i in 1:size(load_in,1)]
    Time_Index_M[1:size(LPOutputData,1)] = 1:size(LPOutputData,1)
    load_in[!,:Time_Index] .= Time_Index_M

    for c in LoadCols
        new_col = Union{Float64, Missings.Missing}[missing for i in 1:size(load_in,1)]
        new_col[1:size(LPOutputData,1)] = LPOutputData[!,c]
        load_in[!,c] .= new_col
    end
    load_in = load_in[1:size(LPOutputData,1),:]

    if v println("Writing load file...") end
    CSV.write(string(inpath,sep,Load_Outfile), load_in)

    ### Generators_variability_clustered.csv

    # Reset column ordering, add time index, and solve duplicate column name trouble with CSV.write's header kwarg
    GVColMap = Dict(myinputs["RESOURCE_ZONES"][i] => myinputs["RESOURCES"][i] for i in 1:length(myinputs["RESOURCES"]))
    GVColMap["Time_Index"] = "Time_Index"
    GVOutputData = GVOutputData[!, Symbol.(myinputs["RESOURCE_ZONES"])]
    insertcols!(GVOutputData, 1, :Time_Index => 1:size(GVOutputData,1))
    NewGVColNames = [GVColMap[string(c)] for c in names(GVOutputData)]
    if v println("Writing resource file...") end
    CSV.write(string(inpath,sep,GVar_Outfile), GVOutputData, header=NewGVColNames)

    ### Fuels_data_clustered.csv

    fuel_in = DataFrame(CSV.File(string(inpath,sep,"Fuels_data.csv"), header=true), copycols=true)
    select!(fuel_in, Not(:Time_Index))
    SepFirstRow = DataFrame(fuel_in[1, :])
    NewFuelOutput = vcat(SepFirstRow, FPOutputData)
    rename!(NewFuelOutput, FuelCols)
    insertcols!(NewFuelOutput, 1, :Time_Index => 0:size(NewFuelOutput,1)-1)
    if v println("Writing fuel profiles...") end
    CSV.write(string(inpath,sep,Fuel_Outfile), NewFuelOutput)

    ### Period_map.csv
    if v println("Writing period map...") end
    CSV.write(string(inpath,sep,PMap_Outfile), PeriodMap)

    ### Write Hydrogen Outputs
    if mysetup["ModelH2"] == 1
        #Write h2_load_data.csv
        h2_load_in = DataFrame(CSV.File(string(inpath,sep,"HSC_load_data.csv"), header=true), copycols=true)
        h2_load_in[!,:Sub_Weights] = h2_load_in[!,:Sub_Weights] * 1.
        h2_load_in[1:length(W),:Sub_Weights] .= W
        h2_load_in[!,:Rep_Periods][1] = length(W)
        h2_load_in[!,:Timesteps_per_Rep_Period][1] = TimestepsPerRepPeriod
        select!(h2_load_in, Not(H2LoadCols))
        select!(h2_load_in, Not(:Time_Index))
        Time_Index_M = Union{Int64, Missings.Missing}[missing for i in 1:size(h2_load_in,1)]
        Time_Index_M[1:size(HLPOutputData,1)] = 1:size(HLPOutputData,1)
        h2_load_in[!,:Time_Index] .= Time_Index_M

        for c in H2LoadCols
            new_col = Union{Float64, Missings.Missing}[missing for i in 1:size(h2_load_in,1)]
            new_col[1:size(HLPOutputData,1)] = HLPOutputData[!,c]
            h2_load_in[!,c] .= new_col
        end

        h2_load_in = h2_load_in[1:size(HLPOutputData,1),:]

        if v println("Writing load file...") end
        CSV.write(string(inpath,sep,H2Load_Outfile), h2_load_in)

        #Write HSC Resource Variability
        # Reset column ordering, add time index, and solve duplicate column name trouble with CSV.write's header kwarg
        HRVColMap = Dict(myinputs["H2_RESOURCE_ZONES"][i] => myinputs["H2_RESOURCES_NAME"][i] for i in 1:length(myinputs["H2_RESOURCES_NAME"]))
        HRVColMap["Time_Index"] = "Time_Index"
        HRVOutputData = HRVOutputData[!, Symbol.(myinputs["H2_RESOURCE_ZONES"])]
        insertcols!(HRVOutputData, 1, :Time_Index => 1:size(HRVOutputData,1))
        NewHRVColNames = [HRVColMap[string(c)] for c in names(HRVOutputData)]
        if v println("Writing resource file...") end
        println(NewHRVColNames)
        CSV.write(string(inpath,sep,H2RVar_Outfile), HRVOutputData, header=NewHRVColNames)

        if mysetup["ModelH2G2P"] == 1
            #Write HSC Resource Variability
            # Reset column ordering, add time index, and solve duplicate column name trouble with CSV.write's header kwarg
            # Dharik - string conversion needed to change from inlinestring to string type
            HG2PVColMap = Dict(myinputs["H2_G2P_RESOURCE_ZONES"][i] => string(myinputs["H2_G2P_NAME"][i]) for i in 1:length(myinputs["H2_G2P_NAME"]))
            println(HG2PVColMap)
            HG2PVColMap["Time_Index"] = "Time_Index"
            HG2POutputData = HG2POutputData[!, Symbol.(myinputs["H2_G2P_RESOURCE_ZONES"])]
            insertcols!(HG2POutputData, 1, :Time_Index => 1:size(HG2POutputData,1))
            NewHG2PVColNames = [HG2PVColMap[string(c)] for c in names(HG2POutputData)]
            println(NewHG2PVColNames)
            if v println("Writing resource file...") end
            CSV.write(string(inpath,sep,H2G2PVar_Outfile), HG2POutputData, header=NewHG2PVColNames)
        end
    end

    ### time_domain_reduction_settings.yml
    if v println("Writing .yml settings...") end
    YAML.write_file(string(inpath,sep,YAML_Outfile), myTDRsetup)

    return nothing

end
