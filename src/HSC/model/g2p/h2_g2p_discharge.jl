

@doc raw"""
    h2_g2p_discharge(EP::Model, inputs::Dict, setup::Dict)

This module defines the power generation decision variable $x_{k,z,t}^{\textrm{H,G2P}} \forall k \in \mathcal{K}, z\in \mathcal{Z}, t \in \mathcal{T}$, representing energy injected into the grid by hydrogen to power resource $k$ in zone $z$ at time period $t$.

The variable defined in this file named after ```vP``` covers all variables $x_{k,z,t}^{\textrm{E,THE}}, x_{r,z,t}^{\textrm{E,VRE}}, x_{s,z,t}^{\textrm{E,DIS}}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable O&M plus fuel cost) from all generation resources $g \in \mathcal{G}$ (thermal, renewable, storage, DR, flexible demand resources and hydro) over all time periods $t \in \mathcal{T}$:

```math
\begin{equation*}
    \textrm{C}^{\textrm{H,G2P,o}} = \sum_{g \in \mathcal{G}} \sum_{t \in \mathcal{T}} \omega_t \times \left(\textrm{c}_{g}^{\textrm{H,VOM}} + \textrm{c}_{g}^{\textrm{H,FUEL}}\right) \times x_{g,z,t}^{\textrm{H,G2P}}
\end{equation*}
```
"""
function h2_g2p_discharge(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("H2 g2p demand module")

    dfH2G2P = inputs["dfH2G2P"]::DataFrame

    # Define sets
    H = inputs["H2_G2P_ALL"]::Int #Number of Hydrogen gen units
    T = inputs["T"]::Int     # Number of time steps (hours)

    SCALING = setup["scaling"]::Float64

    ### Variables ###

    #Electricity Discharge from hydrogen G2P resource k (MWh) in time t
    @variable(EP, vPG2P[k=1:H, t = 1:T] >= 0)

    ### Expressions ###

    ## Objective Function Expressions ##

    # Variable costs of "generation" for resource "y" during hour "t" = variable O&M plus fuel cost

    #  ParameterScale = 1 --> objective function is in million $ . 
    ## In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
    ## Fue cost already scaled by 1000 in load_fuels_data.jl sheet, so  need to scale variable OM cost component by million and fuel cost component by 1000 here.
    #  ParameterScale = 0 --> objective function is in $
    @expression(EP, eCH2G2PVar_out[k = 1:H,t = 1:T], 
    inputs["omega"][t] * (dfH2G2P[!,:Var_OM_Cost_p_MWh][k] / SCALING^2) * vPG2P[k,t])

    @expression(EP, eTotalCH2G2PVarOutT[t=1:T], sum(eCH2G2PVar_out[k,t] for k in 1:H))
    @expression(EP, eTotalCH2G2PVarOut, sum(eTotalCH2G2PVarOutT[t] for t in 1:T))
    
    # Add total variable discharging cost contribution to the objective function
    add_similar_to_expression!(EP[:eObj], eTotalCH2G2PVarOut)

    return EP

end
