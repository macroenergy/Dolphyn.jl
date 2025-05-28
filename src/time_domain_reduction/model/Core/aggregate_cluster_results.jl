@doc raw"""
    aggregate_cluster_results(
        A::Vector{Int},
        W::Vector{<:Real},
        M::Vector{Int},
        ClusteringInputDF::DataFrame,
        ModifiedData::DataFrame,
        InputData::DataFrame,
        ConstCols::Vector{<:AbstractString},
        ConstData::Vector,
        ColumnNames::Dict,
        Flags::Dict,
        NClusters::Int,
        ExtremeWksList::Vector{Int},
        Ncols::Int,
        NumDataPoints::Int,
        mysetup::Dict,
        myTDRsetup::Dict,
        v::Bool = false
    )
"""

function aggregate_cluster_results(
            A::Vector{Int},
            W::Vector{<:Real},
            M::Vector{Int},
            ClusteringInputDF::DataFrame,
            ModifiedData::DataFrame,
            InputData::DataFrame,
            ConstCols::Vector{<:AbstractString},
            ConstData::Vector,
            ColumnNames::Dict,
            Flags::Dict,
            NClusters::Int,
            ExtremeWksList::Vector{Int},
            Ncols::Int,
            NumDataPoints::Int,
            mysetup::Dict,
            myTDRsetup::Dict,
            v::Bool = false
        )

    # Load column names from ColumnNames dictionary
    load_col_names       = ColumnNames["load_col_names"]
    var_col_names        = ColumnNames["var_col_names"]
    fuel_col_names       = ColumnNames["fuel_col_names"]
    h2_load_col_names    = ColumnNames["h2_load_col_names"]
    h2_var_col_names     = ColumnNames["h2_var_col_names"]
    h2_g2p_var_col_names = ColumnNames["h2_g2p_var_col_names"]
    h2_load_liq_col_names = ColumnNames["h2_load_liq_col_names"]
    OldColNames          = ColumnNames["OldColNames"]
    NewColNames          = ColumnNames["NewColNames"]

    # Load flags 
    AllHRVarConst     = Flags["AllHRVarConst"]
    AllHG2PVarConst   = Flags["AllHG2PVarConst"]
    LoadExtremePeriod = Flags["LoadExtremePeriod"]
    IncludeFuel       = Flags["IncludeFuel"]

    # Accept model parameters from the settings file time_domain_reduction_settings.yml
    TimestepsPerRepPeriod = myTDRsetup["TimestepsPerRepPeriod"]
    UseExtremePeriods = myTDRsetup["UseExtremePeriods"]
    WeightTotal = myTDRsetup["WeightTotal"]

    ####################################################################################

    # Set clustering outputs in correct numeric order.
    # Add the subperiods corresponding to the extreme periods back into the data.
    # Rescale weights to total user-specified number of hours (e.g., 8760 for one year).
    # If DemandExtremePeriod=false (because we don't want to change peak demand day), rescale demand to ensure total demand is equal.

    # K-means/medoids returns indices from DistMatrix as its medoids.
    #   This does not account for missing extreme weeks.
    #   This is corrected retroactively here.
    
    # Orginal M is produced in alphabetical order - 10th column is not the 10th data point in chronological order
    # Hence need to identify the right data point number based on column name
    M = [parse(Int64, string(names(ClusteringInputDF)[i])) for i in M]
    
    if v println(" -- Fixed M: ", M) end
    

    # ClusterInputDF Ordering of All Periods (i.e., alphabetical as opposed to indices)
    A_Dict = Dict()   # States index of representative period within M for each period a in A
    M_Dict = Dict()   # States representative period m for each period a in A
    for i in 1:length(A)
        A_Dict[parse(Int64, string(names(ClusteringInputDF)[i]))] = A[i]
        M_Dict[parse(Int64, string(names(ClusteringInputDF)[i]))] = M[A[i]]
    end
      
    # Add extreme periods into the clustering result with # of occurences = 1 for each
    ExtremeWksList = sort(ExtremeWksList)
    if UseExtremePeriods == 1
        if v
            println("Extreme Periods: ", ExtremeWksList)
        end
        M = [M; ExtremeWksList]
        A_idx = NClusters + 1
        for w in ExtremeWksList
            A_Dict[w] = A_idx
            M_Dict[w] = w
            push!(W, 1)
            A_idx += 1
        end
        NClusters += length(ExtremeWksList) #NClusers from this point forward is the ending number of periods
    end 

    ########################################
    # Recreate A in numeric order (as opposed to ClusterInputDF order)
    A = [A_Dict[i] for i in 1:(length(A) + length(ExtremeWksList))]

    N = W  # Keep cluster version of weights stored as N, number of periods represented by RP

    # Rescale weights to total user-specified number of hours
    W = scale_weights(W, WeightTotal, v)

    # Order representative periods chronologically
    #   SORT A W M in conjunction, chronologically by M, before handling them elsewhere to be consistent
    #   A points to an index of M. We need it to point to a new index of sorted M. Hence, AssignMap.
    old_M = M
    df_sort = DataFrame( Weights = W, NumPeriods = N, Rep_Period = M)
    sort!(df_sort, [:Rep_Period])
    W = df_sort[!, :Weights]
    N = df_sort[!, :NumPeriods]
    M = df_sort[!, :Rep_Period]
    # Sorting the representative periods to be in chronological order
    AssignMap = Dict( i => findall(x->x==old_M[i], M)[1] for i in 1:length(M))
    A = [AssignMap[a] for a in A]

  
    # Make PeriodMap, maps each period to its representative period
    PeriodMap = DataFrame(Period_Index = 1:length(A),
                            Rep_Period = [M[a] for a in A],
                            Rep_Period_Index = [a for a in A])

    ######################################

    # Get Symbol-version of column names by type for later analysis
    LoadCols = [Symbol("Load_MW_z"*string(i)) for i in 1:length(load_col_names) ]
    VarCols = [Symbol(var_col_names[i]) for i in 1:length(var_col_names) ]
    FuelCols = [Symbol(fuel_col_names[i]) for i in 1:length(fuel_col_names) ]
    ConstCol_Syms = [Symbol(ConstCols[i]) for i in 1:length(ConstCols) ]

    LoadColsNoConst = setdiff(LoadCols, ConstCol_Syms)

    if mysetup["ModelH2"] == 1
        H2LoadCols = [Symbol("Load_H2_MW_z"*string(i)) for i in 1:length(h2_load_col_names) ]
        H2LoadLiqCols = [Symbol("Load_liqH2_MW_z"*string(i)) for i in 1:length(h2_load_liq_col_names) ]
        H2VarCols = [Symbol(h2_var_col_names[i]) for i in 1:length(h2_var_col_names) ]
        H2G2PVarCols = [Symbol(h2_g2p_var_col_names[i]) for i in 1:length(h2_g2p_var_col_names) ]
    end

    # Cluster Ouput: The original data at the medoids/centers
    ClusterOutputData = ModifiedData[:,Symbol.(M)]

    # Get zone-wise load multipliers for later scaling in order for weighted-representative-total-zonal load to equal original total-zonal load
    #  (Only if we don't have load-related extreme periods because we don't want to change peak load periods)
    if !LoadExtremePeriod
        load_mults = get_load_multipliers(ClusterOutputData, InputData, M, W, LoadColsNoConst, TimestepsPerRepPeriod, NewColNames, NClusters, Ncols)
    end

    # Reorganize Data by Load, Solar, Wind, Fuel, and GrpWeight by Hour, Add Constant Data Back In
    rpDFs = [] # Representative Period DataFrames - Load and Resource Profiles
    gvDFs = [] # Generators Variability DataFrames - Just Resource Profiles
    lpDFs = [] # Load Profile DataFrames - Just Load Profiles
    fpDFs = [] # Fuel Profile DataFrames - Just Fuel Profiles

    if mysetup["ModelH2"] == 1
        hrvDFs = [] # Hydrogen resource variability DataFrames
        hlpDFs = [] # Hydrogen load profiles
        hllpDFs = [] # liquid Hydrogen load profiles
        hrvg2pDFs = []
    end
    
    for m in 1:NClusters
        rpDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols) )
        gvDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in VarCols)) )
        lpDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in LoadCols)) )
        if IncludeFuel fpDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in FuelCols)) ) end
        if !IncludeFuel fpDF = DataFrame(Placeholder = 1:TimestepsPerRepPeriod) end

        if mysetup["ModelH2"] == 1
            hrvDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in H2VarCols)) )
            hlpDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in H2LoadCols)) )

            AllH2LoadVarConst =  length(intersect(H2LoadCols, ConstCol_Syms)) == length(H2LoadCols)

            if AllH2LoadVarConst
                hlpDF = DataFrame(Placeholder = 1:TimestepsPerRepPeriod)
            end

            if AllHRVarConst
                hrvDF = DataFrame(Placeholder = 1:TimestepsPerRepPeriod)
            end
            
            if mysetup["ModelH2Liquid"] == 1
                hllpDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in H2LoadLiqCols)) )
            end

            if mysetup["ModelH2G2P"] == 1

                hrvg2pDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in H2G2PVarCols)))

                if AllHG2PVarConst
                    hrvg2pDF = DataFrame(Placeholder = 1:TimestepsPerRepPeriod)
                end

            else
                hrvg2pDF = []
            end


        else
            hrvDF = []
            hlpDF = []
            hllpDF = []
            hrvg2pDF = []
        end
                
        # Add Constant Columns back in
        for c in 1:length(ConstCols)
            rpDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
            if Symbol(ConstCols[c]) in VarCols
                gvDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
            elseif Symbol(ConstCols[c]) in FuelCols
                fpDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
            elseif Symbol(ConstCols[c]) in LoadCols
                lpDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
            elseif mysetup["ModelH2"] == 1
                if Symbol(ConstCols[c]) in H2VarCols
                    hrvDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
                elseif Symbol(ConstCols[c]) in H2LoadCols
                    hlpDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
                end

                if mysetup["ModelH2Liquid"] == 1
                    if Symbol(ConstCols[c]) in H2LoadLiqCols
                        hllpDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
                    end
                end
                
                if mysetup["ModelH2G2P"] == 1
                    if Symbol(ConstCols[c]) in H2G2PVarCols
                        hrvg2pDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
                    end
                end

            end
        end

        if !IncludeFuel select!(fpDF, Not(:Placeholder)) end
        

        # Scale Load using previously identified multipliers
        #   Scale lpDF but not rpDF which compares to input data but is not written to file.
        if !LoadExtremePeriod
            for loadcol in LoadCols
                if loadcol ∉ ConstCol_Syms
                    lpDF[!,loadcol] .*= load_mults[loadcol]
                end
            end
        end

        rpDF[!,:GrpWeight] .= W[m]
        rpDF[!,:Cluster] .= M[m]
        push!(rpDFs, rpDF)
        push!(gvDFs, gvDF)
        push!(lpDFs, lpDF)
        push!(fpDFs, fpDF)
        
        if mysetup["ModelH2"] == 1
            if AllHRVarConst select!(hrvDF, Not(:Placeholder)) end 
            push!(hrvDFs, hrvDF)
            push!(hlpDFs, hlpDF)

            if mysetup["ModelH2Liquid"] == 1
                push!(hllpDFs, hllpDF)
            end

            if mysetup["ModelH2G2P"] == 1
                if AllHG2PVarConst select!(hrvg2pDF, Not(:Placeholder))end
                push!(hrvg2pDFs, hrvg2pDF)
            end

        end
    end
    FinalOutputData = vcat(rpDFs...)  # For comparisons with input data to evaluate clustering process
    GVOutputData = vcat(gvDFs...)     # Generators Variability
    LPOutputData = vcat(lpDFs...)     # Load Profiles
    FPOutputData = vcat(fpDFs...)     # Load Profiles

    if mysetup["ModelH2"] == 1
        HLPOutputData = vcat(hlpDFs...) #Hydrogen Load Profiles
        HRVOutputData = vcat(hrvDFs...) #Hydrogen Resource Variability Profiles
        
        if mysetup["ModelH2Liquid"] == 1
            HLLPOutputData = vcat(hllpDFs...) #Hydrogen Load Profiles
        end
        
        if mysetup["ModelH2G2P"] == 1
            HG2POutputData = vcat(hrvg2pDFs...)
        end

    end

    InputDataTest = InputData[(InputData.Group .<= NumDataPoints*1.0), :]
    ClusterDataTest = vcat([rpDFs[a] for a in A]...) # To compare fairly, load is not scaled here
    RMSE = Dict( c => rmse_score(InputDataTest[:, c], ClusterDataTest[:, c])  for c in OldColNames)

    OutputData = Dict(
        "GVOutputData"      => GVOutputData,
        "LPOutputData"      => LPOutputData,
        "FPOutputData"      => FPOutputData,
        "HLPOutputData"     => (mysetup["ModelH2"] == 1 ? HLPOutputData : nothing),
        "HRVOutputData"     => (mysetup["ModelH2"] == 1 ? HRVOutputData : nothing),
        "HLLPOutputData"    => (mysetup["ModelH2Liquid"] == 1 ? HLLPOutputData : nothing),
        "HG2POutputData"    => (mysetup["ModelH2G2P"] == 1 ? HG2POutputData : nothing)
    )

    return FinalOutputData, OutputData, PeriodMap, W, M, A, RMSE

end