#include("helper_files.jl")
function step4_data_aggregation(WeightTotal, load_col_names, var_col_names, fuel_col_names, ConstCols, h2_load_col_names, h2_var_col_names, h2_g2p_var_col_names, InputData, TimestepsPerRepPeriod, NewColNames, Ncols, ConstData, IncludeFuel, AllHRVarConst, AllHG2PVarConst, ExtremeWksList, NClusters, ModifiedData, LoadExtremePeriod,  M, W, A, UseExtremePeriods, mysetup, v)

    # Add the subperiods corresponding to the extreme periods back into the data.
    # Rescale weights to total user-specified number of hours (e.g., 8760 for one year).
    # If LoadExtremePeriod=false (because we don't want to change peak load day), rescale load to ensure total demand is equal

    # Add extreme periods into the clustering result with # of occurences = 1 for each
        ExtremeWksList = sort(ExtremeWksList)
        if UseExtremePeriods == 1
            if v println("Extreme Periods: ", ExtremeWksList) end
            M = [M; ExtremeWksList]
            for w in 1:length(ExtremeWksList)
                insert!(A, ExtremeWksList[w], NClusters+w)
                push!(W, 1)
            end
            NClusters += length(ExtremeWksList) #NClusers from this point forward is the ending number of periods
        end

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
        AssignMap = Dict( i => findall(x->x==old_M[i], M)[1] for i in 1:length(M))
        A = [AssignMap[a] for a in A]

        # Make PeriodMap, maps each period to its representative period
        PeriodMap = DataFrame(Period_Index = 1:length(A),
                                Rep_Period = [M[a] for a in A],
                                Rep_Period_Index = [a for a in A])

        # Get Symbol-version of column names by type for later analysis
        LoadCols = [Symbol("Load_MW_z"*string(i)) for i in 1:length(load_col_names) ]
        VarCols = [Symbol(var_col_names[i]) for i in 1:length(var_col_names) ]
        FuelCols = [Symbol(fuel_col_names[i]) for i in 1:length(fuel_col_names) ]
        ConstCol_Syms = [Symbol(ConstCols[i]) for i in 1:length(ConstCols) ]

        LoadColsNoConst = setdiff(LoadCols, ConstCol_Syms)

        if mysetup["ModelH2"] == 1
            H2LoadCols = [Symbol("Load_H2_tonne_per_hr_z"*string(i)) for i in 1:length(h2_load_col_names) ]
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

            if mysetup["ModelH2G2P"] == 1
                HG2POutputData = vcat(hrvg2pDFs...)
            end

        end

    println("Data is processed")

    return FinalOutputData, GVOutputData, LPOutputData, FPOutputData, HLPOutputData, HRVOutputData, HG2POutputData, rpDFs, LoadCols, PeriodMap, FuelCols, H2LoadCols

end
