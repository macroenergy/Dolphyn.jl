"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
    syn_fuels_truck_all(EP::Model, inputs::Dict, setup::Dict)

This module implements the basic variables and constraints related to hydrogen transmission via trucks.

"""
function syn_fuels_truck_all(EP::Model, inputs::Dict, setup::Dict)

    # Setup variables, constraints, and expressions common to all hydrogen truck resources
    println("Synthesis Fuels Truck Core Resources Module")

    dfSynTruck = inputs["dfSynTruck"]
    SYN_TRUCK_TYPES = inputs["SYN_TRUCK_TYPES"] # Set of h2 truck types

    T = inputs["T"] # Number of time steps (hours)
    Z = inputs["Z"] # Number of zones

    START_SUBPERIODS = inputs["START_SUBPERIODS"] # Starting subperiod index for each representative period
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] # Index of interior subperiod for each representative period

    fuels = inputs["fuels"]
    fuel_costs = inputs["fuel_costs"]
    fuel_CO2 = inputs["fuel_CO2"]

    ### Variables ###

    # Truck flow volume [tonne] through type 'j' at time 't' on zone 'z'
    @variable(EP, vSynTruckFlow[z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T])

    # Number of available full truck type 'j' in transit at time 't' on zone 'z'
    @variable(EP, vSynNavail_full[z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of travel, arrive and deaprt full truck type 'j' in transit at time 't' from zone 'zz' to 'z'
    @variable(EP, vSynNtravel_full[zz = 1:Z, z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vSynNarrive_full[zz = 1:Z, z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vSynNdepart_full[zz = 1:Z, z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T] >= 0)

    # Number of available empty truck type 'j' in transit at time 't' on zone 'z'
    @variable(EP, vSynNavail_empty[z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of travel, arrive and deaprt empty truck type 'j' in transit at time 't' from zone 'zz' to 'z'
    @variable(EP, vSynNtravel_empty[zz = 1:Z, z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vSynNarrive_empty[zz = 1:Z, z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vSynNdepart_empty[zz = 1:Z, z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T] >= 0)

    # Number of charged truck type 'j' at time 't' on zone 'z'
    @variable(EP, vSynNcharged[z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of discharged truck type 'j' at time 't' on zone 'z'
    @variable(EP, vSynNdischarged[z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of full truck type 'j' at time 't'
    @variable(EP, vSynN_full[j in SYN_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of empty truck type 'j' at time 't'
    @variable(EP, vSynN_empty[j in SYN_TRUCK_TYPES, t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Function Expressions ##

    #Operating expenditure for truck type "j" during hour "t" on route "zz" -> "z"
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $

    # Operating expenditure for full and empty trucks
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            OPEX_Truck,
            sum(
                inputs["omega"][t] *
                (vSynNarrive_full[zz, z, j, t] + vSynNarrive_empty[zz, z, j, t]) *
                inputs["fuel_costs"][dfSynTruck[!, :Fuel][j]][t] *
                dfSynTruck[!, :Fuel_MMBTU_per_mile][j] *
                inputs["SynTruckRouteLength"][zz, z] for
                zz = 1:Z, z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T if zz != z
            ) / ModelScalingFactor^2
        )
    else
        @expression(
            EP,
            OPEX_Truck,
            sum(
                inputs["omega"][t] *
                (vSynNarrive_full[zz, z, j, t] + vSynNarrive_empty[zz, z, j, t]) *
                inputs["fuel_costs"][dfSynTruck[!, :Fuel][j]][t] *
                dfSynTruck[!, :Fuel_MMBTU_per_mile][j] *
                inputs["SynTruckRouteLength"][zz, z] for
                zz = 1:Z, z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T if zz != z
            )
        )
    end
    EP[:eObj] += OPEX_Truck

    # Operating expenditure for truck h2 compression
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            OPEX_Truck_Compression,
            sum(
                inputs["omega"][t] *
                (vSynTruckFlow[z, j, t] * dfSynTruck[!, :SynTruckCompressionUnitOpex][j]) for
                z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T
            )
        ) / ModelScalingFactor^2
    else
        @expression(
            EP,
            OPEX_Truck_Compression,
            sum(
                inputs["omega"][t] *
                (vSynTruckFlow[z, j, t] * dfSynTruck[!, :SynTruckCompressionUnitOpex][j]) for
                z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T
            )
        )
    end
    EP[:eObj] += OPEX_Truck_Compression
    ## End Objective Function Expressions ##

    ## Balance Expressions ##
    # Syn Power Compression Consumption balance
    @expression(
        EP,
        ePowerbalanceSynTruckCompression[t = 1:T, z = 1:Z],
        if setup["ParameterScale"] == 1 # If ParameterScale = 1, power system operation/capacity modeled in GWh rather than MWh
            sum(
                vSynNcharged[z, j, t] *
                dfSynTruck[!, :TruckCap_tonne_per_unit][j] *
                dfSynTruck[!, :SynTruckCompressionEnergy][j] for j in SYN_TRUCK_TYPES
            ) / ModelScalingFactor
        else
            sum(
                vSynNcharged[z, j, t] *
                dfSynTruck[!, :TruckCap_tonne_per_unit][j] *
                dfSynTruck[!, :SynTruckCompressionEnergy][j] for j in SYN_TRUCK_TYPES
            )
        end
    )

    EP[:ePowerBalance] += -ePowerbalanceSynTruckCompression

    # Syn Power Truck Travelling Consumption balance
    @expression(
        EP,
        ePowerbalanceSynTruckTravel[t = 1:T, z = 1:Z],
        if setup["ParameterScale"] == 1
            sum(
                (vSynNarrive_full[zz, z, j, t] + vSynNarrive_empty[zz, z, j, t]) *
                dfSynTruck[!, :Power_MW_per_mile][j] *
                inputs["SynTruckRouteLength"][zz, z] for
                zz = 1:Z, j in SYN_TRUCK_TYPES if zz != z
            ) / ModelScalingFactor
        else
            sum(
                (vSynNarrive_full[zz, z, j, t] + vSynNarrive_empty[zz, z, j, t]) *
                dfSynTruck[!, :Power_MW_per_mile][j] *
                inputs["SynTruckRouteLength"][zz, z] for
                zz = 1:Z, j in SYN_TRUCK_TYPES if zz != z
            )
        end
    )

    EP[:ePowerBalance] += -ePowerbalanceSynTruckTravel

    # Syn balance
    @expression(
        EP,
        eSynTruckFlow[t = 1:T, z = 1:Z],
        sum(vSynTruckFlow[z, j, t] for j in SYN_TRUCK_TYPES)
    )
    EP[:eSynBalance] += eSynTruckFlow

    # Syn Truck Traveling Consumption balance
    @expression(
        EP,
        eSynTruckTravelConsumption[t = 1:T, z = 1:Z],
        sum(
            (vSynNarrive_full[zz, z, j, t] + vSynNarrive_empty[zz, z, j, t]) *
            dfSynTruck[!, :Syn_tonne_per_mile][j] *
            inputs["SynTruckRouteLength"][zz, z] for
            zz = 1:Z, j in SYN_TRUCK_TYPES if zz != z
        )
    )

    EP[:eSynBalance] += -eSynTruckTravelConsumption
    # Syn truck emission penalty
    @expression(
        EP,
        Syn_Truck_carbon_emission,
        sum(
            inputs["omega"][t] *
            (vSynNarrive_full[zz, z, j, t] + vSynNarrive_empty[zz, z, j, t]) *
            inputs["fuel_CO2"][dfSynTruck[!, :Fuel][j]] *
            dfSynTruck[!, :Fuel_MMBTU_per_mile][j] *
            inputs["SynTruckRouteLength"][zz, z] for
            zz = 1:Z, z = 1:Z, j in SYN_TRUCK_TYPES, t = 1:T if zz != z
        )
    )
    # EP[:eCarbonBalance] += Syn_Truck_carbon_emission
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###

    ## Total number
    @constraint(
        EP,
        cSynTruckTotalNumber[j in SYN_TRUCK_TYPES, t in 1:T],
        vSynN_full[j, t] + vSynN_empty[j, t] == EP[:eTotalSynTruckNumber][j]
    )

    # No truck in transit should have the same start and end
    @constraints(
        EP,
        begin
            cSynTruckSameZoneTravelFull[zz in 1:Z, z = zz, j in SYN_TRUCK_TYPES, t in 1:T],
            vSynNtravel_full[zz, z, j, t] == 0
            cSynTruckSameZoneTravelEmpty[zz in 1:Z, z = zz, j in SYN_TRUCK_TYPES, t in 1:T],
            vSynNtravel_empty[zz, z, j, t] == 0
            cSynTruckSameZoneArriveFull[zz in 1:Z, z = zz, j in SYN_TRUCK_TYPES, t in 1:T],
            vSynNarrive_full[zz, z, j, t] == 0
            cSynTruckSameZoneArriveEmpty[zz in 1:Z, z = zz, j in SYN_TRUCK_TYPES, t in 1:T],
            vSynNarrive_empty[zz, z, j, t] == 0
            cSynTruckSameZoneDepartFull[zz in 1:Z, z = zz, j in SYN_TRUCK_TYPES, t in 1:T],
            vSynNdepart_full[zz, z, j, t] == 0
            cSynTruckSameZoneDepartEmpty[zz in 1:Z, z = zz, j in SYN_TRUCK_TYPES, t in 1:T],
            vSynNdepart_empty[zz, z, j, t] == 0
        end
    )

    # The number of total full and empty trucks
    @constraints(
        EP,
        begin
            cSynTruckTotalFull[j in SYN_TRUCK_TYPES, t in 1:T],
            vSynN_full[j, t] ==
            sum(vSynNtravel_full[zz, z, j, t] for zz = 1:Z, z = 1:Z if zz != z) +
            sum(vSynNavail_full[z, j, t] for z = 1:Z)

            cSynTruckTotalEmpty[j in SYN_TRUCK_TYPES, t in 1:T],
            vSynN_empty[j, t] ==
            sum(vSynNtravel_empty[zz, z, j, t] for zz = 1:Z, z = 1:Z if zz != z) +
            sum(vSynNavail_empty[z, j, t] for z = 1:Z)
        end
    )

    t_arrive = 1
    t_depart = 1

    # Change of the number of full available trucks
    @constraints(
        EP,
        begin
            cSynTruckChangeFullAvailInterior[
                z in 1:Z,
                j in SYN_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vSynNavail_full[z, j, t] - vSynNavail_full[z, j, t-1] ==
            vSynNcharged[z, j, t] - vSynNdischarged[z, j, t] +
            sum(vSynNarrive_full[zz, z, j, t-t_arrive] for zz = 1:Z if zz != z) -
            sum(vSynNdepart_full[z, zz, j, t-t_depart] for zz = 1:Z if zz != z) + 0
            cSynTruckChangeFullAvailStart[
                z in 1:Z,
                j in SYN_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vSynNavail_full[z, j, t] -
            vSynNavail_full[z, j, t+inputs["hours_per_subperiod"]-1] ==
            vSynNcharged[z, j, t] - vSynNdischarged[z, j, t] + sum(
                vSynNarrive_full[zz, z, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            ) - sum(
                vSynNdepart_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            )
        end
    )

    # Change of the number of empty available trucks
    @constraints(
        EP,
        begin
            cSynTruckChangeEmptyAvailInterior[
                z in 1:Z,
                j in SYN_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vSynNavail_empty[z, j, t] - vSynNavail_empty[z, j, t-1] ==
            -vSynNcharged[z, j, t] +
            vSynNdischarged[z, j, t] +
            sum(vSynNarrive_empty[zz, z, j, t-t_arrive] for zz = 1:Z if zz != z) -
            sum(vSynNdepart_empty[z, zz, j, t-t_depart] for zz = 1:Z if zz != z)
            cSynTruckChangeEmptyAvailStart[
                z in 1:Z,
                j in SYN_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vSynNavail_empty[z, j, t] -
            vSynNavail_empty[z, j, t+inputs["hours_per_subperiod"]-1] ==
            -vSynNcharged[z, j, t] +
            vSynNdischarged[z, j, t] +
            sum(
                vSynNarrive_empty[zz, z, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            ) - sum(
                vSynNdepart_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            )
        end
    )

    # Change of the number of full traveling trucks
    @constraints(
        EP,
        begin
            cSynTruckChangeFullTravelInterior[
                z in 1:Z,
                zz in 1:Z,
                j in SYN_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vSynNtravel_full[z, zz, j, t] - vSynNtravel_full[z, zz, j, t-1] ==
            vSynNdepart_full[z, zz, j, t-t_depart] - vSynNarrive_full[z, zz, j, t-t_arrive]
            cSynTruckChangeFullTravelStart[
                z in 1:Z,
                zz in 1:Z,
                j in SYN_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vSynNtravel_full[z, zz, j, t] -
            vSynNtravel_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] ==
            vSynNdepart_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] -
            vSynNarrive_full[z, zz, j, t+inputs["hours_per_subperiod"]-1]
        end
    )

    # Change of the number of empty traveling trucks
    @constraints(
        EP,
        begin
            cSynTruckChangeEmptyTravelInterior[
                z in 1:Z,
                zz in 1:Z,
                j in SYN_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vSynNtravel_empty[z, zz, j, t] - vSynNtravel_empty[z, zz, j, t-1] ==
            vSynNdepart_empty[z, zz, j, t-t_depart] - vSynNarrive_empty[z, zz, j, t-t_arrive]
            cSynTruckChangeEmptyTravelStart[
                z in 1:Z,
                zz in 1:Z,
                j in SYN_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vSynNtravel_empty[z, zz, j, t] -
            vSynNtravel_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] ==
            vSynNdepart_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] -
            vSynNarrive_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1]
        end
    )

    # Travel delay
    @constraints(
        EP,
        begin
            [zz in 1:Z, z in 1:Z, j in SYN_TRUCK_TYPES, t in 1:T],
            vSynNtravel_full[zz, z, j, t] >= sum(
                vSynNarrive_full[zz, z, j, tt] for
                tt = (t+1):(t+inputs["TD"][j][zz, z]) if t + inputs["TD"][j][zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][zz, z] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][zz, z]
            )
            [zz in 1:Z, z in 1:Z, j in SYN_TRUCK_TYPES, t in 1:T],
            vSynNtravel_empty[zz, z, j, t] >= sum(
                vSynNdepart_empty[zz, z, j, tt] for
                tt = (t-inputs["TD"][j][zz, z]+1):t if t + inputs["TD"][j][zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][zz, z] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][zz, z]
            )
        end
    )

    @constraints(
        EP,
        begin
            [zz in 1:Z, z in 1:Z, j in SYN_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vSynNtravel_full[zz, z, j, t] >= sum(
                vSynNarrive_full[zz, z, j, tt] for
                tt = (t+1):(t+inputs["TD"][j][zz, z]) if t + inputs["TD"][j][zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][zz, z] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][zz, z]
            )
            [zz in 1:Z, z in 1:Z, j in SYN_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vSynNtravel_empty[zz, z, j, t] >= sum(
                vSynNarrive_empty[zz, z, j, tt] for
                tt = (t+1):(t+inputs["TD"][j][zz, z]) if t + inputs["TD"][j][zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][zz, z] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][zz, z]
            )
        end
    )

    # Capacity constraints
    @constraint(
        EP,
        [z in 1:Z, j in SYN_TRUCK_TYPES, t in 1:T],
        vSynNcharged[z, j, t] * dfSynTruck[!, :TruckCap_tonne_per_unit][j] <=
        EP[:eTotalSynTruckEnergy][z, j]
    )

    # Syn truck flow balance
    @constraint(
        EP,
        cSynTruckFlow[z in 1:Z, j in SYN_TRUCK_TYPES, t in 1:T],
        vSynTruckFlow[z, j, t] ==
        vSynNdischarged[z, j, t] *
        dfSynTruck[!, :TruckCap_tonne_per_unit][j] *
        (1 - dfSynTruck[!, :SynTLoss_per_mile][j]) -
        vSynNcharged[z, j, t] * dfSynTruck[!, :TruckCap_tonne_per_unit][j]
    )

    ### End Constraints ###

    return EP
end

# # Truck travel delay - reserved for backup
# if t + inputs["TD"][j][zz, z] >=
#    (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
#    t + inputs["TD"][j][zz, z] <= t + inputs["hours_per_subperiod"] - 1 &&
#    t + 1 <= t + inputs["TD"][j][zz, z]
#     nothing
# end
