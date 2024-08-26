using DataFrames
using CSV

const HHV_H2 = 39.38 # MWh/tonne

cases = [
    joinpath(@__DIR__,"SmallNewEngland","OneZone"),
    joinpath(@__DIR__,"SmallNewEngland","ThreeZones"),
    joinpath(@__DIR__,"SmallNewEngland","ThreeZones_Gurobi"),
    joinpath(@__DIR__,"SmallNewEngland","ThreeZones_Liquid"),
    joinpath(@__DIR__,"NorthSea_2030"),
    joinpath(@__DIR__,"Eastern_US_CSC","ThreeZones"),
    joinpath(@__DIR__,"ERCOT_1stg_hourly_5GW_base_tmr"),
    joinpath(@__DIR__,"NorthSea_2040_SF_Examples"),
]

for case in cases
# case = joinpath(@__DIR__,"SmallNewEngland","OneZone")

    case_files = readdir(case)

    # Find all the files in case_files which start with "HSC"
    hsc_files = filter(x -> occursin(r"HSC", x), case_files)


    hsc_gen_changes = Dict(
        r"etaP2G_MWh_p_tonne$" => ("etaG2P", 1/HHV_H2),
        r"etaFuel_MMBtu_p_tonne" => ("etaFuel_MMBtu_p_MWh", 1/HHV_H2),
        r"Inv_Cost_p_tonne_p_hr_yr" => ("Inv_Cost_p_MW_yr", 1/HHV_H2),
        r"Inv_Cost_Charge_p_tonne_p_hr_yr" => ("Inv_Cost_Charge_p_MW_yr", 1/HHV_H2),
        r"Inv_Cost_Energy_p_tonne_yr" => ("Inv_Cost_Energy_p_MWh_yr", 1/HHV_H2),
        r"Fixed_OM_Cost_p_tonne_p_hr_yr" => ("Fixed_OM_Cost_p_MW_yr", 1/HHV_H2),
        r"Fixed_OM_Cost_Charge_p_tonne_p_hr_yr" => ("Fixed_OM_Cost_Charge_p_MW_yr", 1/HHV_H2),
        r"Fixed_OM_Cost_Energy_p_tonne_yr" => ("Fixed_OM_Cost_Energy_p_MWh_yr", 1/HHV_H2),
        r"Var_OM_Cost_p_tonne" => ("Var_OM_Cost_p_MWh", 1/HHV_H2),
        r"Var_OM_Cost_Charge_p_tonne" => ("Var_OM_Cost_Charge_p_MWh", 1/HHV_H2),
        r"Max_Cap_tonne_p_hr" => ("Max_Cap_MW", HHV_H2),
        r"Min_Cap_tonne_p_hr" => ("Min_Cap_MW", HHV_H2),
        r"Max_Charge_Cap_tonne_p_hr" => ("Max_Charge_Cap_MW", HHV_H2),
        r"Min_Charge_Cap_tonne_p_hr" => ("Min_Charge_Cap_MW", HHV_H2),
        r"Max_Energy_Cap_tonne" => ("Max_Energy_Cap_MWh", HHV_H2),
        r"Min_Energy_Cap_tonne" => ("Min_Energy_Cap_MWh", HHV_H2),
        r"Existing_Cap_tonne_p_hr" => ("Existing_Cap_MW", HHV_H2),
        r"Existing_Charge_Cap_tonne_p_hr" => ("Existing_Charge_Cap_MW", HHV_H2),
        r"Existing_Energy_Cap_tonne" => ("Existing_Energy_Cap_MWh", HHV_H2),
        r"Cap_Size_tonne_p_hr" => ("Cap_Size_MW", HHV_H2),
        r"H2Stor_Charge_MWh_p_tonne" => ("H2Stor_Charge_MWh_p_MWh", 1/HHV_H2),
        r"H2Stor_Charge_MMBtu_p_tonne" => ("H2Stor_Charge_MMBtu_p_MWh", 1/HHV_H2),
        r"Start_Cost_per_tonne_p_hr" => ("Start_Cost_p_MW", 1/HHV_H2)
    )

    hsc_load_changes = Dict(
        r"Cost_of_Demand_Curtailment_per_Tonne" => ("Cost_of_Demand_Curtailment_p_MWh", 1/HHV_H2),
        r"Load_H2_tonne_per_hr_z" => ("Load_H2_MW_z", HHV_H2),
        r"Voll" => ("Voll", 1/HHV_H2),
    )

    hsc_liquid_load_changes = Dict(
        r"Cost_of_Demand_Curtailment_per_Tonne" => ("Cost_of_Demand_Curtailment_p_MWh", 1/HHV_H2),
        r"Load_liqH2_tonne_per_hr_z" => ("Load_liqH2_MW_z", HHV_H2),
        r"Voll" => ("Voll", 1/HHV_H2),
    )

    hsc_pipelines_changes = Dict(
        r"Max_Flow_Tonne_p_Hr_Per_Pipe" => ("Max_Flow_MW_p_pipe", HHV_H2),
        r"H2PipeCap_tonne_per_mile" => ("H2PipeCap_MWh_p_mile", HHV_H2),
        r"BoosterCompCapex_per_tonne_p_hr_yr" => ("BoosterCompCapex_p_MW_yr", 1/HHV_H2),
        r"BoosterCompEnergy_MWh_per_tonne" => ("BoosterCompEnergy_MWh_p_MWh", 1/HHV_H2),
        r"H2PipeCompEnergy" => ("H2PipeCompEnergy", 1/HHV_H2),
    )

    hsc_trucks_changes = Dict(
        r"Existing_Energy_Cap_tonne_z" => ("Existing_Energy_Cap_MW_z", HHV_H2),
        r"TruckCap_tonne_per_unit" => ("TruckCap_MW_per_unit", HHV_H2),
        r"Inv_Cost_Energy_p_tonne_yr" => ("Inv_Cost_Energy_p_MW_yr", 1/HHV_H2),
        r"Fixed_OM_Cost_Energy_p_tonne_yr" => ("Fixed_OM_Cost_Energy_p_MW_yr", 1/HHV_H2),
        r"Max_Energy_Cap_tonne" => ("Max_Energy_Cap_MW", HHV_H2),
        r"Min_Energy_Cap_tonne" => ("Min_Energy_Cap_MW", HHV_H2),
        r"H2_tonne_per_mile" => ("H2_MW_per_mile", 1/HHV_H2),
        r"Inv_Cost_p_unit_p_yr" => ("Inv_Cost_p_unit_p_yr", 1/HHV_H2),
        r"H2TruckCompressionEnergy" => ("H2TruckCompressionEnergy", 1/HHV_H2),
        r"H2TruckUnitOpex_per_mile_full" => ("H2TruckUnitOpex_per_mile_full", 1/HHV_H2),
        r"H2TruckUnitOpex_per_mile_empty" => ("H2TruckUnitOpex_per_mile_empty", 1/HHV_H2),
        r"H2TruckCompressionUnitOpex" => ("H2TruckCompressionUnitOpex", 1/HHV_H2),
        r"H2TruckCompressionEnergy" => ("H2TruckCompressionEnergy", 1/HHV_H2),
    )

    hsc_g2p_changes = Dict(
        r"etaG2P_MWh_p_tonne" => ("etaG2P", 1/HHV_H2),
    )

    hsc_changes = Dict(
        "HSC_trucks.csv" => hsc_trucks_changes,
        "HSC_pipelines.csv" => hsc_pipelines_changes,
        "HSC_load_data.csv" => hsc_load_changes,
        "HSC_load_data_liquid.csv" => hsc_liquid_load_changes,
        "HSC_generation.csv" => hsc_gen_changes,
        "HSC_G2P.csv" => hsc_g2p_changes,
        "HSC_g2p.csv" => hsc_g2p_changes
    )

    for file in hsc_files
        # If the file is not in the changes dictionary, skip it
        if file ∉ keys(hsc_changes)
            continue
        else
            changes_2_make = hsc_changes[file]
        end

        # Load the file as a DataFrame
        df = DataFrame(CSV.File(joinpath(case,file), header=true), copycols=true)
        
        # Go through the column names in changes_2_make
        # Change the column name to the first element of the tuple
        # Multiply the column by the second element of the tuple
        for (old_col, (new_col, factor)) in changes_2_make
            if old_col in names(df)
                df[!, new_col] = df[!, old_col] .* factor
                delete!(df, old_col)
            end
        end

        # Save the DataFrame back to the file
        CSV.write(joinpath(case,file), df)
    end
end