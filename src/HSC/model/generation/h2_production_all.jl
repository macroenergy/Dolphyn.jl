

@doc raw"""
    h2_production_all(EP::Model, inputs::Dict, setup::Dict)

The h2 generation module creates decision variables, expressions, and constraints related to hydrogen generation infrastructure. 
Hydrogen generation expressions are also applied to liquefiers and evaporators. 

This module defines the power consumption decision variable $x_{z,t}^{\textrm{E,H-GEN}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$, representing power consumed by electrolyzers in zone $z$ at time period $t$.

The variable defined in this file named after ```vP2G``` cover variable $x_{z,t}^{E,H-GEN}$.

**Constraints on hydrogen generation capacity**

One cannot retire more capacity than existing capacity.
```math
\begin{equation*}
    0 \leq y_{g}^{\textrm{H,GEN,retired}} \leq y_{g}^{\textrm{H,GEN,existing}} \quad \forall g \in \mathcal{G}
\end{equation*}
```

For resources where upper bound $\overline{y_{g}^{\textrm{H,GEN}}}$ and lower bound $\underline{y_{g}^{\textrm{H,GEN}}}$ of capacity is defined, then we impose constraints on minimum and maximum generation capacity.

```math
\begin{equation*}
    \underline{y_{g}^{\textrm{H,GEN}}} \leq y_{g}^{\textrm{H,GEN}} \leq \overline{y_{g}^{\textrm{H,GEN}}} \quad \forall g \in \mathcal{G}
\end{equation*}
```
"""
function h2_production_all(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("H2 Production Core Module")
    
    dfH2Gen = inputs["dfH2Gen"]::DataFrame

    #Define sets
    if setup["ModelH2Liquid"] ==1
        H2_GEN_NO_COMMIT= union(inputs["H2_GEN_NO_COMMIT"], inputs["H2_LIQ_NO_COMMIT"], inputs["H2_EVAP_NO_COMMIT"])
        H2_GEN_COMMIT = union(inputs["H2_GEN_COMMIT"], inputs["H2_LIQ_COMMIT"], inputs["H2_EVAP_COMMIT"])
        H2_GEN = union(inputs["H2_GEN"], inputs["H2_LIQ"], inputs["H2_EVAP"])
    else
        H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]::Vector{<:Int}
        H2_GEN_NO_COMMIT = inputs["H2_GEN_NO_COMMIT"]
        H2_GEN = inputs["H2_GEN"]::Vector{<:Int}    
    end
    H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"]
    H =inputs["H2_RES_ALL"]::Int

    T = inputs["T"]::Int     # Number of time steps (hours)

    ####Variables####
    #Define variables needed across both commit and no commit sets

    #Power required by hydrogen generation resource k to make hydrogen (MW)
    @variable(EP, vP2G[k in H2_GEN, t = 1:T] >= 0 )

    ### Constratints ###

    ## Constraints on retirements and capacity additions
    # Cannot retire more capacity than existing capacity
    @constraint(EP, cH2GenMaxRetNoCommit[k in setdiff(H2_GEN_RET_CAP, H2_GEN_NO_COMMIT)], EP[:vH2GenRetCap][k] <= dfH2Gen[!,:Existing_Cap_tonne_p_hr][k])
    @constraint(EP, cH2GenMaxRetCommit[k in intersect(H2_GEN_RET_CAP, H2_GEN_COMMIT)], dfH2Gen[!,:Cap_Size_tonne_p_hr][k] * EP[:vH2GenRetCap][k] <= dfH2Gen[!,:Existing_Cap_tonne_p_hr][k])

    ## Constraints on new built capacity
    # Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
    @constraint(EP, cH2GenMaxCap[k in intersect(dfH2Gen[dfH2Gen.Max_Cap_tonne_p_hr.>0,:R_ID], 1:H)],EP[:eH2GenTotalCap][k] <= dfH2Gen[!,:Max_Cap_tonne_p_hr][k])

    # Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is <= Min_Cap_MW and lead to infeasabilty
    @constraint(EP, cH2GenMinCap[k in intersect(dfH2Gen[dfH2Gen.Min_Cap_tonne_p_hr.>0,:R_ID], 1:H)], EP[:eH2GenTotalCap][k] >= dfH2Gen[!,:Min_Cap_tonne_p_hr][k])

    return EP

end