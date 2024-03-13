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

This module defines the hydrogen pipeline storage level decision variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$, representing hydrogen stored in pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$.

The variable defined in this file named after ```vH2NPipe``` covers variable $y_{i,z \rightarrow z^{\prime}}^{\textrm{H,PIP}}$.

The variable defined in this file named after ```vH2PipeFlow_pos``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP+}}$.

The variable defined in this file named after ```vH2PipeFlow_neg``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP-}}$.

The variable defined in this file named after ```vH2PipeLevel``` covers variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}}$.

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

    T = inputs["T"]::Int64  # Model operating time steps
    Z = inputs["Z"]::Int64  # Model demand zones - assumed to be same for H2 and electricity
    setup["ParameterScale"]==1 ? SCALING = ModelScalingFactor : SCALING = 1.0

    INTERIOR_SUBPERIODS= inputs["INTERIOR_SUBPERIODS"]::Vector{Int64} 
    START_SUBPERIODS = inputs["START_SUBPERIODS"]::StepRange{Int64, Int64}
    hours_per_subperiod = inputs["hours_per_subperiod"]::Int64

    H2_P = inputs["H2_P"]::Int64 # Number of Hydrogen Pipelines
    H2_Pipe_Map = inputs["H2_Pipe_Map"]::DataFrame

    pH2_Pipe_No_Curr = inputs["pH2_Pipe_No_Curr"]::Vector{Float64}
    pCAPEX_H2_Pipe = inputs["pCAPEX_H2_Pipe"]::Vector{Float64}

    eObj = EP[:eObj]::AffExpr

    ### Variables ###
    @variable(EP, vH2NPipe[p = 1:H2_P] >= 0) # Number of Pipes
    @variable(EP, vH2PipeLevel[p = 1:H2_P, t = 1:T] >= 0) # Storage in the pipe
    @variable(EP, vH2PipeFlow_pos[p = 1:H2_P, t = 1:T, d = [1, -1]] >= 0) # positive pipeflow
    @variable(EP, vH2PipeFlow_neg[p = 1:H2_P, t = 1:T, d = [1, -1]] >= 0) # negative pipeflow

    ### Expressions ###
    # Calculate the number of new pipes
    @expression(EP, eH2NPipeNew[p = 1:H2_P], vH2NPipe[p] - pH2_Pipe_No_Curr[p])

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
    eCH2Pipe = sum_expression(eH2NPipeNew[p] / SCALING^2 * pCAPEX_H2_Pipe[p] for p = 1:H2_P)
    EP[:eCH2Pipe] = eCH2Pipe

    add_to_expression!(eObj, eCH2Pipe)

    # Capital cost of booster compressors located along each pipeline - more booster compressors needed for longer pipelines than shorter pipelines
    # YS Formula doesn't make sense to me
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    eCH2CompPipe = sum_expression(eH2NPipeNew[p] / SCALING^2 * inputs["pCAPEX_Comp_H2_Pipe"][p] for p = 1:H2_P)
    EP[:eCH2CompPipe] = eCH2CompPipe

    add_to_expression!(eObj, eCH2CompPipe)

    ## End Objective Function Expressions ##

    ## Balance Expressions ##
    # H2 Power Consumption balance

    # Power consumption of booster compressors located along each pipeline
    
    powerBalanceH2PipeCompression(T, Z, vH2PipeFlow_neg, H2_Pipe_Map, inputs, SCALING, EP)

    # H2 balance - net flows of H2 from between z and zz via pipeline p over time period t

    pipeZoneDemand(T, Z, eH2PipeFlow_net, H2_Pipe_Map, EP)

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
    H2NetworkExpansion = setup["H2NetworkExpansion"]::Int64
    if H2NetworkExpansion == 1
        # If network expansion allowed Total no. of Pipes >= Existing no. of Pipe 
        @constraints(EP, begin
            [p in 1:H2_P], eH2NPipeNew[p] >= 0
        end)
    else
        # If network expansion is not alllowed Total no. of Pipes == Existing no. of Pipe 
        @constraints(EP, begin
            [p in 1:H2_P], eH2NPipeNew[p] == 0
        end)
    end

    pH2_Pipe_No_Max = inputs["pH2_Pipe_No_Max"]::Vector{Float64}
    # Constraint maximum pipe flow
    @constraints(
        EP,
        begin
            [p in 1:H2_P, t = 1:T, d in [-1, 1]], eH2PipeFlow_net[p, t, d] <= vH2NPipe[p] * pH2_Pipe_No_Max[p]
            [p in 1:H2_P, t = 1:T, d in [-1, 1]], -eH2PipeFlow_net[p, t, d] <= vH2NPipe[p] * pH2_Pipe_No_Max[p]
        end
    )

    # Constrain positive and negative pipe flows
    @constraints(
        EP,
        begin
            [p in 1:H2_P, t = 1:T, d in [-1, 1]], vH2NPipe[p] * pH2_Pipe_No_Max[p] >= vH2PipeFlow_pos[p, t, d]
            [p in 1:H2_P, t = 1:T, d in [-1, 1]], vH2NPipe[p] * pH2_Pipe_No_Max[p] >= vH2PipeFlow_neg[p, t, d]
        end
    )

    pH2_Pipe_Min_Cap = inputs["pH2_Pipe_Min_Cap"]::Vector{Float64}
    pH2_Pipe_Max_Cap = inputs["pH2_Pipe_Max_Cap"]::Vector{Float64}
    # Minimum and maximum pipe level constraint
    @constraints(
        EP,
        begin
            [p in 1:H2_P, t = 1:T], vH2PipeLevel[p, t] >= pH2_Pipe_Min_Cap[p] * vH2NPipe[p]
            [p in 1:H2_P, t = 1:T], pH2_Pipe_Max_Cap[p] * vH2NPipe[p] >= vH2PipeLevel[p, t]
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
        [p in 1:H2_P], vH2NPipe[p] <= pH2_Pipe_No_Max[p]
    end)

    return EP
end # end H2Pipeline module

function powerBalanceH2PipeCompression(T::Int64, Z::Int64, vH2PipeFlow_neg::AbstractArray{VariableRef}, H2_Pipe_Map::DataFrame, inputs::Dict, ModelScalingFactor::Float64, EP::Model) 
    ePowerBalanceH2PipeCompression = create_empty_expression((T, Z))

    pipe_zones = H2_Pipe_Map[!, :Zone]::Vector{Float64}
    pipe_numbers = H2_Pipe_Map[!, :pipe_no]::Vector{Int64}
    pipe_d = H2_Pipe_Map[!, :d]::Vector{Int64}
    pComp_MWh_per_tonne_Pipe = inputs["pComp_MWh_per_tonne_Pipe"]::Vector{Float64}

    @inbounds for z = 1:Z
        active_zones = pipe_zones.==z
        @inbounds for t = 1:T
            ePowerBalanceH2PipeCompression[t,z] = sum_expression(
                vH2PipeFlow_neg[p, t, pipe_d[active_zones.&(pipe_numbers.==p), :,][1]] * pComp_MWh_per_tonne_Pipe[p] / ModelScalingFactor 
                for p in pipe_numbers[active_zones]
            )
        end
    end 

    EP[:ePowerBalanceH2PipeCompression] = ePowerBalanceH2PipeCompression
    add_similar_to_expression!(EP[:ePowerBalance], -ePowerBalanceH2PipeCompression)
    add_similar_to_expression!(EP[:eH2NetpowerConsumptionByAll], ePowerBalanceH2PipeCompression)

    return ePowerBalanceH2PipeCompression
end

function pipeZoneDemand(T::Int64, Z::Int64, eH2PipeFlow_net::AbstractArray{AffExpr}, H2_Pipe_Map::DataFrame, EP::Model)
    ePipeZoneDemand = create_empty_expression((T, Z))

    pipe_zones = H2_Pipe_Map[!, :Zone]::Vector{Float64}
    pipe_numbers = H2_Pipe_Map[!, :pipe_no]::Vector{Int64}
    pipe_d = H2_Pipe_Map[!, :d]::Vector{Int64}

    @inbounds for z = 1:Z
        active_zones = pipe_zones.==z
        @inbounds for t = 1:T
            ePipeZoneDemand[t,z] = sum_expression(
                eH2PipeFlow_net[p, t, pipe_d[active_zones.&(pipe_numbers.==p), :,][1]] for p in pipe_numbers[active_zones]
            )
        end
    end 

    EP[:ePipeZoneDemand] = ePipeZoneDemand

    ## Timing and memory tests:
    # median, mean - allocations

    # 365, 362 - 5395169
    add_similar_to_expression!(EP[:eH2Balance], ePipeZoneDemand)
    add_similar_to_expression!(EP[:eH2TransmissionByZone], ePipeZoneDemand)

    # 371, 379 - 5395169
    # add_similar_to_expression!(EP[:eH2Balance]::Array{AffExpr,2}, ePipeZoneDemand)
    # add_similar_to_expression!(EP[:eH2TransmissionByZone]::Array{AffExpr,2}, ePipeZoneDemand)

    # 361, 358 - 5395175
    # add_to_expression!.(EP[:eH2Balance], ePipeZoneDemand)
    # add_to_expression!.(EP[:eH2TransmissionByZone], ePipeZoneDemand)

    # 372, 373 - 5395171
    # add_to_expression!.(EP[:eH2Balance]::Array{AffExpr,2}, ePipeZoneDemand)
    # add_to_expression!.(EP[:eH2TransmissionByZone]::Array{AffExpr,2}, ePipeZoneDemand)

    # 366, 363 - 5395169 
    # eH2Balance = EP[:eH2Balance]::Array{AffExpr,2}
    # eH2TransmissionByZone = EP[:eH2TransmissionByZone]::Array{AffExpr,2}
    # add_similar_to_expression!(eH2Balance, ePipeZoneDemand)
    # add_similar_to_expression!(eH2TransmissionByZone, ePipeZoneDemand)

    # 370, 370 - 5395171
    # eH2Balance = EP[:eH2Balance]::Array{AffExpr,2}
    # eH2TransmissionByZone = EP[:eH2TransmissionByZone]::Array{AffExpr,2}
    # add_to_expression!.(eH2Balance, ePipeZoneDemand)
    # add_to_expression!.(eH2TransmissionByZone, ePipeZoneDemand)

    return eH2PipeFlow_net
end