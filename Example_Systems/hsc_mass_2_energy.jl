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
    println("Working on case: $case")
# case = joinpath(@__DIR__,"SmallNewEngland","OneZone")

    case_files = readdir(case)

    # Find all the files in case_files which start with "HSC"
    hsc_files = filter(x -> occursin("HSC", x), case_files)


    hsc_gen_changes = Dict(
        "etaP2G_MWh_p_tonne" => ("etaG2P", 1/HHV_H2),
        "etaFuel_MMBtu_p_tonne" => ("etaFuel_MMBtu_p_MWh", 1/HHV_H2),
        "Inv_Cost_p_tonne_p_hr_y" => ("Inv_Cost_p_MW_y", 1/HHV_H2),
        "Inv_Cost_Charge_p_tonne_p_hr_y" => ("Inv_Cost_Charge_p_MW_y", 1/HHV_H2),
        "Inv_Cost_Energy_p_tonne_y" => ("Inv_Cost_Energy_p_MWh_y", 1/HHV_H2),
        "Fixed_OM_Cost_p_tonne_p_hr_y" => ("Fixed_OM_Cost_p_MW_y", 1/HHV_H2),
        "Fixed_OM_Cost_Charge_p_tonne_p_hr_y" => ("Fixed_OM_Cost_Charge_p_MW_y", 1/HHV_H2),
        "Fixed_OM_Cost_Energy_p_tonne_y" => ("Fixed_OM_Cost_Energy_p_MWh_y", 1/HHV_H2),
        "Var_OM_Cost_p_tonne" => ("Var_OM_Cost_p_MWh", 1/HHV_H2),
        "Var_OM_Cost_Charge_p_tonne" => ("Var_OM_Cost_Charge_p_MWh", 1/HHV_H2),
        "Max_Cap_tonne_p_h" => ("Max_Cap_MW", HHV_H2),
        "Min_Cap_tonne_p_h" => ("Min_Cap_MW", HHV_H2),
        "Max_Charge_Cap_tonne_p_h" => ("Max_Charge_Cap_MW", HHV_H2),
        "Min_Charge_Cap_tonne_p_h" => ("Min_Charge_Cap_MW", HHV_H2),
        "Max_Energy_Cap_tonne" => ("Max_Energy_Cap_MWh", HHV_H2),
        "Min_Energy_Cap_tonne" => ("Min_Energy_Cap_MWh", HHV_H2),
        "Existing_Cap_tonne_p_h" => ("Existing_Cap_MW", HHV_H2),
        "Existing_Charge_Cap_tonne_p_h" => ("Existing_Charge_Cap_MW", HHV_H2),
        "Existing_Energy_Cap_tonne" => ("Existing_Energy_Cap_MWh", HHV_H2),
        "Cap_Size_tonne_p_h" => ("Cap_Size_MW", HHV_H2),
        "H2Stor_Charge_MWh_p_tonne" => ("H2Stor_Charge_MWh_p_MWh", 1/HHV_H2),
        "H2Stor_Charge_MMBtu_p_tonne" => ("H2Stor_Charge_MMBtu_p_MWh", 1/HHV_H2),
        "Start_Cost_per_tonne_p_h" => ("Start_Cost_p_MW", 1/HHV_H2)
    )

    hsc_load_changes = Dict(
        "Cost_of_Demand_Curtailment_per_Tonne" => ("Cost_of_Demand_Curtailment_p_MWh", 1/HHV_H2),
        "Load_H2_tonne_per_hr_z" => ("Load_H2_MW_z", HHV_H2),
        "Voll" => ("Voll", 1/HHV_H2),
    )

    hsc_liquid_load_changes = Dict(
        "Cost_of_Demand_Curtailment_per_Tonne" => ("Cost_of_Demand_Curtailment_p_MWh", 1/HHV_H2),
        "Load_liqH2_tonne_per_hr_z" => ("Load_liqH2_MW_z", HHV_H2),
        "Voll" => ("Voll", 1/HHV_H2),
    )

    hsc_pipelines_changes = Dict(
        "Max_Flow_Tonne_p_Hr_Per_Pipe" => ("Max_Flow_MW_p_pipe", HHV_H2),
        "H2PipeCap_tonne_per_mile" => ("H2PipeCap_MWh_p_mile", HHV_H2),
        "BoosterCompCapex_per_tonne_p_hr_y" => ("BoosterCompCapex_p_MW_y", 1/HHV_H2),
        "BoosterCompEnergy_MWh_per_tonne" => ("BoosterCompEnergy_MWh_p_MWh", 1/HHV_H2),
        "H2PipeCompEnergy" => ("H2PipeCompEnergy", 1/HHV_H2),
    )

    hsc_trucks_changes = Dict(
        "Existing_Energy_Cap_tonne_z" => ("Existing_Energy_Cap_MW_z", HHV_H2),
        "TruckCap_tonne_per_unit" => ("TruckCap_MWh_per_unit", HHV_H2),
        "Inv_Cost_Energy_p_tonne_y" => ("Inv_Cost_Energy_p_MW_y", 1/HHV_H2),
        "Fixed_OM_Cost_Energy_p_tonne_y" => ("Fixed_OM_Cost_Energy_p_MW_y", 1/HHV_H2),
        "Max_Energy_Cap_tonne" => ("Max_Energy_Cap_MW", HHV_H2),
        "Min_Energy_Cap_tonne" => ("Min_Energy_Cap_MW", HHV_H2),
        "H2_tonne_per_mile" => ("H2_MW_per_mile", 1/HHV_H2),
        "Inv_Cost_p_unit_p_y" => ("Inv_Cost_p_unit_p_y", 1/HHV_H2),
        "H2TruckCompressionEnergy" => ("H2TruckCompressionEnergy", 1/HHV_H2),
        "H2TruckUnitOpex_per_mile_full" => ("H2TruckUnitOpex_per_mile_full", 1/HHV_H2),
        "H2TruckUnitOpex_per_mile_empty" => ("H2TruckUnitOpex_per_mile_empty", 1/HHV_H2),
        "H2TruckCompressionUnitOpex" => ("H2TruckCompressionUnitOpex", 1/HHV_H2),
        "H2TruckCompressionEnergy" => ("H2TruckCompressionEnergy", 1/HHV_H2),
    )

    hsc_g2p_changes = Dict(
        "etaG2P_MWh_p_tonne" => ("etaG2P", 1/HHV_H2),
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

        println(" -- Working on file: $file")

        # Load the file as a DataFrame
        df = DataFrame(CSV.File(joinpath(case,file), header=true), copycols=true)
        
        # Go through the column names in changes_2_make
        # If the column name starts with the old_col string,
        # Replace the first part of the column name with the new_col string
        # Multiply the column by the second element of the tuple
        for (old_col, (new_col, factor)) in changes_2_make
            N = length(old_col) + 1
            for col in names(df)
                if startswith(col, old_col)
                    new_name = new_col * col[N:end]
                    println("   -- Changing column: $col to $new_name")
                    df[!,col] = df[!,col] .* factor
                    rename!(df, col => new_name)
                end
            end
        end

        # Save the DataFrame back to the file
        CSV.write(joinpath(case,file), df)
    end
end