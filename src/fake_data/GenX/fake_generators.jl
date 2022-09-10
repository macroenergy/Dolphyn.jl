"""
LTESOM: Spatial-Temporal model complexity analysis based on GenX model in power system.
Copyright (C) 2022, College of Engineering, Peking University, Department of Industry and Engineering
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
    fake_generators(path::AbstractString, zones::Integer, generators::Dict{String, Int64})

This function fakes imaginary power generators (thermal, renewable, storage, etc.) from nowhere.
"""
function fake_generators(path::AbstractString, zones::Integer, generators::Dict{String, Int64})

    # Generate zone list
    Zones = 1:zones

    # Candidate generator list
    THERM_set = ["Nuclear", "CCGT", "CCGT_CCS", "OCGT_F"]
    VRE_set = ["PV", "Wind"]
    CCS_set = ["CCGT_CCS"]
    STO_set = ["Storage_bat"]
    candidates = union(THERM_set, VRE_set, CCS_set, STO_set)

    # Construct resources list
    resources = 0
    therm_number = 0
    VRE_number = 0
    ccs_number = 0
    storage_number = 0
    for (key, value) in generators
        if key in candidates
            resources += value
        end
        if key in THERM_set
            therm_number += generators[key]
        end
        if key in VRE_set
            VRE_number += generators[key]
        end
        if key in CCS_set
            ccs_number += generators[key]
        end
        if key in STO_set
            storage_number += generators[key]
        end
    end

    # Compute the number of all resources
    resources_number = zones*resources

    # Construct resources dataframe
    df_resources = DataFrame(
        Resource = replace.(collect("$key-$i-$z" for (key, value) in generators for i in 1:value for z in Zones), "-"=>"_"),
        Resource_Type = replace.(collect("$key" for (key, value) in generators for i in 1:value for z in Zones), "-"=>"_"),
        Zone = repeat(Zones, resources),
    )

    # Initialize generators' parameters dataframe
    df_parameters = DataFrame(
        THERM = zeros(resources_number),
        STOR = zeros(resources_number),
        VRE = zeros(resources_number),
        LDS = zeros(resources_number),
        CCS = zeros(resources_number),
        Num_VRE_Bins = zeros(resources_number),
        New_Build = ones(resources_number),
        Existing_Cap_MW = zeros(resources_number),
        Existing_Cap_MWh = zeros(resources_number),
        Existing_Charge_Cap_MW = zeros(resources_number),
        Max_Cap_MW = repeat([-1], resources_number),
        Max_Cap_MWh = repeat([-1], resources_number),
        Max_Charge_Cap_MW = repeat([-1], resources_number),
        Min_Cap_MW = zeros(resources_number),
        Min_Cap_MWh = zeros(resources_number),
        Min_Charge_Cap_MW = zeros(resources_number),
        Inv_Cost_per_MWyr = rand(resources_number) .* 100000,
        Inv_Cost_per_MWhyr = zeros(resources_number),
        Inv_Cost_Charge_per_MWyr = zeros(resources_number),
        Fixed_OM_Cost_per_MWyr = rand(resources_number) .* 8000,
        Fixed_OM_Cost_per_MWhyr = zeros(resources_number),
        Fixed_OM_Cost_Charge_per_MWyr = zeros(resources_number),
        Var_OM_Cost_per_MWh = zeros(resources_number),
        Heat_Rate_MMBTU_per_MWh = zeros(resources_number),
        Fuel = repeat(["None"], resources_number),
        CCS_Percentage = zeros(resources_number),
        Cap_Size = ones(resources_number),
        Start_Cost_per_MW = zeros(resources_number),
        Start_Fuel_MMBTU_per_MW = zeros(resources_number),
        Up_Time = zeros(resources_number),
        Down_Time = zeros(resources_number),
        Ramp_Up_Percentage = ones(resources_number),
        Ramp_Dn_Percentage = ones(resources_number),
        Min_Power = zeros(resources_number),
        Self_Disch = zeros(resources_number),
        Eff_Up = zeros(resources_number),
        Eff_Down = zeros(resources_number),
        Min_Duration = zeros(resources_number),
        Max_Duration = zeros(resources_number)
    )

    # Merge parameters dataframe into resources dataframe
    df_resources = hcat(df_resources, df_parameters)

    # Justify parameters according to resources type
    # Thermal resources
    df_resources[in(THERM_set).(df_resources.Resource_Type), :THERM] .= 1
    df_resources[in(CCS_set).(df_resources.Resource_Type), :CCS] .= 1
    df_resources[in(THERM_set).(df_resources.Resource_Type), :Var_OM_Cost_per_MWh] .= round.(reduce(vcat, repeat([rand()] .* 10, zones) for _ in 1:therm_number))
    df_resources[in(THERM_set).(df_resources.Resource_Type), :Heat_Rate_MMBTU_per_MWh] .= round.(reduce(vcat, repeat([rand()] .* 10, zones) for _ in 1:therm_number))
    df_resources[in(["Nuclear"]).(df_resources.Resource_Type), :Fuel] .= "uranium"
    df_resources[in(["CCGT", "OCGT_F"]).(df_resources.Resource_Type), :Fuel] .= "natural_gas"
    df_resources[in(["CCGT_CCS"]).(df_resources.Resource_Type), :Fuel] .= "natural_gas_ccs"
    df_resources[in(CCS_set).(df_resources.Resource_Type), :CCS_Percentage] .= round.(reduce(vcat, repeat([rand()], zones) for _ in 1:ccs_number); digits=1)
    df_resources[in(THERM_set).(df_resources.Resource_Type), :Cap_Size] .= round.(reduce(vcat, repeat([rand() .* 1000], zones) for _ in 1:therm_number))
    df_resources[in(THERM_set).(df_resources.Resource_Type), :Start_Cost_per_MW] .= round.(reduce(vcat, repeat([rand() .* 250], zones) for _ in 1:therm_number))
    df_resources[in(THERM_set).(df_resources.Resource_Type), :Start_Fuel_MMBTU_per_MW] .= reduce(vcat, repeat([rand() .* 10], zones) for _ in 1:therm_number)
    df_resources[in(THERM_set).(df_resources.Resource_Type), :Up_Time] .= round.(reduce(vcat, repeat([rand() .* 24], zones) for _ in 1:therm_number))
    df_resources[in(THERM_set).(df_resources.Resource_Type), :Down_Time] .= df_resources[in(THERM_set).(df_resources.Resource_Type), :Up_Time]
    df_resources[in(THERM_set).(df_resources.Resource_Type), :Ramp_Up_Percentage] .= reduce(vcat, repeat([rand()], zones) for _ in 1:therm_number)
    df_resources[in(THERM_set).(df_resources.Resource_Type), :Ramp_Dn_Percentage] .= df_resources[in(THERM_set).(df_resources.Resource_Type), :Ramp_Up_Percentage]
    df_resources[in(THERM_set).(df_resources.Resource_Type), :Min_Power] .= reduce(vcat, repeat([rand()], zones) for _ in 1:therm_number)

    # VRE resources
    df_resources[in(VRE_set).(df_resources.Resource_Type), :VRE] .= 1
    df_resources[in(VRE_set).(df_resources.Resource_Type), :Num_VRE_Bins] .= 1

    # CCS resources
    df_resources[in(CCS_set).(df_resources.Resource_Type), :CCS] .= 1
    df_resources[in(CCS_set).(df_resources.Resource_Type), :CCS_Percentage] .= reduce(vcat, repeat([rand()], zones) for _ in 1:ccs_number)

    # Storage resources
    df_resources[in(STO_set).(df_resources.Resource_Type), :STOR] .= 2
    df_resources[in(STO_set).(df_resources.Resource_Type), :Inv_Cost_per_MWhyr] .= round.(reduce(vcat, repeat([rand() .* 12000], zones) for _ in 1:storage_number))
    df_resources[in(STO_set).(df_resources.Resource_Type), :Fixed_OM_Cost_per_MWhyr] .= round.(reduce(vcat, repeat([rand() .* 2500], zones) for _ in 1:storage_number))
    df_resources[in(STO_set).(df_resources.Resource_Type), :Self_Disch] .= round.(reduce(vcat, repeat([rand() ./ 1000], zones) for _ in 1:storage_number))
    df_resources[in(STO_set).(df_resources.Resource_Type), :Eff_Up] .= round.(reduce(vcat, repeat([rand()], zones) for _ in 1:storage_number); digits=1)
    df_resources[in(STO_set).(df_resources.Resource_Type), :Eff_Down] .= round.(reduce(vcat, repeat([rand()], zones) for _ in 1:storage_number); digits=1)
    df_resources[in(STO_set).(df_resources.Resource_Type), :Min_Duration] .= round.(reduce(vcat, repeat([rand()], zones) for _ in 1:storage_number); digits=1)
    df_resources[in(STO_set).(df_resources.Resource_Type), :Max_Duration] .= round.(reduce(vcat, repeat([rand() .* 400], zones) for _ in 1:storage_number))

    CSV.write(joinpath(path, "Generators.csv"), df_resources)

    return df_resources

end

fake_generators(pwd(), 3, Dict("CCGT"=>2, "OCGT_F"=>1, "PV"=>1, "Wind"=>2, "Nuclear"=>1, "CCGT_CCS"=>2, "Storage_bat"=>2))
