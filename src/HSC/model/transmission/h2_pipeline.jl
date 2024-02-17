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
    h2_pipeline(EP::Model, inputs::Dict, setup::Dict)

This function includes the variables, expressions and objective funtion of hydrogen pipeline.

This function expresses hydrogen exchange through pipeline i between two zones and can be split into H2 delivering and flowing out.

This module defines the hydrogen pipeline construction decision variable $y_{i,z \rightarrow z^{\prime}}^{\textrm{H,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}$, representing newly constructed hydrogen pipeline of type $i$ through path $z \rightarrow z^{\prime}$.

This module defines the hydrogen pipeline flow decision variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$, representing hydrogen flow via pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$.

This module defines the hydrogen pipeline storage level decision variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$, representing hydrogen stored in pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$. This type of storage is known as "Line Packing".

The variable defined in this file named after ```vH2NPipe``` covers variable $y_{i,z \rightarrow z^{\prime}}^{\textrm{H,PIP}}$.

Variable to track positive hydrogen flow through pipeline
This variable tracks the positive (unidirectional) flow of hydrogen through each pipeline in each time period. It is indexed by pipeline type `i`, pipeline path `z -> z'`, and time period `t`. Along with the corresponding negative flow variable, it is used to calculate net pipeline flow. Tracks the positive hydrogen flow through the pipeline in the forward direction
in the direction from zone z to zone z'# Variable to track positive hydrogen flow through pipeline
Variable to track positive hydrogen flow through pipeline 
_pos``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP+}}$.

The variable defined in this file named after ```vH2PipeFlow_neg``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP-}}$.

The variable defined in this file named after ```vH2PipeLevel``` covers variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}}$.

The key to understanding how the pipeline flow works is through the expression '''eH2PipeFlow_net'''. This expression can be split up into 4 components that represent the inflow and outflow at each end of a single pipeline. For each zone that the pipeline connects, that side of the pipeline could either import hydrogen from the zone or export it into the zone. The unidirectional flow setting turns off the source side of the pipeline's ability to export hydrogen into the zone and the sink side of the pipeline's ability to import hydrogen from the zone.


**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of generation (fixed OM plus construction) from all pipeline resources $i \in \mathcal{I}$:

```math
\begin{equation*}
    \textrm{C}^{\textrm{H,PIP,c}}=\delta_{i}^{\textrm{H,PIP}} \sum_{i \in \mathbb{I}} \sum_{z \rightarrow z^{\prime} \in \mathbb{B}} \textrm{c}_{i}^{\textrm{H,PIP}} \textrm{L}_{z \rightarrow z^{\prime}} l_{i,z \rightarrow z^{\prime}}
    h_{i,z \rightarrow z^{\prime}, t}^{\textrm{H,PIP}}=h_{i, z \rightarrow z^{\prime}, t}^{\textrm{H,PIP+}}-h_{i, z \rightarrow z^{\prime}, t}^{\textrm{PIP-}} \quad \forall i \in \mathbb{I}, z \rightarrow z^{\prime} \in \mathbb{B}, t \in \mathbb{T}
\end{equation*}
 ```

The flow rate of H2 through pipeline type $i$ is capped by the operational limits of the pipeline, multiplied by the number of constructed pipeline $i$
```math
\begin{equation*}
    \overline{\textrm{F}}_{i} l_{i,z \rightarrow z^{\prime}} \geq x_{i,z \rightarrow z^{\prime}, t}^{\textrm{\textrm{H,PIP+}}}, x_{i,z \rightarrow z^{\prime}, t}^{\textrm{\textrm{H,PIP-}}} \geq 0 \quad \forall i \in \mathbb{I}, z \rightarrow z^{\prime} \in \mathbb{B}, t \in \mathbb{T}
\end{equation*}    
```

The pipeline has storage capacity via line packing:
```math
\begin{equation*}
    \overline{\textrm{U}}_{i}^{\textrm{\textrm{H,PIP}}} l_{i,z \rightarrow z^{\prime}} \geq -\sum_{\tau=t_{0}}^{t}\left(x_{i,z^{\prime} \rightarrow z, \tau}^{\textrm{\textrm{H,PIP}}}+x_{i,z \rightarrow z^{\prime}, \tau}^{\textrm{\textrm{H,PIP}}}\right) \Delta t \geq \underline{\textrm{R}}_{i}^{\textrm{\textrm{H,PIP}}} \overline{\textrm{E}}_{i}^{\textrm{\textrm{H,PIP}}} l_{i,z \rightarrow z^{\prime}} \\
    & \forall z^{\prime} \in \mathbb{Z}, z \in \mathbb{Z}, i \in \mathbb{I}, t \in \mathbb{T}
\end{equation*}   
```

The change of hydrogen pipeline storage inventory is modeled as follows:
```math
\begin{equation*}
    U_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}} - U_{i,z \rightarrow z^{\prime},t-1} = x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP-}} + x_{i,z^{\prime} \rightarrow z,t}^{\textrm{H,PIP-}}
\end{equation*}
```
"""
function h2_pipeline(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("Hydrogen Pipeline Module")

    T = inputs["T"] # Model operating time steps
    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity

    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]

    H2_P = inputs["H2_P"] # Number of Hydrogen Pipelines
    H2_Pipe_Map = inputs["H2_Pipe_Map"]

    Source_H2_Pipe_Map = H2_Pipe_Map[H2_Pipe_Map.d .== 1, :]
    Sink_H2_Pipe_Map = H2_Pipe_Map[H2_Pipe_Map.d .== -1, :]

    ### Variables ###
    # Here the d index refers to the zones. +1 d refers to the source zone. -1 d refers to the destination zone.
    # p refers to each unique pipeline
    @variable(EP, vH2NPipe[p = 1:H2_P] >= 0) # Number of Pipes
    @variable(EP, vH2PipeLevel[p = 1:H2_P, t = 1:T] >= 0) # Storage in the pipe
    # H2PipeFlow refers to the flow into a zone d = +/-1 (aka source(+) --> sink(-))
    @variable(EP, vH2PipeFlow_pos[p = 1:H2_P, t = 1:T, d = [1, -1]] >= 0) # positive pipeflow to zone
    @variable(EP, vH2PipeFlow_neg[p = 1:H2_P, t = 1:T, d = [1, -1]] >= 0) # negative pipeflow to zone

    # Unidirectional pipeline flow constraints. hsc_pipeline inputs file must have 2 pipelines in between each zone for this to work properly (flipping the -1 and +1 directions)
    # Constraints force the source zone to only export H2 through pipeline p while the destination zone can only import
    if setup["H2PipeDirection"] == 1
        @constraint(EP, vH2PipeFlow_pos[p = 1:H2_P, t = 1:T, d = 1] .== 0)
        @constraint(EP, vH2PipeFlow_neg[p = 1:H2_P, t = 1:T, d = -1] .== 0)
    end


    ### Expressions ###
    # Calculate the number of new pipes
    @expression(EP, eH2NPipeNew[p = 1:H2_P], vH2NPipe[p] - inputs["pH2_Pipe_No_Curr"][p])

    # Calculate net flow at each pipe-zone interfrace
    @expression(
        EP,
        eH2PipeFlow_net[p = 1:H2_P, t = 1:T, d = [-1, 1]],
        vH2PipeFlow_pos[p, t, d] - vH2PipeFlow_neg[p, t, d]
    )




    ## Objective Function Expressions ##
    # Capital cost of pipelines 
    # DEV NOTE: To add fixed cost of existing + new pipelines
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCH2Pipe,
            sum(
                eH2NPipeNew[p] * inputs["pCAPEX_H2_Pipe"][p] / (ModelScalingFactor)^2 for
                p = 1:H2_P
            )
        )
    else
        @expression(
            EP,
            eCH2Pipe,
            sum(eH2NPipeNew[p] * inputs["pCAPEX_H2_Pipe"][p] for p = 1:H2_P)
        )
    end

    EP[:eObj] += eCH2Pipe

    # Capital cost of booster compressors located along each pipeline - more booster compressors needed for longer pipelines than shorter pipelines
    # YS Formula doesn't make sense to me
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eCH2CompPipe,
            sum(eH2NPipeNew[p] * inputs["pCAPEX_Comp_H2_Pipe"][p] for p = 1:H2_P) / ModelScalingFactor^2
        )
    else
        @expression(
            EP,
            eCH2CompPipe,
            sum(eH2NPipeNew[p] * inputs["pCAPEX_Comp_H2_Pipe"][p] for p = 1:H2_P)
        )
    end

    EP[:eObj] += eCH2CompPipe

    ## End Objective Function Expressions ##

    ## Balance Expressions ##
    # H2 Power Consumption balance

    if setup["ParameterScale"] == 1 # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
        @expression(
            EP,
            ePowerBalanceH2PipeCompression[t = 1:T, z = 1:Z],
            sum(
                vH2PipeFlow_neg[
                    p, t, H2_Pipe_Map[(H2_Pipe_Map[!, :Zone].==z).&(H2_Pipe_Map[!, :pipe_no].==p), :,][!,:d][1]   # H2_Pipe_Map[(H2_Pipe_Map[!, :Zone].==z).&(H2_Pipe_Map[!, :pipe_no].==p), :,][!,:d][1] explanation: For each zone z and pipeline p, finds the direction of the flow of the pipeline d = +/-1
                ] * inputs["pComp_MWh_per_tonne_Pipe"][p] for p in H2_Pipe_Map[H2_Pipe_Map[!, :Zone].==z, :][!, :pipe_no] # H2_Pipe_Map[H2_Pipe_Map[!, :Zone].==z, :][!, :pipe_no] / explanation: Finds all of the pipelines p that connect to the zone z
            ) / ModelScalingFactor
        )
    else # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of H2 related power consumption
        @expression(
            EP,
            ePowerBalanceH2PipeCompression[t = 1:T, z = 1:Z],
            sum(
                vH2PipeFlow_neg[
                    p, t, H2_Pipe_Map[(H2_Pipe_Map[!, :Zone].==z).&(H2_Pipe_Map[!, :pipe_no].==p), :,][!,:d][1]
                ] * inputs["pComp_MWh_per_tonne_Pipe"][p] for p in H2_Pipe_Map[H2_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
            )
        )
    end

    EP[:ePowerBalance] += -ePowerBalanceH2PipeCompression
    EP[:eH2NetpowerConsumptionByAll] += ePowerBalanceH2PipeCompression


    # H2 balance - net flows of H2 from between z and zz via pipeline p over time period t
    @expression(
        EP,
        ePipeZoneDemand[t = 1:T, z = 1:Z],
        sum(
            eH2PipeFlow_net[p, t, H2_Pipe_Map[(H2_Pipe_Map[!, :Zone].==z).&(H2_Pipe_Map[!, :pipe_no].==p), :][!,:d][1]] 
            for p in H2_Pipe_Map[H2_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
        )
    )

    EP[:eH2Balance] += ePipeZoneDemand

    EP[:eHTransmissionByZone] += ePipeZoneDemand

    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###

    # Constraints
    if setup["H2PipeInteger"] == 1
        for p = 1:H2_P
            set_integer.(vH2NPipe[p])
        end
    end

    # Modeling expansion of the pipleline network
    if setup["H2NetworkExpansion"] == 1
        # If network expansion allowed Total no. of Pipes >= Existing no. of Pipe 
        @constraints(EP, begin
            [p in 1:H2_P], EP[:eH2NPipeNew][p] >= 0
        end)
    else
        # If network expansion is not alllowed Total no. of Pipes == Existing no. of Pipe 
        @constraints(EP, begin
            [p in 1:H2_P], EP[:eH2NPipeNew][p] == 0
        end)
    end

    # Constraint maximum pipe flow
    @constraints(
        EP,
        begin
            [p in 1:H2_P, t = 1:T, d in [-1, 1]],
            EP[:eH2PipeFlow_net][p, t, d] <=
            EP[:vH2NPipe][p] * inputs["pH2_Pipe_Max_Flow"][p]
            [p in 1:H2_P, t = 1:T, d in [-1, 1]],
            -EP[:eH2PipeFlow_net][p, t, d] <=
            EP[:vH2NPipe][p] * inputs["pH2_Pipe_Max_Flow"][p]
        end
    )

    # Constrain positive and negative pipe flows
    @constraints(
        EP,
        begin
            [p in 1:H2_P, t = 1:T, d in [-1, 1]],
            vH2NPipe[p] * inputs["pH2_Pipe_Max_Flow"][p] >= vH2PipeFlow_pos[p, t, d]
            [p in 1:H2_P, t = 1:T, d in [-1, 1]],
            vH2NPipe[p] * inputs["pH2_Pipe_Max_Flow"][p] >= vH2PipeFlow_neg[p, t, d]
        end
    )

    # Minimum and maximum pipe level constraint
    @constraints(
        EP,
        begin
            [p in 1:H2_P, t = 1:T],
            vH2PipeLevel[p, t] >= inputs["pH2_Pipe_Min_Cap"][p] * vH2NPipe[p]
            [p in 1:H2_P, t = 1:T],
            inputs["pH2_Pipe_Max_Cap"][p] * vH2NPipe[p] >= vH2PipeLevel[p, t]
        end
    )

    # Pipeline storage level change
    @constraints(
        EP,
        begin
            [p in 1:H2_P, t in START_SUBPERIODS],
            vH2PipeLevel[p, t] ==
            vH2PipeLevel[p, t+hours_per_subperiod-1] - eH2PipeFlow_net[p, t, -1] -
            eH2PipeFlow_net[p, t, 1]
        end
    )

    @constraints(
        EP,
        begin
            [p in 1:H2_P, t in INTERIOR_SUBPERIODS],
            vH2PipeLevel[p, t] ==
            vH2PipeLevel[p, t-1] - eH2PipeFlow_net[p, t, -1] - eH2PipeFlow_net[p, t, 1]
        end
    )

    @constraints(EP, begin
        [p in 1:H2_P], vH2NPipe[p] <= inputs["pH2_Pipe_No_Max"][p]
    end)

    return EP
end # end H2Pipeline module