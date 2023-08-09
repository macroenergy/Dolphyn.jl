function h2_inherit_clusters(path, setup)

    data_directory = joinpath(path, setup["TimeDomainReductionFolder"]);

    if Sys.isunix()
        sep = "/"
    elseif Sys.iswindows()
        sep = "\U005c"
    else
        sep = "/"
    end

    df_load = CSV.read(data_directory*sep*"load_data.csv",DataFrame);
    Period_map =  CSV.read(data_directory*sep*"Period_map.csv",DataFrame);
    Rep_Period_Indices = unique(Period_map[!,:Rep_Period_Index]);
    
    TimestepsPerRepPeriod = df_load[1,:Timesteps_per_Rep_Period];

    rep_timesteps=[];
    T = 1:length(Period_map[!,:Period_Index])*TimestepsPerRepPeriod;
    
    for k in Rep_Period_Indices
        c = Period_map[findfirst(Period_map[!,:Rep_Period_Index].==k),:Rep_Period];
        append!(rep_timesteps,T[(c-1)*TimestepsPerRepPeriod + 1:c*TimestepsPerRepPeriod]);
    end

    HSC_load_data_all = CSV.read(path*sep*"HSC_load_data.csv",DataFrame);
    HSC_load_data = HSC_load_data_all[rep_timesteps,:];

    HSC_load_data[!,:Time_Index] = 1:length(rep_timesteps);
    HSC_load_data[1,:Voll] = HSC_load_data_all[1,:Voll];
    HSC_load_data[1,:Demand_Segment] = HSC_load_data_all[1,:Demand_Segment];
    HSC_load_data[1,:Cost_of_Demand_Curtailment_per_Tonne] = HSC_load_data_all[1,:Cost_of_Demand_Curtailment_per_Tonne];
    HSC_load_data[1,:Max_Demand_Curtailment] = HSC_load_data_all[1,:Max_Demand_Curtailment];

    HSC_load_data[!,:Rep_Periods] = df_load[!,:Rep_Periods];
    HSC_load_data[!,:Timesteps_per_Rep_Period] = df_load[!,:Timesteps_per_Rep_Period];
    HSC_load_data[!,:Sub_Weights] = df_load[!,:Sub_Weights];
  
    HSC_generators_variability_all = CSV.read(path*sep*"HSC_generators_variability.csv",DataFrame);
    HSC_generators_variability = HSC_generators_variability_all[rep_timesteps,:];
    HSC_generators_variability[!,:Time_Index] = 1:length(rep_timesteps);

    HSC_g2p_variability_all = CSV.read(path*sep*"HSC_g2p_variability.csv",DataFrame);
    HSC_g2p_variability = HSC_g2p_variability_all[rep_timesteps,:];
    HSC_g2p_variability[!,:Time_Index] = 1:length(rep_timesteps);

    CSV.write(data_directory*sep*"HSC_load_data.csv",HSC_load_data)
    CSV.write(data_directory*sep*"HSC_generators_variability.csv",HSC_generators_variability)
    CSV.write(data_directory*sep*"HSC_g2p_variability.csv",HSC_g2p_variability)
end