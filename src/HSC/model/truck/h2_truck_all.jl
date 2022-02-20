"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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

function h2_truck_all(EP::Model, inputs::Dict, setup::Dict)

    # Setup variables, constraints, and expressions common to all hydrogen truck resources
    println("Hydrogen Truck Core Resources Module")

    dfH2Truck = inputs["dfH2Truck"]
    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"] # Set of h2 truck types

    T = inputs["T"] # Number of time steps (hours)
    Z = inputs["Z"] # Number of zones

    START_SUBPERIODS = inputs["START_SUBPERIODS"] # Starting subperiod index for each representative period
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] # Index of interior subperiod for each representative period

    TD = round.(Int, inputs["RouteLength"] ./ dfH2Truck[!, :AvgTruckSpeed_mile_per_hour][1])
    ### Variables ###

    # Truck flow volume [tonne] through type 'j' at time 't' on zone 'z'
    @variable(EP, vH2TruckFlow[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T])

    # Number of available full truck type 'j' in transit at time 't' on zone 'z'
    @variable(EP, vH2Navail_full[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of travel, arrive and depart full truck type 'j' in transit at time 't' from zone 'zz' to 'z'
    @variable(EP, vH2Ntravel_full[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vH2Narrive_full[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vH2Ndepart_full[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)

    # Number of available empty truck type 'j' in transit at time 't' on zone 'z'
    @variable(EP, vH2Navail_empty[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of travel, arrive and depart empty truck type 'j' in transit at time 't' from zone 'zz' to 'z'
    @variable(EP, vH2Ntravel_empty[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vH2Narrive_empty[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vH2Ndepart_empty[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)

    # Number of charged truck type 'j' at time 't' on zone 'z'
    @variable(EP, vH2Ncharged[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of discharged truck type 'j' at time 't' on zone 'z'
    @variable(EP, vH2Ndischarged[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of full truck type 'j' at time 't'
    @variable(EP, vH2N_full[j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of empty truck type 'j' at time 't'
    @variable(EP, vH2N_empty[j in H2_TRUCK_TYPES, t = 1:T] >= 0)

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
                (
                    vH2Narrive_full[zz, z, j, t] *
                    dfH2Truck[!, :H2TruckUnitOpex_per_mile_full][j] +
                    vH2Narrive_empty[zz, z, j, t] *
                    dfH2Truck[!, :H2TruckUnitOpex_per_mile_empty][j]
                ) *
                inputs["RouteLength"][zz, z] for
                zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T if zz != z
            ) / ModelScalingFactor^2
        )
    else
        @expression(
            EP,
            OPEX_Truck,
            sum(
                inputs["omega"][t] *
                (
                    vH2Narrive_full[zz, z, j, t] *
                    dfH2Truck[!, :H2TruckUnitOpex_per_mile_full][j] +
                    vH2Narrive_empty[zz, z, j, t] *
                    dfH2Truck[!, :H2TruckUnitOpex_per_mile_empty][j]
                ) *
                inputs["RouteLength"][zz, z] for
                zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T if zz != z
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
                (vH2TruckFlow[z, j, t] * dfH2Truck[!, :H2TruckCompressionUnitOpex][j]) for
                z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T
            )
        ) / ModelScalingFactor^2
    else
        @expression(
            EP,
            OPEX_Truck_Compression,
            sum(
                inputs["omega"][t] *
                (vH2TruckFlow[z, j, t] * dfH2Truck[!, :H2TruckCompressionUnitOpex][j]) for
                z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T
            )
        )
    end
    EP[:eObj] += OPEX_Truck_Compression
    ## End Objective Function Expressions ##

    ## Balance Expressions ##
    # H2 Power Consumption balance
    @expression(
        EP,
        eH2TruckCompressionPowerConsumption[t = 1:T, z = 1:Z],
        if setup["ParameterScale"] == 1 # If ParameterScale = 1, power system operation/capacity modeled in GW rather than MW
            sum(
                vH2Ncharged[z, j, t] *
                dfH2Truck[!, :TruckCap_tonne_per_unit][j] *
                dfH2Truck[!, :H2TruckCompressionEnergy][j] for j in H2_TRUCK_TYPES
            ) / ModelScalingFactor
        else
            sum(
                vH2Ncharged[z, j, t] *
                dfH2Truck[!, :TruckCap_tonne_per_unit][j] *
                dfH2Truck[!, :H2TruckCompressionEnergy][j] for j in H2_TRUCK_TYPES
            )
        end
    )
    EP[:ePowerBalance] += eH2TruckCompressionPowerConsumption

    # H2 balance
    @expression(
        EP,
        TruckFlow[t = 1:T, z = 1:Z],
        sum(vH2TruckFlow[z, j, t] for j in H2_TRUCK_TYPES)
    )
    EP[:eH2Balance] += TruckFlow

    # Dev note: carbon emission balance is under construction
    # Carbon emission balance
    # @expression(
    #     EP,
    #     Truck_carbon_emission,
    #     sum(
    #         inputs["omega"][t] *
    #         (
    #             vH2Narrive_full[zz, z, j, t] *
    #             dfH2Truck[!, :Full_weight_tonne_per_unit][j] +
    #             vH2Narrive_empty[zz, z, j, t] * dfH2Truck[!, :Empty_weight_tonne_per_unit][j]
    #         ) *
    #         inputs["RouteLength"][zz, z] *
    #         dfH2Truck[!, :truck_emission_rate_tonne_per_tonne_mile][j] for
    #         zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T if zz != z
    #     )
    # )
    # EP[:eCarbonBalance] += Truck_carbon_emission
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###

    ## Total number
    @constraint(
        EP,
        [j in H2_TRUCK_TYPES, t in 1:T],
        vH2N_full[j, t] + vH2N_empty[j, t] == EP[:eTotalH2CapTruckNumber][j]
    )

    # No truck in transit should have the same start and end 
    @constraints(
        EP,
        begin
            [zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ntravel_full[zz, z, j, t] == 0
            [zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ntravel_empty[zz, z, j, t] == 0
            [zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Narrive_full[zz, z, j, t] == 0
            [zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ndepart_full[zz, z, j, t] == 0
            [zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Narrive_empty[zz, z, j, t] == 0
            [zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ndepart_empty[zz, z, j, t] == 0
        end
    )

    # The number of total full and empty trucks
    @constraints(
        EP,
        begin
            [j in H2_TRUCK_TYPES, t in 1:T],
            vH2N_full[j, t] ==
            sum(vH2Ntravel_full[zz, z, j, t] for zz = 1:Z, z = 1:Z if zz != z) +
            sum(vH2Navail_full[z, j, t] for z = 1:Z)
            [j in H2_TRUCK_TYPES, t in 1:T],
            vH2N_empty[j, t] ==
            sum(vH2Ntravel_empty[zz, z, j, t] for zz = 1:Z, z = 1:Z if zz != z) +
            sum(vH2Navail_empty[z, j, t] for z = 1:Z)
        end
    )

    t_arrive = 1
    t_depart = 1

    # Change of the number of full available trucks
    @constraints(
        EP,
        begin
            [z in 1:Z, j in H2_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vH2Navail_full[z, j, t] - vH2Navail_full[z, j, t-1] ==
            vH2Ncharged[z, j, t] - vH2Ndischarged[z, j, t] +
            sum(vH2Narrive_full[zz, z, j, t-t_arrive] for zz = 1:Z if zz != z) -
            sum(vH2Ndepart_full[z, zz, j, t-t_depart] for zz = 1:Z if zz != z) + 0
            [z in 1:Z, j in H2_TRUCK_TYPES, t in START_SUBPERIODS],
            vH2Navail_full[z, j, t] -
            vH2Navail_full[z, j, t+inputs["hours_per_subperiod"]-1] ==
            vH2Ncharged[z, j, t] - vH2Ndischarged[z, j, t] + sum(
                vH2Narrive_full[zz, z, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            ) - sum(
                vH2Ndepart_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            )
        end
    )

    # Change of the number of empty available trucks
    @constraints(
        EP,
        begin
            [z in 1:Z, j in H2_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vH2Navail_empty[z, j, t] - vH2Navail_empty[z, j, t-1] ==
            -vH2Ncharged[z, j, t] +
            vH2Ndischarged[z, j, t] +
            sum(vH2Narrive_empty[zz, z, j, t-t_arrive] for zz = 1:Z if zz != z) -
            sum(vH2Ndepart_empty[z, zz, j, t-t_depart] for zz = 1:Z if zz != z) + 0
            [z in 1:Z, j in H2_TRUCK_TYPES, t in START_SUBPERIODS],
            vH2Navail_empty[z, j, t] -
            vH2Navail_empty[z, j, t+inputs["hours_per_subperiod"]-1] ==
            -vH2Ncharged[z, j, t] +
            vH2Ndischarged[z, j, t] +
            sum(
                vH2Narrive_empty[zz, z, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            ) - sum(
                vH2Ndepart_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            )
        end
    )

    # Change of the number of full traveling trucks
    @constraints(
        EP,
        begin
            [z in 1:Z, zz in 1:Z, j in H2_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vH2Ntravel_full[z, zz, j, t] - vH2Ntravel_full[z, zz, j, t-1] ==
            vH2Ndepart_full[z, zz, j, t-t_depart] - vH2Narrive_full[z, zz, j, t-t_arrive]
            [z in 1:Z, zz in 1:Z, j in H2_TRUCK_TYPES, t in START_SUBPERIODS],
            vH2Ntravel_full[z, zz, j, t] -
            vH2Ntravel_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] ==
            vH2Ndepart_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] -
            vH2Narrive_full[z, zz, j, t+inputs["hours_per_subperiod"]-1]
        end
    )

    # Change of the number of empty traveling trucks
    @constraints(
        EP,
        begin
            [z in 1:Z, zz in 1:Z, j in H2_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vH2Ntravel_empty[z, zz, j, t] - vH2Ntravel_empty[z, zz, j, t-1] ==
            vH2Ndepart_empty[z, zz, j, t-t_depart] - vH2Narrive_empty[z, zz, j, t-t_arrive]
            [z in 1:Z, zz in 1:Z, j in H2_TRUCK_TYPES, t in START_SUBPERIODS],
            vH2Ntravel_empty[z, zz, j, t] -
            vH2Ntravel_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] ==
            vH2Ndepart_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] -
            vH2Narrive_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1]
        end
    )

    # Travel delay
    @constraints(
        EP,
        begin
            [zz in 1:Z, z in 1:Z, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ntravel_full[zz, z, j, t] >= sum(
                vH2Narrive_full[zz, z, j, tt] for
                tt = (t+1):(t+TD[zz, z]) if t + TD[zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + TD[zz, z] <= (t % inputs["hours_per_subperiod"]) * (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + TD[zz, z]
            )
            [zz in 1:Z, z in 1:Z, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ntravel_empty[zz, z, j, t] >= sum(
                vH2Ndepart_empty[zz, z, j, tt] for
                tt = (t-TD[zz, z]+1):t if t + TD[zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + TD[zz, z] <= (t % inputs["hours_per_subperiod"]) * (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + TD[zz, z]
            )
        end
    )

    @constraints(
        EP,
        begin
            [zz in 1:Z, z in 1:Z, j in H2_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vH2Ntravel_full[zz, z, j, t] >= sum(
                vH2Narrive_full[zz, z, j, tt] for
                tt = (t+1):(t+TD[zz, z]) if t + TD[zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + TD[zz, z] <= (t % inputs["hours_per_subperiod"]) * (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + TD[zz, z]
            )
            [zz in 1:Z, z in 1:Z, j in H2_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vH2Ntravel_empty[zz, z, j, t] >= sum(
                vH2Narrive_empty[zz, z, j, tt] for
                tt = (t+1):(t+TD[zz, z]) if t + TD[zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + TD[zz, z] <= (t % inputs["hours_per_subperiod"]) * (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + TD[zz, z]
            )
        end
    )

    # Capacity constraints
    @constraint(
        EP,
        [z in 1:Z, j in H2_TRUCK_TYPES, t in 1:T],
        vH2Ncharged[z, j, t] * dfH2Truck[!, :TruckCap_tonne_per_unit][j] <=
        EP[:eTotalH2CapTruckEnergy][z, j]
    )

    # H2 truck flow balance
    @constraint(
        EP,
        [z in 1:Z, j in H2_TRUCK_TYPES, t in 1:T],
        vH2TruckFlow[z, j, t] ==
        vH2Ndischarged[z, j, t] *
        dfH2Truck[!, :TruckCap_tonne_per_unit][j] *
        (1 - dfH2Truck[!, :H2TLoss_per_mile][j]) -
        vH2Ncharged[z, j, t] * dfH2Truck[!, :TruckCap_tonne_per_unit][j]
    )

    ### End Constraints ###

    return EP
end

# # Truck travel delay - reserved for backup
# if t + TD[zz, z] >=
#    (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
#    t + TD[zz, z] <= t + inputs["hours_per_subperiod"] - 1 &&
#    t + 1 <= t + TD[zz, z]
#     nothing
# end