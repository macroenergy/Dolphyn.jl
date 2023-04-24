"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
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
    h2_truck_all(EP::Model, inputs::Dict, setup::Dict)

This function defines a series of operating variables, expressions and constraints in truck scheduling and routing model.
We establish the truck scheduling model by modeling the change of truck's states and number. In each zone 'z', we have
available trucks either in full or empty states which are ready for unloading or loading. In addition, we have trucks
in transit states which are either in full or empty states. Further the transit states are divided into three categories:
departed, arrived and in-transit. The departed trucks are trucks that have already loaded energy carrier such as hydrogen
in the origin zone; the arrived trucks are trucks that have already unloaded energy carrier in the destination zone;
and the in-transit trucks are trucks that are in transit on a certain defined route. The truck state will shift from loaded
to departed after the truck loading time, and samely, the truck state will shift from unloaded to arrived after the truck
unloading time. Detailed truck model description is available in the [G. He, D. S. Mallapragada 2021](https://ieeexplore.ieee.org/abstract/document/9371425).

![Truck scheduling model](assets/truck_scheduling.jpg)
*Figure. Truck scheduling model*

**Variables**

|Variable|Description|
|--------|-----------|
|$v_{j, t}^{\textrm{F}}$|Number of full trucks of type 'j' at time 't'|
|$v_{j, t}^{\textrm{E}}$|Number of empty trucks of type 'j' at time 't'|
|$V_{j}$|Total number of trucks including full and empty of type 'j'|
|$q_{z, j, t}^{\textrm{F}}$|Number of available full trucks of type 'j' at zone 'z' at time 't'|
|$q_{z, j, t}^{\textrm{E}}$|Number of available empty trucks of type 'j' at zone 'z' at time 't'|
|$u_{r, d, j, t}^{\textrm{F}}$|Number of full trucks in transit on route 'r' with direction 'd' of type 'j' at time 't'|
|$u_{r, d, j, t}^{\textrm{E}}$|Number of empty trucks in transit on route 'r' with direction 'd' of type 'j' at time 't'|
|$x_{r, d, j, t-1}^{\textrm{F}}$|Number of departed full trucks in transit on route 'r' with direction 'd' of type 'j' at time 't'|
|$x_{r, d, j, t-1}^{\textrm{E}}$|Number of departed empty trucks in transit on route 'r' with direction 'd' of type 'j' at time 't'|
|$y_{r, d, j, t-1}^{\textrm{F}}$|Number of arrived full trucks in transit on route 'r' with direction 'd' of type 'j' at time 't'|
|$y_{r, d, j, t-1}^{\textrm{E}}$|Number of arrived empty trucks in transit on route 'r' with direction 'd' of type 'j' at time 't'|

**Constraints**

The sum of full and empty trucks should equal to the total number of invested trucks.
```math
\begin{equation*}
    v_{j, t}^{\textrm{F}}+v_{j, t}^{\textrm{E}}=V_{j} \quad \forall j \in \mathbb{J}, t \in \mathbb{T}
\end{equation*}
```

The full (empty) trucks include full (empty) trucks in transit and staying at each zones.
```math
\begin{aligned}
    v_{j, t}^{\textrm{F}}=\sum_{r \in \mathbb{Route}, d \in [-1,1]} u_{r, d, j, t}^{\textrm{F}}+\sum_{z \in \mathbb{Z}} q_{z, j, t}^{\textrm{F}} \\
    v_{j, t}^{\textrm{E}}=\sum_{r \in \mathbb{Route}, d \in [-1,1]} u_{r, d, j, t}^{\textrm{E}}+\sum_{z \in \mathbb{Z}} q_{z, j, t}^{\textrm{E}} \quad \forall j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}
```

The change of the total number of full (empty) available trucks at zone z should equal the number of charged (discharged) trucks minus the number of discharged (charged) trucks at zone z plus the number of full (empty) trucks that just arrived minus the number of full (empty) trucks that just departed:
```math
\begin{aligned}
    q_{z, j, t}^{\textrm{F}}-q_{z, j, t-1}^{\textrm{F}}=& q_{z, j, t}^{\textrm{CHA}}-q_{z, j, t}^{\textrm{DIS}} \\
    &+\sum_{(r,d)\in \{(r,d)\vert (r,d)=(z,z^{\prime},1) or (r,d)=(z^{\prime},z,-1) \forall z^{\prime} in \mathbb{Z}\}}\left(-x_{r, d, j, t-1}^{\textrm{F}}+y_{r, d, j, t-1}^{\textrm{F}}\right) \\
    q_{z, j, t}^{\textrm{E}}-q_{z, j, t-1}^{\textrm{E}}=&-q_{z, j, t}^{\textrm{CHA}}+q_{z, j, t}^{\textrm{DIS}} \\
    &+\sum_{(r,d)\in \{(r,d)\vert (r,d)=(z,z^{\prime},1) or (r,d)=(z^{\prime},z,-1) \forall z^{\prime} in \mathbb{Z}\}}\left(-x_{r, d, j, t-1}^{\textrm{E}}+y_{r, d, j, t-1}^{\textrm{E}}\right) \\
    \quad \forall z \in \mathbb{Z}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}
```

The change of the total number of full (empty) trucks in transit from zone $z$ to zone $z^{\prime}$ (on route $r$ with direction $d$) should equal the number of full (empty) trucks that just departed from zone $z$ minus the number of full (empty) trucks that just arrived at zone $z^{\prime}$:
```math
\begin{aligned}
    u_{r, d, j, t}^{\textrm{F}}-u_{r, d, j, t-1}^{\textrm{F}} &= x_{r, d, j, t-1}^{\textrm{F}} - y_{r, d, j, t-1}^{\textrm{F}} \\
    u_{r, d, j, t}^{\textrm{E}}-u_{r, d, j, t-1}^{\textrm{E}} &= x_{r, d, j, t-1}^{\textrm{E}} - y_{r, d, j, t-1}^{\textrm{E}} \\
    & \quad \forall r \in \mathbb{R}, j \in \mathbb{J}, d \in [-1,1], t \in \mathbb{T}
\end{aligned}
```

The amount of H2 delivered to zone z should equal the truck capacity times the number of discharged trucks minus the number of charged trucks, adjusted by theH2 boil-off loss during truck transportation and compression.
```math
\begin{aligned}
    h_{z, j, t}^{\textrm{H,TRU}}=\left[\left(1-\sigma_{j}\right) q_{z, j, t}^{\textrm{DIS}}-q_{z, j, t}^{\textrm{CHA}}\right] \overline{\textrm{E}}_{j}^{\textrm{H,TRU}} \\
    \quad \forall z \in \mathbb{Z}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}
```

The minimum travelling time delay is modelled as follows.
```math
\begin{aligned}
    u_{r, d, j, t}^{\textrm{F}} \geq \sum_{e=t-\Delta_{r+1}}^{e=t} x_{r, d, j, e}^{\textrm{F}} \\
    u_{r, d, j, t}^{\textrm{E}} \geq \sum_{e=t-\Delta_{r+1}}^{e=t} x_{r, d, j, e}^{\textrm{E}} \quad \forall r \in \mathbb{R}, j \in \mathbb{J}, d \in [-1,1], t \in \mathbb{T}
\end{aligned}
```

```math
\begin{aligned}
    u_{r, d, j, t}^{\textrm{F}} \geq \sum_{e=t+1}^{e=t+\Delta_{t}} y_{r, d, j, e}^{\textrm{F}} \\
    u_{r, d, j, t}^{\textrm{E}} \geq \sum_{e=t+1}^{e=t+\Delta_{t}} y_{r, d, j, e}^{\textrm{E}} \\
    \quad \forall r \in \mathbb{R}, j \in \mathbb{J}, d \in [-1,1], t \in \mathbb{T}
\end{aligned}
```

The charging capability of truck stations is limited by their compression or liquefaction capacity.
```math
\begin{equation*}
    q_{z, j, t}^{\textrm{CHA}} \overline{\textrm{E}}_{j}^{\textrm{H,TRU}} \leq H_{z, j}^{\textrm{H,TRU}} \quad \forall z \in \mathbb{Z}, j \in \mathbb{J}, t \in \mathbb{T}
\end{equation*}
```
"""
function h2_truck_all(EP::Model, inputs::Dict, setup::Dict)

    # Setup variables, constraints, and expressions common to all hydrogen truck resources
    print_and_log("H2 Truck Core Resources Module")

    dfH2Truck = inputs["dfH2Truck"]
    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"] # Set of h2 truck types

    T = inputs["T"] # Number of time steps (hours)
    Z = inputs["Z"] # Number of zones
    R = inputs["R"] # Number of routes

    START_SUBPERIODS = inputs["START_SUBPERIODS"] # Starting subperiod index for each representative period
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] # Index of interior subperiod for each representative period

    dfH2Route = inputs["dfH2Route"]

    Truck_map = inputs["Truck_map"]

    ### Variables ###

    # Truck flow volume [tonne] through type 'j' at time 't' on zone 'z'
    @variable(EP, vH2TruckFlow[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T])

    # Number of available full truck type 'j' in transit at time 't' on zone 'z'
    @variable(EP, vH2Navail_full[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of travel, arrive and deaprt full truck type 'j' in transit at time 't' from zone 'zz' to 'z'
    @variable(EP, vH2Ntravel_full[r = 1:R, j in H2_TRUCK_TYPES, d in [-1, 1], t = 1:T] >= 0)
    @variable(EP, vH2Narrive_full[r = 1:R, j in H2_TRUCK_TYPES, d in [-1, 1], t = 1:T] >= 0)
    @variable(EP, vH2Ndepart_full[r = 1:R, j in H2_TRUCK_TYPES, d in [-1, 1], t = 1:T] >= 0)

    # Number of available empty truck type 'j' in transit at time 't' on zone 'z'
    @variable(EP, vH2Navail_empty[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of travel, arrive and deaprt empty truck type 'j' in transit at time 't' from zone 'zz' to 'z'
    @variable(
        EP,
        vH2Ntravel_empty[r = 1:R, j in H2_TRUCK_TYPES, d in [-1, 1], t = 1:T] >= 0
    )
    @variable(
        EP,
        vH2Narrive_empty[r = 1:R, j in H2_TRUCK_TYPES, d in [-1, 1], t = 1:T] >= 0
    )
    @variable(
        EP,
        vH2Ndepart_empty[r = 1:R, j in H2_TRUCK_TYPES, d in [-1, 1], t = 1:T] >= 0
    )

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
                (vH2Narrive_full[r, j, d, t] + vH2Narrive_empty[r, j, d, t]) *
                inputs["fuel_costs"][dfH2Truck[!, :Fuel][j]][t] *
                dfH2Truck[!, :Fuel_MMBTU_per_mile][j] *
                dfH2Route[!, :Distance][r] for r = 1:R, j in H2_TRUCK_TYPES, d in [-1, 1],
                t = 1:T
            ) / ModelScalingFactor^2
        )
    else
        @expression(
            EP,
            OPEX_Truck,
            sum(
                inputs["omega"][t] *
                (vH2Narrive_full[r, j, d, t] + vH2Narrive_empty[r, j, d, t]) *
                inputs["fuel_costs"][dfH2Truck[!, :Fuel][j]][t] *
                dfH2Truck[!, :Fuel_MMBTU_per_mile][j] *
                dfH2Route[!, :Distance][r] for r = 1:R, j in H2_TRUCK_TYPES, d in [-1, 1],
                t = 1:T
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
    # Power balance from hydrogen compression consumption
    @expression(
        EP,
        ePowerbalanceH2TruckCompression[t = 1:T, z = 1:Z],
        if setup["ParameterScale"] == 1 # If ParameterScale = 1, power system operation/capacity modeled in GWh rather than MWh
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

    EP[:ePowerBalance] += -ePowerbalanceH2TruckCompression
    EP[:eH2NetpowerConsumptionByAll] += ePowerbalanceH2TruckCompression

    # Power balance from electric truck travelling onsumption balance
    @expression(
        EP,
        ePowerbalanceH2TruckTravel[t = 1:T, z = 1:Z],
        if setup["ParameterScale"] == 1
            sum(
                (
                    vH2Narrive_full[
                        r,
                        j,
                        Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                        t,
                    ] + vH2Narrive_empty[
                        r,
                        j,
                        Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                        t,
                    ]
                ) *
                dfH2Truck[!, :Power_MW_per_mile][j] *
                dfH2Route[!, :Distance][r] for
                r in Truck_map[Truck_map.Zone.==z, :route_no], j in H2_TRUCK_TYPES;init=0.0
            ) / ModelScalingFactor
        else
            sum(
                (
                    vH2Narrive_full[
                        r,
                        j,
                        Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                        t,
                    ] + vH2Narrive_empty[
                        r,
                        j,
                        Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                        t,
                    ]
                ) *
                dfH2Truck[!, :Power_MW_per_mile][j] *
                dfH2Route[!, :Distance][r] for
                r in Truck_map[Truck_map.Zone.==z, :route_no], j in H2_TRUCK_TYPES;init=0.0
            )
        end
    )

    EP[:ePowerBalance] += -ePowerbalanceH2TruckTravel
    EP[:eH2NetpowerConsumptionByAll] += ePowerbalanceH2TruckTravel

    # Hydrogen balance via truck transmission
    @expression(
        EP,
        eH2TruckFlow[t = 1:T, z = 1:Z],
        sum(vH2TruckFlow[z, j, t] for j in H2_TRUCK_TYPES)
    )
    EP[:eH2Balance] += eH2TruckFlow

    # Hydrogen balance via truck traveling consumption
    @expression(
        EP,
        eH2TruckTravelConsumption[t = 1:T, z = 1:Z],
        sum(
            (
                vH2Narrive_full[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t,
                ] + vH2Narrive_empty[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t,
                ]
            ) *
            dfH2Truck[!, :H2_tonne_per_mile][j] *
            dfH2Route[!, :Distance][r] for
            r in Truck_map[Truck_map.Zone.==z, :route_no], j in H2_TRUCK_TYPES
        )
    )

    EP[:eH2Balance] += -eH2TruckTravelConsumption

    # H2 truck emission penalty
    @expression(
        EP,
        Truck_carbon_emission[t = 1:T, z = 1:Z],
        sum(
            inputs["omega"][t] *
            (
                vH2Narrive_full[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t,
                ] + vH2Narrive_empty[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t,
                ]
            ) *
            inputs["fuel_CO2"][dfH2Truck[!, :Fuel][j]] *
            dfH2Truck[!, :Fuel_MMBTU_per_mile][j] *
            dfH2Route[!, :Distance][r] for
            r in Truck_map[Truck_map.Zone.==z, :route_no], j in H2_TRUCK_TYPES, t = 1:T
        )
    )
    # EP[:eCarbonBalance] += Truck_carbon_emission
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###

    ## Total number = empty + full number
    @constraint(
        EP,
        cH2TruckTotalNumber[j in H2_TRUCK_TYPES, t in 1:T],
        vH2N_full[j, t] + vH2N_empty[j, t] == EP[:eTotalH2TruckNumber][j]
    )

    # The number of total full (empty) trucks = travelling + available
    @constraints(
        EP,
        begin
            cH2TruckTotalFull[j in H2_TRUCK_TYPES, t in 1:T],
            vH2N_full[j, t] ==
            sum(vH2Ntravel_full[r, j, d, t] for r = 1:R, d in [-1, 1]) +
            sum(vH2Navail_full[z, j, t] for z = 1:Z)

            cH2TruckTotalEmpty[j in H2_TRUCK_TYPES, t in 1:T],
            vH2N_empty[j, t] ==
            sum(vH2Ntravel_empty[r, j, d, t] for r = 1:R, d in [-1, 1]) +
            sum(vH2Navail_empty[z, j, t] for z = 1:Z)
        end
    )

    t_arrive = 1
    t_depart = 1

    # Change of the number of full available trucks on each zone
    # For each typr of truck, on each zone, the number change equals charged (meant to leave) +
    # discharged (meant arrived) + arrived (not discharged) - departed (charged)
    # The difference between charged and departed (same with discharged and arrived) is that
    # there is a time lag between the two events which is set to be one hour
    @constraints(
        EP,
        begin
            cH2TruckChangeFullAvailInterior[
                z in 1:Z,
                j in H2_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vH2Navail_full[z, j, t] - vH2Navail_full[z, j, t-1] ==
            vH2Ncharged[z, j, t] - vH2Ndischarged[z, j, t] + sum(
                vH2Narrive_full[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t-t_arrive,
                ] for r in Truck_map[Truck_map.Zone.==z, :route_no]
            ) - sum(
                vH2Ndepart_full[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t-t_depart,
                ] for r in Truck_map[Truck_map.Zone.==z, :route_no]
            )
            cH2TruckChangeFullAvailStart[
                z in 1:Z,
                j in H2_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vH2Navail_full[z, j, t] -
            vH2Navail_full[z, j, t+inputs["hours_per_subperiod"]-1] ==
            vH2Ncharged[z, j, t] - vH2Ndischarged[z, j, t] + sum(
                vH2Narrive_full[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t+inputs["hours_per_subperiod"]-1,
                ] for r in Truck_map[Truck_map.Zone.==z, :route_no]
            ) - sum(
                vH2Ndepart_full[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t+inputs["hours_per_subperiod"]-1,
                ] for r in Truck_map[Truck_map.Zone.==z, :route_no]
            )
        end
    )

    # Change of the number of empty available trucks on each zone
    # For each typr of truck, on each zone, the number change equals discharged (meant to arrive) -
    # charged (meant to leave) + arrived (not discharged) - departed (charged)
    # The difference between charged and departed (same with discharged and arrived) is that
    # there is a time lag between the two events which is set to be one hour
    @constraints(
        EP,
        begin
            cH2TruckChangeEmptyAvailInterior[
                z in 1:Z,
                j in H2_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vH2Navail_empty[z, j, t] - vH2Navail_empty[z, j, t-1] ==
            -vH2Ncharged[z, j, t] +
            vH2Ndischarged[z, j, t] +
            sum(
                vH2Narrive_empty[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t-t_arrive,
                ] for r in Truck_map[Truck_map.Zone.==z, :route_no]
            ) - sum(
                vH2Ndepart_empty[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t-t_depart,
                ] for r in Truck_map[Truck_map.Zone.==z, :route_no]
            )
            cH2TruckChangeEmptyAvailStart[
                z in 1:Z,
                j in H2_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vH2Navail_empty[z, j, t] -
            vH2Navail_empty[z, j, t+inputs["hours_per_subperiod"]-1] ==
            -vH2Ncharged[z, j, t] +
            vH2Ndischarged[z, j, t] +
            sum(
                vH2Narrive_empty[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t+inputs["hours_per_subperiod"]-1,
                ] for r in Truck_map[Truck_map.Zone.==z, :route_no]
            ) - sum(
                vH2Ndepart_empty[
                    r,
                    j,
                    Truck_map[(Truck_map.Zone.==z).&(Truck_map.route_no.==r), :d][1],
                    t+inputs["hours_per_subperiod"]-1,
                ] for r in Truck_map[Truck_map.Zone.==z, :route_no]
            )
        end
    )

    # For each typr of truck, on each zone, the number change of full traveling trucks equals
    # departed - arrived
    @constraints(
        EP,
        begin
            cH2TruckChangeFullTravelInterior[
                r in 1:R,
                j in H2_TRUCK_TYPES,
                d in [-1, 1],
                t in INTERIOR_SUBPERIODS,
            ],
            vH2Ntravel_full[r, j, d, t] - vH2Ntravel_full[r, j, d, t-1] ==
            vH2Ndepart_full[r, j, d, t-t_depart] - vH2Narrive_full[r, j, d, t-t_arrive]
            cH2TruckChangeFullTravelStart[
                r in 1:R,
                j in H2_TRUCK_TYPES,
                d in [-1, 1],
                t in START_SUBPERIODS,
            ],
            vH2Ntravel_full[r, j, d, t] -
            vH2Ntravel_full[r, j, d, t+inputs["hours_per_subperiod"]-1] ==
            vH2Ndepart_full[r, j, d, t+inputs["hours_per_subperiod"]-1] -
            vH2Narrive_full[r, j, d, t+inputs["hours_per_subperiod"]-1]
        end
    )

    # For each typr of truck, on each zone, the number change of empty traveling trucks equals
    # departed - arrived
    @constraints(
        EP,
        begin
            cH2TruckChangeEmptyTravelInterior[
                r in 1:R,
                j in H2_TRUCK_TYPES,
                d in [-1, 1],
                t in INTERIOR_SUBPERIODS,
            ],
            vH2Ntravel_empty[r, j, d, t] - vH2Ntravel_empty[r, j, d, t-1] ==
            vH2Ndepart_empty[r, j, d, t-t_depart] - vH2Narrive_empty[r, j, d, t-t_arrive]
            cH2TruckChangeEmptyTravelStart[
                r in 1:R,
                j in H2_TRUCK_TYPES,
                d in [-1, 1],
                t in START_SUBPERIODS,
            ],
            vH2Ntravel_empty[r, j, d, t] -
            vH2Ntravel_empty[r, j, d, t+inputs["hours_per_subperiod"]-1] ==
            vH2Ndepart_empty[r, j, d, t+inputs["hours_per_subperiod"]-1] -
            vH2Narrive_empty[r, j, d, t+inputs["hours_per_subperiod"]-1]
        end
    )

    # Travel delay
    @constraints(
        EP,
        begin
            [r in 1:R, j in H2_TRUCK_TYPES, d in [-1, 1], t in 1:T],
            vH2Ntravel_full[r, j, d, t] >= sum(
                vH2Narrive_full[r, j, d, tt] for
                tt = (t+1):(t+inputs["TD"][j][r]) if t + inputs["TD"][j][r] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][r] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][r]
            )
            [r in 1:R, j in H2_TRUCK_TYPES, d in [-1, 1], t in 1:T],
            vH2Ntravel_empty[r, j, d, t] >= sum(
                vH2Ndepart_empty[r, j, d, tt] for
                tt = (t-inputs["TD"][j][r]+1):t if t + inputs["TD"][j][r] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][r] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][r]
            )
        end
    )

    @constraints(
        EP,
        begin
            [r in 1:R, j in H2_TRUCK_TYPES, d in [-1, 1], t in INTERIOR_SUBPERIODS],
            vH2Ntravel_full[r, j, d, t] >= sum(
                vH2Narrive_full[r, j, d, tt] for
                tt = (t+1):(t+inputs["TD"][j][r]) if t + inputs["TD"][j][r] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][r] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][r]
            )
            [r in 1:R, j in H2_TRUCK_TYPES, d in [-1, 1], t in INTERIOR_SUBPERIODS],
            vH2Ntravel_empty[r, j, d, t] >= sum(
                vH2Narrive_empty[r, j, d, tt] for
                tt = (t+1):(t+inputs["TD"][j][r]) if t + inputs["TD"][j][r] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][r] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][r]
            )
        end
    )

    # Capacity constraints charged hydrogen is less than the maximum compression capacity
    @constraint(
        EP,
        [z in 1:Z, j in H2_TRUCK_TYPES, t in 1:T],
        vH2Ncharged[z, j, t] * dfH2Truck[!, :TruckCap_tonne_per_unit][j] <=
        EP[:eTotalH2TruckComp][z, j]
    )

    # H2 truck flow balance
    @constraint(
        EP,
        cH2TruckFlow[z in 1:Z, j in H2_TRUCK_TYPES, t in 1:T],
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
# if t + inputs["TD"][j][zz, z] >=
#    (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
#    t + inputs["TD"][j][zz, z] <= t + inputs["hours_per_subperiod"] - 1 &&
#    t + 1 <= t + inputs["TD"][j][zz, z]
#     nothing
# end
