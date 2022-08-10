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
    co2_truck_all(EP::Model, inputs::Dict, setup::Dict)

This module implements the basic variables and constraints related to carbon transmission via trucks.
"""
function co2_truck_all(EP::Model, inputs::Dict, setup::Dict)

    # Setup variables, constraints, and expressions common to all carbon truck resources
    println("CO2 Truck Core Resources Module")

    dfCO2Truck = inputs["dfCO2Truck"]
    CO2_TRUCK_TYPES = inputs["CO2_TRUCK_TYPES"] # Set of h2 truck types

    T = inputs["T"] # Number of time steps (hours)
    Z = inputs["Z"] # Number of zones

    START_SUBPERIODS = inputs["START_SUBPERIODS"] # Starting subperiod index for each representative period
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] # Index of interior subperiod for each representative period

    fuels = inputs["fuels"]
    fuel_costs = inputs["fuel_costs"]
    fuel_CO2 = inputs["fuel_CO2"]

    ### Variables ###

    # Truck flow volume [tonne] through type 'j' at time 't' on zone 'z'
    @variable(EP, vCO2TruckFlow[z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T])

    # Number of available full truck type 'j' in transit at time 't' on zone 'z'
    @variable(EP, vCO2Navail_full[z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of travel, arrive and deaprt full truck type 'j' in transit at time 't' from zone 'zz' to 'z'
    @variable(EP, vCO2Ntravel_full[zz = 1:Z, z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vCO2Narrive_full[zz = 1:Z, z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vCO2Ndepart_full[zz = 1:Z, z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T] >= 0)

    # Number of available empty truck type 'j' in transit at time 't' on zone 'z'
    @variable(EP, vCO2Navail_empty[z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of travel, arrive and deaprt empty truck type 'j' in transit at time 't' from zone 'zz' to 'z'
    @variable(EP, vCO2Ntravel_empty[zz = 1:Z, z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vCO2Narrive_empty[zz = 1:Z, z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vCO2Ndepart_empty[zz = 1:Z, z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T] >= 0)

    # Number of charged truck type 'j' at time 't' on zone 'z'
    @variable(EP, vCO2Ncharged[z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of discharged truck type 'j' at time 't' on zone 'z'
    @variable(EP, vCO2Ndischarged[z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of full truck type 'j' at time 't'
    @variable(EP, vCO2N_full[j in CO2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of empty truck type 'j' at time 't'
    @variable(EP, vCO2N_empty[j in CO2_TRUCK_TYPES, t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Function Expressions ##

    #Operating expenditure for truck type "j" during hour "t" on route "zz" -> "z"
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $

    # Operating expenditure for full and empty trucks
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            OPEX_CO2_Truck,
            sum(
                inputs["omega"][t] *
                (vCO2Narrive_full[zz, z, j, t] + vCO2Narrive_empty[zz, z, j, t]) *
                inputs["fuel_costs"][dfCO2Truck[!, :Fuel][j]][t] *
                dfCO2Truck[!, :Fuel_MMBTU_per_mile][j] *
                inputs["RouteLength"][zz, z] for
                zz = 1:Z, z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T if zz != z
            ) / ModelScalingFactor^2
        )
    else
        @expression(
            EP,
            OPEX_CO2_Truck,
            sum(
                inputs["omega"][t] *
                (vCO2Narrive_full[zz, z, j, t] + vCO2Narrive_empty[zz, z, j, t]) *
                inputs["fuel_costs"][dfCO2Truck[!, :Fuel][j]][t] *
                dfCO2Truck[!, :Fuel_MMBTU_per_mile][j] *
                inputs["RouteLength"][zz, z] for
                zz = 1:Z, z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T if zz != z
            )
        )
    end
    EP[:eObj] += OPEX_CO2_Truck

    # Operating expenditure for truck h2 compression
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            OPEX_Truck_CO2_Compression,
            sum(
                inputs["omega"][t] *
                (vCO2TruckFlow[z, j, t] * dfCO2Truck[!, :CO2TruckCompressionUnitOpex][j]) for
                z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T
            )
        ) / ModelScalingFactor^2
    else
        @expression(
            EP,
            OPEX_Truck_CO2_Compression,
            sum(
                inputs["omega"][t] *
                (vCO2TruckFlow[z, j, t] * dfCO2Truck[!, :CO2TruckCompressionUnitOpex][j]) for
                z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T
            )
        )
    end
    EP[:eObj] += OPEX_Truck_CO2_Compression
    ## End Objective Function Expressions ##

    ## Balance Expressions ##
    # H2 Power Compression Consumption balance
    @expression(
        EP,
        ePowerbalanceCO2TruckCompression[t = 1:T, z = 1:Z],
        if setup["ParameterScale"] == 1 # If ParameterScale = 1, power system operation/capacity modeled in GWh rather than MWh
            sum(
                vCO2Ncharged[z, j, t] *
                dfCO2Truck[!, :TruckCap_tonne_per_unit][j] *
                dfCO2Truck[!, :CO2TruckCompressionEnergy][j] for j in CO2_TRUCK_TYPES
            ) / ModelScalingFactor
        else
            sum(
                vCO2Ncharged[z, j, t] *
                dfCO2Truck[!, :TruckCap_tonne_per_unit][j] *
                dfCO2Truck[!, :CO2TruckCompressionEnergy][j] for j in CO2_TRUCK_TYPES
            )
        end
    )

    EP[:ePowerBalance] += -ePowerbalanceCO2TruckCompression
    
    # H2 Power Truck Travelling Consumption balance
    @expression(
        EP,
        ePowerbalanceCO2TruckTravel[t = 1:T, z = 1:Z],
        if setup["ParameterScale"] == 1
            sum(
                (vCO2Narrive_full[zz, z, j, t] + vCO2Narrive_empty[zz, z, j, t]) *
                dfCO2Truck[!, :Power_MW_per_mile][j] *
                inputs["RouteLength"][zz, z] for
                zz = 1:Z, j in CO2_TRUCK_TYPES if zz != z
            ) / ModelScalingFactor
        else
            sum(
                (vCO2Narrive_full[zz, z, j, t] + vCO2Narrive_empty[zz, z, j, t]) *
                dfCO2Truck[!, :Power_MW_per_mile][j] *
                inputs["RouteLength"][zz, z] for
                zz = 1:Z, j in CO2_TRUCK_TYPES if zz != z
            )
        end
    )

    EP[:ePowerBalance] += -ePowerbalanceCO2TruckTravel

    # carbon balance
    @expression(
        EP,
        eCO2TruckFlow[t = 1:T, z = 1:Z],
        sum(vCO2TruckFlow[z, j, t] for j in CO2_TRUCK_TYPES)
    )
    EP[:eCO2Balance] += eCO2TruckFlow

    # carbon truck emission penalty
    @expression(
        EP,
        Truck_carbon_emission,
        sum(
            inputs["omega"][t] *
            (vCO2Narrive_full[zz, z, j, t] + vCO2Narrive_empty[zz, z, j, t]) *
            inputs["fuel_CO2"][dfCO2Truck[!, :Fuel][j]] *
            dfCO2Truck[!, :Fuel_per_mile][j] *
            inputs["RouteLength"][zz, z] for
            zz = 1:Z, z = 1:Z, j in CO2_TRUCK_TYPES, t = 1:T if zz != z
        )
    )
    # EP[:eCarbonBalance] += Truck_carbon_emission
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###

    ## Total number
    @constraint(
        EP,
        cCO2TruckTotalNumber[j in CO2_TRUCK_TYPES, t in 1:T],
        vCO2N_full[j, t] + vCO2N_empty[j, t] == EP[:eTotalCO2TruckNumber][j]
    )

    # No truck in transit should have the same start and end 
    @constraints(
        EP,
        begin
            cCO2TruckSameZoneTravelFull[zz in 1:Z, z = zz, j in CO2_TRUCK_TYPES, t in 1:T],
            vCO2Ntravel_full[zz, z, j, t] == 0
            cCO2TruckSameZoneTravelEmpty[zz in 1:Z, z = zz, j in CO2_TRUCK_TYPES, t in 1:T],
            vCO2Ntravel_empty[zz, z, j, t] == 0
            cCO2TruckSameZoneArriveFull[zz in 1:Z, z = zz, j in CO2_TRUCK_TYPES, t in 1:T],
            vCO2Narrive_full[zz, z, j, t] == 0
            cCO2TruckSameZoneArriveEmpty[zz in 1:Z, z = zz, j in CO2_TRUCK_TYPES, t in 1:T],
            vCO2Narrive_empty[zz, z, j, t] == 0
            cCO2TruckSameZoneDepartFull[zz in 1:Z, z = zz, j in CO2_TRUCK_TYPES, t in 1:T],
            vCO2Ndepart_full[zz, z, j, t] == 0
            cCO2TruckSameZoneDepartEmpty[zz in 1:Z, z = zz, j in CO2_TRUCK_TYPES, t in 1:T],
            vCO2Ndepart_empty[zz, z, j, t] == 0
        end
    )

    # The number of total full and empty trucks
    @constraints(
        EP,
        begin
            cCO2TruckTotalFull[j in CO2_TRUCK_TYPES, t in 1:T],
            vCO2N_full[j, t] ==
            sum(vCO2Ntravel_full[zz, z, j, t] for zz = 1:Z, z = 1:Z if zz != z) +
            sum(vCO2Navail_full[z, j, t] for z = 1:Z)

            cCO2TruckTotalEmpty[j in CO2_TRUCK_TYPES, t in 1:T],
            vCO2N_empty[j, t] ==
            sum(vCO2Ntravel_empty[zz, z, j, t] for zz = 1:Z, z = 1:Z if zz != z) +
            sum(vCO2Navail_empty[z, j, t] for z = 1:Z)
        end
    )

    t_arrive = 1
    t_depart = 1

    # Change of the number of full available trucks
    @constraints(
        EP,
        begin
            cCO2TruckChangeFullAvailInterior[
                z in 1:Z,
                j in CO2_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vCO2Navail_full[z, j, t] - vCO2Navail_full[z, j, t-1] ==
            vCO2Ncharged[z, j, t] - vCO2Ndischarged[z, j, t] +
            sum(vCO2Narrive_full[zz, z, j, t-t_arrive] for zz = 1:Z if zz != z) -
            sum(vCO2Ndepart_full[z, zz, j, t-t_depart] for zz = 1:Z if zz != z) + 0
            cCO2TruckChangeFullAvailStart[
                z in 1:Z,
                j in CO2_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vCO2Navail_full[z, j, t] -
            vCO2Navail_full[z, j, t+inputs["hours_per_subperiod"]-1] ==
            vCO2Ncharged[z, j, t] - vCO2Ndischarged[z, j, t] + sum(
                vCO2Narrive_full[zz, z, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            ) - sum(
                vCO2Ndepart_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            )
        end
    )

    # Change of the number of empty available trucks
    @constraints(
        EP,
        begin
            cCO2TruckChangeEmptyAvailInterior[
                z in 1:Z,
                j in CO2_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vCO2Navail_empty[z, j, t] - vCO2Navail_empty[z, j, t-1] ==
            -vCO2Ncharged[z, j, t] +
            vCO2Ndischarged[z, j, t] +
            sum(vCO2Narrive_empty[zz, z, j, t-t_arrive] for zz = 1:Z if zz != z) -
            sum(vCO2Ndepart_empty[z, zz, j, t-t_depart] for zz = 1:Z if zz != z)
            cCO2TruckChangeEmptyAvailStart[
                z in 1:Z,
                j in CO2_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vCO2Navail_empty[z, j, t] -
            vCO2Navail_empty[z, j, t+inputs["hours_per_subperiod"]-1] ==
            -vCO2Ncharged[z, j, t] +
            vCO2Ndischarged[z, j, t] +
            sum(
                vCO2Narrive_empty[zz, z, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            ) - sum(
                vCO2Ndepart_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            )
        end
    )

    # Change of the number of full traveling trucks
    @constraints(
        EP,
        begin
            cCO2TruckChangeFullTravelInterior[
                z in 1:Z,
                zz in 1:Z,
                j in CO2_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vCO2Ntravel_full[z, zz, j, t] - vCO2Ntravel_full[z, zz, j, t-1] ==
            vCO2Ndepart_full[z, zz, j, t-t_depart] - vCO2Narrive_full[z, zz, j, t-t_arrive]
            cCO2TruckChangeFullTravelStart[
                z in 1:Z,
                zz in 1:Z,
                j in CO2_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vCO2Ntravel_full[z, zz, j, t] -
            vCO2Ntravel_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] ==
            vCO2Ndepart_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] -
            vCO2Narrive_full[z, zz, j, t+inputs["hours_per_subperiod"]-1]
        end
    )

    # Change of the number of empty traveling trucks
    @constraints(
        EP,
        begin
            cCO2TruckChangeEmptyTravelInterior[
                z in 1:Z,
                zz in 1:Z,
                j in CO2_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vCO2Ntravel_empty[z, zz, j, t] - vCO2Ntravel_empty[z, zz, j, t-1] ==
            vCO2Ndepart_empty[z, zz, j, t-t_depart] - vCO2Narrive_empty[z, zz, j, t-t_arrive]
            cCO2TruckChangeEmptyTravelStart[
                z in 1:Z,
                zz in 1:Z,
                j in CO2_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vCO2Ntravel_empty[z, zz, j, t] -
            vCO2Ntravel_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] ==
            vCO2Ndepart_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] -
            vCO2Narrive_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1]
        end
    )

    # Travel delay
    @constraints(
        EP,
        begin
            [zz in 1:Z, z in 1:Z, j in CO2_TRUCK_TYPES, t in 1:T],
            vCO2Ntravel_full[zz, z, j, t] >= sum(
                vCO2Narrive_full[zz, z, j, tt] for
                tt = (t+1):(t+inputs["TD"][j][zz, z]) if t + inputs["TD"][j][zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][zz, z] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][zz, z]
            )
            [zz in 1:Z, z in 1:Z, j in CO2_TRUCK_TYPES, t in 1:T],
            vCO2Ntravel_empty[zz, z, j, t] >= sum(
                vCO2Ndepart_empty[zz, z, j, tt] for
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
            [zz in 1:Z, z in 1:Z, j in CO2_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vCO2Ntravel_full[zz, z, j, t] >= sum(
                vCO2Narrive_full[zz, z, j, tt] for
                tt = (t+1):(t+inputs["TD"][j][zz, z]) if t + inputs["TD"][j][zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][zz, z] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][zz, z]
            )
            [zz in 1:Z, z in 1:Z, j in CO2_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vCO2Ntravel_empty[zz, z, j, t] >= sum(
                vCO2Narrive_empty[zz, z, j, tt] for
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
        [z in 1:Z, j in CO2_TRUCK_TYPES, t in 1:T],
        vCO2Ncharged[z, j, t] * dfCO2Truck[!, :TruckCap_tonne_per_unit][j] <=
        EP[:eTotalCO2TruckEnergy][z, j]
    )

    # H2 truck flow balance
    @constraint(
        EP,
        cCO2TruckFlow[z in 1:Z, j in CO2_TRUCK_TYPES, t in 1:T],
        vCO2TruckFlow[z, j, t] ==
        vCO2Ndischarged[z, j, t] *
        dfCO2Truck[!, :TruckCap_tonne_per_unit][j] *
        (1 - dfCO2Truck[!, :CO2TLoss_per_mile][j]) -
        vCO2Ncharged[z, j, t] * dfCO2Truck[!, :TruckCap_tonne_per_unit][j]
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