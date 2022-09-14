"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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
    h2_long_duration_truck(EP::Model, inputs::Dict)

This function includes LongDurationtruck only when modeling representative periods.

** Variables**

State of charge of truck at beginning of each modeled period n.
\begin{align}
    v_{j, t}^{\mathrm{F}}+v_{j, t}^{\mathrm{E}} & = V_{j} \quad \forall j \in \mathbb{J}, t \in \mathbb{T}
\end{align}

```math
\begin{aligned}
    v_{n}^{SOC} \geq 0
\end{aligned}
```

**Constraints**

State of charge of truck at beginning of each modeled period cannot exceed installed energy capacity
```math
\begin{aligned}
    v_{z,j,n}^{SOC} \leq v_{j}^{TRU}
\end{aligned}
```

"""
function h2_long_duration_truck(EP::Model, inputs::Dict)

    println("H2 Long Duration Truck Module")

    Z = inputs["Z"] # Number of zone locations
    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"]
    dfPeriodMap = inputs["Period_Map"]

    inputs["NPeriods"]  = size(inputs["Period_Map"])[1] # Number of modeled periods
    N = inputs["NPeriods"] # Number of modeled periods
    MODELED_PERIODS_INDEX = 1:N

    MODELED_HOURS_INDEX = 1:inputs["hours_per_subperiod"]

    REP_PERIOD = inputs["REP_PERIOD"] # Number of representative periods
    REP_PERIODS_INDEX =
        MODELED_PERIODS_INDEX[dfPeriodMap[!, :Rep_Period].==MODELED_PERIODS_INDEX]

    ### Variables ###
    # State of charge of truck at beginning of each modeled period n
    @variable(
        EP,
        0 >= vH2TruckSOCw[z = 1:Z, j in H2_TRUCK_TYPES, n in MODELED_HOURS_INDEX] >= 0
    )

    # Build up in truck inventory over each representative period w
    # Build up inventory is fixed zero
    @variable(EP, 0 >= vH2TruckdSOC[z = 1:Z, j in H2_TRUCK_TYPES, w = 1:REP_PERIOD] >= 0)

    @constraints(
        EP,
        begin
            # State of charge of truck at beginning of each modeled period cannot exceed installed energy capacity
            [z = 1:Z, j in H2_TRUCK_TYPES, n in MODELED_HOURS_INDEX],
            vH2TruckSOCw[z, j, n] <= vH2NTruck[j]

            # State of charge of truck balance
            [z = 1:Z, j in H2_TRUCK_TYPES, n = N],
                vH2TruckSOCw[z, j, 1] ==
                vH2TruckSOCw[z, j, n] +
                vH2TruckdSOC[z, j, dfPeriodMap[!, :RepPeriod_index][n]]
            [z = 1:Z, j in H2_TRUCK_TYPES, n = 1:N-1],
                vH2TruckSOCw[z, j, n+1] ==
                vH2TruckSOCw[z, j, n] +
                vH2TruckdSOC[z, j, dfPeriodMap[!, :RepPeriod_index][n]]
        end
    )

    return EP
end
