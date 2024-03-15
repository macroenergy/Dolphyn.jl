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
    h2_production_commit(EP::Model, inputs::Dict, setup::Dict)

This function defines the operating constraints for thermal hydrogen generation plants subject to unit commitment constraints on hydrogen plant start-ups and shut-down decision ($g \in \mathcal{UC}$).

**Hydrogen balance expression**

Contributions to the hydrogen balance expression from each thermal resources with unit commitment $g \in \mathcal{UC}$ are also defined as below. If liquid hydrogen is modeled, a liquid hydrogen balance expression is needed and contributions to the gas balance are accounted for. 

```math
\begin{equation*}
    HydrogenBalGas_{GEN} = \sum_{g \in \mathcal{UC}} x_{g,z,t}^{\textrm{H,GEN}} - \sum_{g \in \mathcal{UC}} x_{g,z,t}^{\textrm{H,LIQ}} + \sum_{g \in \mathcal{UC}} x_{g,z,t}^{\textrm{H,EVAP}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    HydrogenBalLiq_{GEN} = \sum_{g \in \mathcal{UC}} x_{g,z,t}^{\textrm{H,LIQ}} - \sum_{g \in \mathcal{UC}} x_{g,z,t}^{\textrm{H,EVAP}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

**Startup and shutdown events (thermal plant cycling)**

*Capacity limits on unit commitment decision variables*

Thermal resources subject to unit commitment ($k \in \mathcal{UC}$) adhere to the following constraints on commitment states, startup events, and shutdown events, which limit each decision to be no greater than the maximum number of discrete units installed (as per the following three constraints):

```math
\begin{equation*}
    n_{g,z,t}^{\textrm{H,GEN}} \leq \frac{y_{g,z}^{\textrm{H,GEN}}}{\Omega_{g,z}^{\textrm{H,GEN,size}}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    n_{g,z,t}^{\textrm{H,UP}} \leq \frac{y_{g,z}^{\textrm{H,GEN}}}{\Omega_{g,z}^{\textrm{H,GEN,size}}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    n_{g,z,t}^{\textrm{H,DN}} \leq \frac{y_{g,z}^{\textrm{H,GEN}}}{\Omega_{g,z}^{\textrm{H,GEN,size}}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
where decision $n_{g,z,t}^{\textrm{H,GEN}}$ designates the commitment state of generator cluster $g$ in zone $z$ at time $t$, 
decision $n_{g,z,t}^{\textrm{H,UP}}$ represents number of startup decisions, 
decision $n_{g,z,t}^{\textrm{H,DN}}$ represents number of shutdown decisions, 
$y_{g,z}^{\textrm{H,GEN}}$ is the total installed capacity, and parameter $\Omega_{g,z}^{\textrm{H,GEN},size}$ is the unit size.
(See Constraints 1-3 in the code)

*Commitment state constraint linking start-up and shut-down decisions*

Additionally, the following constarint maintains the commitment state variable across time, 
$n_{g,z,t}^{\textrm{H,GEN}}$, as the sum of the commitment state in the prior, $n_{g,z,t-1}^{\textrm{H,GEN}}$, 
period plus the number of units started in the current period, $n_{g,z,t}^{H,UP}$, 
minus the number of units shut down in the current period, $n_{g,z,t}^{H,DN}$:

```math
\begin{aligned}
    n_{g,z,t}^{\textrm{H,GEN}} &= n_{g,z,t-1}^{\textrm{H,GEN}} + n_{g,z,t}^{\textrm{H,UP}} - n_{g,z,t}^{\textrm{H,DN}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}^{interior} \\
    n_{g,z,t}^{\textrm{H,GEN}} &= n_{g,z,t +\tau^{period}-1}^{\textrm{H,GEN}} + n_{g,z,t}^{\textrm{H,UP}} - n_{g,z,t}^{\textrm{H,DN}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}^{start}
\end{aligned}
```
(See Constraint 4 in the code)

Like other time-coupling constraints, this constraint wraps around to link the commitment state in the first time step of the year (or each representative period), $t \in \mathcal{T}^{start}$, to the last time step of the year (or each representative period), $t+\tau^{period}-1$.

**Ramping constraints**

Thermal resources subject to unit commitment ($k \in \mathcal{UC}$) adhere to the following ramping constraints on hourly changes in power output:

```math
\begin{aligned}
    x_{g,z,t-1}^{\textrm{H,GEN}} - x_{g,z,t}^{\textrm{H,GEN}} &\leq \kappa_{g,z}^{\textrm{H,DN}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times \left(n_{g,z,t}^{\textrm{H,UP}} - n_{g,z,t}^{\textrm{H,DN}}\right) \\
    \qquad &- \underline{\rho_{g,z,t}^{\textrm{H,GEN}}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,DN}} \\
    \qquad &+ \text{min}(\overline{\rho_{g,z,t}^{\textrm{H,GEN}}}}, \text{max}(\underline{\rho_{g,z,t}^{\textrm{H,GEN}}}, \kappa_{g,z}^{\textrm{H,GEN}})) \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,DN}} \\
    \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T} 
\end{aligned}
```

```math
\begin{aligned}
    x_{g,z,t}^{\textrm{H,GEN}} - x_{g,z,t-1}^{\textrm{H,GEN}} &\leq \kappa_{g,z}^{\textrm{H,UP}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times \left(n_{g,z,t}^{\textrm{H,UP}} - n_{g,z,t}^{\textrm{H,DN}}\right) \\
    \qquad &+ \text{min}(\overline{\rho_{g,z,t}^{\textrm{H,GEN}}}, \text{max}(\underline{\rho_{g,z,t}^{\textrm{H,GEN}}}, \kappa_{k,z}^{\textrm{H,UP}})) \times \Omega_{k,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,DN}} \\
    \qquad &- \underline{\rho_{g,z,t}^{\textrm{H,GEN}}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,DN}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
(See Constraints 5-6 in the code)

where decision $x_{g,z,t}^{\textrm{H,GEN}}$ is the energy injected into the grid by technology $y$ in zone $z$ at time $t$, parameter $\kappa_{g,z,t}^{\textrm{H,UP}}$, $\kappa_{G,z,t}^{\textrm{H,DN}}$ is the maximum ramp-up or ramp-down rate as a percentage of installed capacity, parameter $\underline{\rho_{g,z}^{\textrm{H,GEN}}}$ is the minimum stable power output per unit of installed capacity, 
and parameter $\overline{\rho_{g,z,t}^{\textrm{H,GEN}}}$ is the maximum available generation per unit of installed capacity. These constraints account for the ramping limits for committed (online) units as well as faster changes in power enabled by units starting or shutting down in the current time step.

```math
\begin{equation*}
    x_{g,z,t}^{\textrm{H,GEN}} \geq \underline{\rho_{g,z,t}^{\textrm{H,GEN}}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,UP}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    x_{g,z,t}^{\textrm{H,GEN}} \geq \overline{\rho_{g,z}^{\textrm{H,GEN}}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,UP}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

(See Constraints 7-8 the code)

**Minimum and maximum up and down time**

Thermal resources subject to unit commitment adhere to the following constraints on the minimum time steps after start-up before a unit can shutdown again (minimum up time) and the minimum time steps after shut-down before a unit can start-up again (minimum down time):

```math
\begin{equation*}
    n_{g,z,t}^{\textrm{H,GEN}} \geq \displaystyle \sum_{\tau = t-\tau_{g,z}^{\textrm{H,UP}}}^t n_{g,z,\tau}^{\textrm{H,UP}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    \frac{y_{g,z}^{\textrm{H,GEN}}}{\Omega_{g,z}^{\textrm{H,GEN,size}}} - n_{g,z,t}^{\textrm{H,UP}} \geq \displaystyle \sum_{\tau = t-\tau_{g,z}^{\textrm{H,DN}}}^t n_{g,z,\tau}^{\textrm{H,DN}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
(See Constraints 9-10 in the code)

where $\tau_{g,z}^{\textrm{H,UP}}$ and $\tau_{g,z}^{\textrm{H,DN}}$ is the minimum up or down time for units in generating cluster $g$ in zone $z$.

Like with the ramping constraints, the minimum up and down constraint time also wrap around from the start of each time period to the end of each period.
It is recommended that users of DOLPHYN must use longer subperiods than the longest min up/down time if modeling unit commitment. Otherwise, the model will report error.
"""
function h2_production_commit(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("H2 Production (Unit Commitment) Module")
    
    # Rename H2Gen dataframe
    dfH2Gen = inputs["dfH2Gen"]
    H2GenCommit = setup["H2GenCommit"]

    T = inputs["T"]::Int64     # Number of time steps (hours)
    Z = inputs["Z"]::Int64     # Number of zones
    H = inputs["H2_GEN"]::Vector{Int64}     # NUmber of hydrogen generation units 

    H2_GAS_COMMIT = inputs["H2_GEN_COMMIT"]::Vector{Int64} #This is needed only for H2 balance

    if setup["ModelH2Liquid"]==1
        H2_LIQ_COMMIT = inputs["H2_LIQ_COMMIT"]::Vector{Int64} 
        H2_EVAP_COMMIT = inputs["H2_EVAP_COMMIT"]::Vector{Int64} 
        H2_GEN_COMMIT = union(H2_LIQ_COMMIT, H2_GAS_COMMIT, H2_EVAP_COMMIT) #liquefiers are treated at generators, all the same expressions & contraints apply, except for H2 balance
    else
        H2_GEN_COMMIT = H2_GAS_COMMIT
    end
    # H2_GEN_NEW_CAP = inputs["H2_GEN_NEW_CAP"]
    # H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"] 
    
    #Define start subperiods and interior subperiods
    START_SUBPERIODS = inputs["START_SUBPERIODS"]::StepRange{Int64,Int64} 
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]::Vector{Int64} 
    hours_per_subperiod = inputs["hours_per_subperiod"]::Int64  #total number of hours per subperiod

    setup["ParameterScale"]==1 ? SCALING = ModelScalingFactor : SCALING = 1.0

    ###Variables###

    # commitment state variable
    @variable(EP, vH2GenCOMMIT[k in H2_GEN_COMMIT, t=1:T] >= 0)
    # Start up variable
    @variable(EP, vH2GenStart[k in H2_GEN_COMMIT, t=1:T] >= 0)
    # Shutdown Variable
    @variable(EP, vH2GenShut[k in H2_GEN_COMMIT, t=1:T] >= 0)

    ###Expressions###

    #Objective function expressions
    # Startup costs of "generation" for resource "y" during hour "t"
    h2_prod_commit_startup_costs!(EP, T, vH2GenStart, H2_GEN_COMMIT, inputs["C_H2_Start"], inputs["omega"], SCALING)

    #H2 Balance expressions
    eH2GenCommit = h2_prod_commit_h2_balance!(EP, T, Z, EP[:vH2Gen], dfH2Gen, H2_GEN_COMMIT)

    if setup["ModelH2Liquid"]==1
        #H2 LIQUID Balance expressions
        eH2GenLiqCommit = h2_prod_commit_h2_liq_balance!(EP, T, Z, EP[:vH2Gen], dfH2Gen, H2_LIQ_COMMIT)

        #H2 EVAPORATION Balance expressions
        if !isempty(H2_EVAP_COMMIT)
            eH2EvapCommit = h2_prod_commit_h2_evap_balance!(EP, T, Z, EP[:vH2Gen], dfH2Gen, H2_LIQ_COMMIT)
        end
    end

    #Power Consumption for H2 Generation
    ePowerBalanceH2GenCommit = h2_prod_commit_power_consumption!(EP, T, Z, dfH2Gen, H2_GEN_COMMIT, SCALING)

    ### Constraints ###
    ## Declaration of integer/binary variables
    if H2GenCommit == 1 # Integer UC constraints
        h2_prod_set_integer_opVar(EP)
        h2_prod_set_integer_invVar(EP)
    end #END unit commitment configuration

    ###Constraints###
    @constraints(EP, begin
        #Power Balance
        [k in H2_GEN_COMMIT, t = 1:T], EP[:vP2G][k,t] == EP[:vH2Gen][k,t] * dfH2Gen[!,:etaP2G_MWh_p_tonne][k]
    end)

    ### Capacitated limits on unit commitment decision variables (Constraints #1-3)
    @constraints(EP, begin
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenCOMMIT][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size_tonne_p_hr][k]
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenStart][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size_tonne_p_hr][k]
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenShut][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size_tonne_p_hr][k]
    end)

    # Commitment state constraint linking startup and shutdown decisions (Constraint #4)
    @constraints(EP, begin
        # For Start Hours, links first time step with last time step in subperiod
        [k in H2_GEN_COMMIT, t in START_SUBPERIODS], EP[:vH2GenCOMMIT][k,t] == EP[:vH2GenCOMMIT][k,(t+hours_per_subperiod-1)] + EP[:vH2GenStart][k,t] - EP[:vH2GenShut][k,t]
        # For all other hours, links commitment state in hour t with commitment state in prior hour + sum of start up and shut down in current hour
        [k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2GenCOMMIT][k,t] == EP[:vH2GenCOMMIT][k,t-1] + EP[:vH2GenStart][k,t] - EP[:vH2GenShut][k,t]
    end)

    ### Maximum ramp up and down between consecutive hours (Constraints #5-6)
    
    ramp_up_cap, min_output, max_min_up, max_min_up_start = prep_ramp_limits(dfH2Gen, dfH2Gen[!,:Ramp_Up_Percentage], inputs["pH2_Max"], H2_GEN_COMMIT, START_SUBPERIODS, INTERIOR_SUBPERIODS)
    ramp_down_cap, min_output, max_min_down, max_min_down_start = prep_ramp_limits(dfH2Gen, dfH2Gen[!,:Ramp_Up_Percentage], inputs["pH2_Max"], H2_GEN_COMMIT, START_SUBPERIODS, INTERIOR_SUBPERIODS)

    ## For Start Hours
    # Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
    # rampup constraints
    h2_prod_commit_ramp_up!(EP, EP[:vH2Gen], EP[:vH2GenCOMMIT], EP[:vH2GenStart], EP[:vH2GenShut], H2_GEN_COMMIT, START_SUBPERIODS, ramp_up_cap, min_output, max_min_up_start, hours_per_subperiod)

    # rampdown constraints
    h2_prod_commit_ramp_down!(EP, EP[:vH2Gen], EP[:vH2GenCOMMIT], EP[:vH2GenStart], EP[:vH2GenShut], H2_GEN_COMMIT, START_SUBPERIODS, ramp_down_cap, min_output, max_min_down_start, hours_per_subperiod)

    ## For Interior Hours
    # rampup constraints
    h2_prod_commit_ramp_up!(EP, EP[:vH2Gen], EP[:vH2GenCOMMIT], EP[:vH2GenStart], EP[:vH2GenShut], H2_GEN_COMMIT, INTERIOR_SUBPERIODS, ramp_up_cap, min_output, max_min_up, 0)

    # rampdown constraints
    h2_prod_commit_ramp_down!(EP, EP[:vH2Gen], EP[:vH2GenCOMMIT], EP[:vH2GenStart], EP[:vH2GenShut], H2_GEN_COMMIT, INTERIOR_SUBPERIODS, ramp_down_cap, min_output, max_min_down, 0)

    @constraints(EP, begin
        # Minimum stable generated per technology "k" at hour "t" > = Min stable output level
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2Gen][k,t] >= dfH2Gen[!,:Cap_Size_tonne_p_hr][k] *dfH2Gen[!,:H2Gen_min_output][k]* EP[:vH2GenCOMMIT][k,t]
        # Maximum power generated per technology "k" at hour "t" < Max power
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2Gen][k,t] <= dfH2Gen[!,:Cap_Size_tonne_p_hr][k] * EP[:vH2GenCOMMIT][k,t] * inputs["pH2_Max"][k,t]
    end)

    ### Minimum up and down times (Constraints #9-10)
    h2_prod_commit_uptime!(EP, T, dfH2Gen, H2_GEN_COMMIT, START_SUBPERIODS, INTERIOR_SUBPERIODS, hours_per_subperiod)
    h2_prod_commit_downtime!(EP, T, dfH2Gen, H2_GEN_COMMIT, START_SUBPERIODS, INTERIOR_SUBPERIODS, hours_per_subperiod)

    return EP

end

function h2_prod_set_integer_opVar(EP::Model)
    set_opVar_integer(
        EP[:vH2GenCOMMIT][H2_GEN_COMMIT,:],
        EP[:vH2GenStart][H2_GEN_COMMIT,:],
        EP[:vH2GenShut][H2_GEN_COMMIT,:]
    )
end

function h2_prod_set_integer_invVar(EP::Model)
    set_invVar_integer(
        EP[:vH2GenCOMMIT][intersect(H2_GEN_COMMIT,vH2GenRetCap),:],
        EP[:vH2GenStart][intersect(H2_GEN_COMMIT,vH2GenNewCap),:],
    )
end

function h2_prod_commit_startup_costs!(EP::Model, T::Int, vH2GenStart::AbstractArray{VariableRef}, H2_GEN_COMMIT::Array{Int64,1}, C_H2_Start::Array{Float64,1}, omega::Array{Float64,1}, scaling::Float64=1.0)
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    @expression(
        EP, 
        eH2GenCStart[k in H2_GEN_COMMIT, t=1:T],
        omega[t] * C_H2_Start[k] * vH2GenStart[k,t] / scaling^2
    )
    eTotalH2GenCStart = sum_expression(eH2GenCStart)
    EP[:eTotalH2GenCStart] = eTotalH2GenCStart
    add_similar_to_expression!(EP[:eObj], eTotalH2GenCStart)
end


function h2_prod_commit_h2_balance!(EP::Model, T::Int, Z::Int, vH2Gen::AbstractArray{VariableRef}, dfH2Gen::DataFrame, H2_GAS_COMMIT::Array{Int64,1})
    eH2GenCommit = create_empty_expression((T,Z))
    @inbounds for z = 1:Z
        zone_set = intersect(H2_GAS_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])
        @inbounds for t = 1:T
            eH2GenCommit[t,z] = sum_expression(vH2Gen[zone_set,t])
        end
    end
    EP[:eH2GenCommit] = eH2GenCommit
    add_similar_to_expression!(EP[:eH2Balance], eH2GenCommit)
    return eH2GenCommit
end

function h2_prod_commit_h2_liq_balance!(EP::Model, T::Int, Z::Int, vH2Gen::AbstractArray{VariableRef}, dfH2Gen::DataFrame, H2_LIQ_COMMIT::Array{Int64,1})
    eH2LiqCommit = create_empty_expression((T,Z))
    @inbounds for z = 1:Z
        zone_set = intersect(H2_LIQ_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])
        @inbounds for t = 1:T
            eH2LiqCommit[t,z] = sum_expression(vH2Gen[zone_set,t])
        end
    end
    EP[:eH2LiqCommit] = eH2LiqCommit
    # Add Liquid H2 to liquid balance, AND REMOVE it from the gas balance
    add_similar_to_expression!(EP[:eH2Balance], -eH2LiqCommit)
    add_similar_to_expression!(EP[:eH2LiqBalance], eH2LiqCommit)
    return eH2LiqCommit
end

function h2_prod_commit_h2_evap_balance!(EP::Model, T::Int, Z::Int, vH2Gen::AbstractArray{VariableRef}, dfH2Gen::DataFrame, H2_EVAP_COMMIT::Array{Int64,1})
    eH2EvapCommit = create_empty_expression((T,Z))
    @inbounds for z = 1:Z
        zone_set = intersect(H2_EVAP_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])
        @inbounds for t = 1:T
            eH2EvapCommit[t,z] = sum_expression(vH2Gen[zone_set,t])
        end
    end
    EP[:eH2EvapCommit] = eH2EvapCommit
    # Add evaporated H2 to gas balance, AND REMOVE it from the liquid balance
    add_similar_to_expression!(EP[:eH2Balance], eH2EvapCommit)
    add_similar_to_expression!(EP[:eH2LiqBalance], -eH2EvapCommit)
    return eH2EvapCommit
end

function calc_ePowerBalanceH2GenCommit(T::Int, Z::Int, vP2G::AbstractArray{VariableRef},  dfH2Gen::DataFrame, H2_GEN_COMMIT::Array{Int64,1}, scaling::Float64=1.0)
    ePowerBalanceH2GenCommit = create_empty_expression((T,Z))
    @inbounds for z = 1:Z
        zone_set = intersect(H2_GEN_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])
        @inbounds for t = 1:T
            ePowerBalanceH2GenCommit[t,z] = sum_expression(vP2G[zone_set,t] / scaling)
        end
    end
    return ePowerBalanceH2GenCommit
end

function h2_prod_commit_power_consumption!(EP::Model, T::Int, Z::Int, dfH2Gen::DataFrame, H2_GEN_COMMIT::Array{Int64,1}, scaling::Float64=1.0)
    # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
    # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of H2 related power consumption
    ePowerBalanceH2GenCommit = calc_ePowerBalanceH2GenCommit(T, Z, EP[:vP2G], dfH2Gen, H2_GEN_COMMIT, scaling)

    add_similar_to_expression!(EP[:ePowerBalance], -ePowerBalanceH2GenCommit)

    ##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
    add_similar_to_expression!(EP[:eH2NetpowerConsumptionByAll], ePowerBalanceH2GenCommit)

    return ePowerBalanceH2GenCommit
end

function h2_prod_commit_uptime!(EP::Model, T::Int, dfH2Gen::DataFrame, H2_GEN_COMMIT::Array{Int64,1}, START_SUBPERIODS::StepRange{Int64, Int64}, INTERIOR_SUBPERIODS::Array{Int64,1}, hours_per_subperiod::Int64)

    up_time_arr = Dict{Int64,Int64}()
    up_time_HOURS_arr = Dict{Int64,Vector{Int64}}()
    @inbounds for y in H2_GEN_COMMIT
        up_time = Int(floor(dfH2Gen[!,:Up_Time][y]))
        up_time_arr[y] = up_time
        up_time_HOURS = Int64[] # Set of hours in the summation term of the maximum up time constraint for the first subperiod of each representative period
        for s in START_SUBPERIODS
            up_time_HOURS = union(up_time_HOURS, (s+1):(s+up_time-1))
        end
        up_time_HOURS_arr[y] = up_time_HOURS
    end

    @inbounds for t in 1:T
        @inbounds for y in H2_GEN_COMMIT
            ## up time
            up_time = up_time_arr[y]
            up_time_HOURS = up_time_HOURS_arr[y]

            # cUpTimeInterior: Constraint looks back over last n hours, where n = dfH2Gen[!,:Up_Time][y]
            if t in setdiff(INTERIOR_SUBPERIODS,up_time_HOURS)
                h2_prod_commit_uptime_interior!(EP, y, t, EP[:vH2GenCOMMIT][y,t], EP[:vH2GenStart], up_time)
            end
            # cUpTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
            if t in up_time_HOURS
                h2_prod_commit_uptime_wrap!(EP, y, t, EP[:vH2GenCOMMIT][y,t], EP[:vH2GenStart], up_time, hours_per_subperiod)
            end
            # cUpTimeStart:
            if t in START_SUBPERIODS
                h2_prod_commit_uptime_start!(EP, y, t, EP[:vH2GenCOMMIT][y,t], EP[:vH2GenStart], up_time, hours_per_subperiod)
            end
        end
    end
end

function h2_prod_commit_uptime_interior!(EP::Model, y::Int, t::Int, vH2GenCOMMIT_yt::VariableRef, vH2GenStart::AbstractArray{VariableRef}, up_time::Int)
    @constraint(EP, vH2GenCOMMIT_yt >= sum_expression(vH2GenStart[y,(t-up_time):t]))
    return nothing
end

function h2_prod_commit_uptime_wrap!(EP::Model, y::Int, t::Int, vH2GenCOMMIT_yt::VariableRef, vH2GenStart::AbstractArray{VariableRef}, up_time::Real, hours_per_subperiod::Int)
    @constraint(EP, vH2GenCOMMIT_yt >= sum_expression(vH2GenStart[y,(t-((t%hours_per_subperiod)-1):t)])+sum_expression(vH2GenStart[y,((t+hours_per_subperiod-(t%hours_per_subperiod))-(up_time-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod))]))
    return nothing
end

function h2_prod_commit_uptime_start!(EP::Model, y::Int, t::Int, vH2GenCOMMIT_yt::VariableRef, vH2GenStart::AbstractArray{VariableRef}, up_time::Real, hours_per_subperiod::Int)
    @constraint(EP, vH2GenCOMMIT_yt >= vH2GenStart[y,t] + sum_expression(vH2GenStart[y,((t+hours_per_subperiod-1)-(up_time-1)):(t+hours_per_subperiod-1)]))
    return nothing
end

function h2_prod_commit_downtime!(EP::Model, T::Int, dfH2Gen::DataFrame, H2_GEN_COMMIT::Array{Int64,1}, START_SUBPERIODS::StepRange{Int64, Int64}, INTERIOR_SUBPERIODS::Array{Int64,1}, hours_per_subperiod::Int64)

    down_time_arr = Dict{Int64,Int64}()
    down_time_HOURS_arr = Dict{Int64,Vector{Int64}}()
    @inbounds for y in H2_GEN_COMMIT
        down_time = Int(floor(dfH2Gen[!,:Down_Time][y]))
        down_time_arr[y] = down_time
        down_time_HOURS = Int64[] # Set of hours in the summation term of the maximum down time constraint for the first subperiod of each representative period
        for s in START_SUBPERIODS
            down_time_HOURS = union(down_time_HOURS, (s+1):(s+down_time-1))
        end
        down_time_HOURS_arr[y] = down_time_HOURS
    end

    cap_size_arr = dfH2Gen[!,:Cap_Size_tonne_p_hr]::Array{Float64,1}

    @inbounds for t in 1:T
        @inbounds for y in H2_GEN_COMMIT
            ## down time
            down_time = down_time_arr[y]
            down_time_HOURS = down_time_HOURS_arr[y]
            cap_size = cap_size_arr[y]

            # cUpTimeInterior: Constraint looks back over last n hours, where n = dfH2Gen[!,:Up_Time][y]
            if t in setdiff(INTERIOR_SUBPERIODS,down_time_HOURS)
                h2_prod_commit_downtime_interior!(EP, y, t, EP[:vH2GenCOMMIT][y,t], EP[:vH2GenShut], EP[:eH2GenTotalCap][y], cap_size, down_time)
            end
            # cUpTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
            if t in down_time_HOURS
                h2_prod_commit_downtime_wrap!(EP, y, t, EP[:vH2GenCOMMIT][y,t], EP[:vH2GenShut], EP[:eH2GenTotalCap][y], cap_size, down_time, hours_per_subperiod)
            end
            # cUpTimeStart:
            if t in START_SUBPERIODS
                h2_prod_commit_downtime_start!(EP, y, t, EP[:vH2GenCOMMIT][y,t], EP[:vH2GenShut], EP[:eH2GenTotalCap][y], cap_size, down_time, hours_per_subperiod)
            end
        end
    end
end

function h2_prod_commit_downtime_interior!(EP::Model, y::Int, t::Int, vH2GenCOMMIT_yt::VariableRef, vH2GenShut::AbstractArray{VariableRef}, eH2GenTotalCap::AffExpr, cap_size::Float64, down_time::Int)
    @constraint(EP, eH2GenTotalCap / cap_size - vH2GenCOMMIT_yt >= sum_expression(vH2GenShut[y,(t-down_time):t]))
    return nothing
end

function h2_prod_commit_downtime_wrap!(EP::Model, y::Int, t::Int, vH2GenCOMMIT_yt::VariableRef, vH2GenShut::AbstractArray{VariableRef}, eH2GenTotalCap::AffExpr, cap_size::Float64, down_time::Int, hours_per_subperiod::Int)
    @constraint(EP, eH2GenTotalCap / cap_size - vH2GenCOMMIT_yt >= sum_expression(vH2GenShut[y,(t-((t%hours_per_subperiod)-1):t)]) + sum_expression(vH2GenShut[y,((t+hours_per_subperiod-(t%hours_per_subperiod))-(down_time-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod))]))
    return nothing
end

function h2_prod_commit_downtime_start!(EP::Model, y::Int, t::Int, vH2GenCOMMIT_yt::VariableRef, vH2GenShut::AbstractArray{VariableRef}, eH2GenTotalCap::AffExpr, cap_size::Float64, down_time::Int, hours_per_subperiod::Int)
    @constraint(EP, eH2GenTotalCap / cap_size - vH2GenCOMMIT_yt  >= vH2GenShut[y,t] + sum_expression(vH2GenShut[y,((t+hours_per_subperiod-1)-(down_time-1)):(t+hours_per_subperiod-1)]))
    return nothing
end

function h2_prod_commit_ramp_up!(EP::Model, vH2Gen::AbstractArray{VariableRef}, vH2GenCOMMIT::AbstractArray{VariableRef}, vH2GenStart::AbstractArray{VariableRef}, vH2GenShut::AbstractArray{VariableRef}, H2_GEN_COMMIT::Array{Int64,1}, time_steps::AbstractArray{Int64}, ramp_up_cap::Dict{Int64,Float64}, min_output::Dict{Int64,Float64}, max_min::Dict{Tuple{Int64,Int64},Float64}, t_shift::Int64=0)
    @inbounds for t in time_steps
        t_mod = t+t_shift-1
        @inbounds for k in H2_GEN_COMMIT
            @constraint(EP, 
            + vH2Gen[k,t] 
            - vH2Gen[k,t_mod]
            <=
            + ramp_up_cap[k] * vH2GenCOMMIT[k,t]
            + max_min[k,t] * vH2GenStart[k,t]
            - min_output[k] * vH2GenShut[k,t]
            )
        end
    end
end

function h2_prod_commit_ramp_down!(EP::Model, vH2Gen::AbstractArray{VariableRef}, vH2GenCOMMIT::AbstractArray{VariableRef}, vH2GenStart::AbstractArray{VariableRef}, vH2GenShut::AbstractArray{VariableRef}, H2_GEN_COMMIT::Array{Int64,1}, time_steps::AbstractArray{Int64}, ramp_down_cap::Dict{Int64,Float64}, min_output::Dict{Int64,Float64}, max_min::Dict{Tuple{Int64,Int64},Float64}, t_shift::Int64=0)
    @inbounds for t in time_steps
        t_mod = t+t_shift-1
        @inbounds for k in H2_GEN_COMMIT
            @constraint(EP, 
            + vH2Gen[k,t_mod]
            - vH2Gen[k,t] 
            <=
            + ramp_down_cap[k] * vH2GenCOMMIT[k,t]
            + max_min[k,t] * vH2GenStart[k,t]
            - min_output[k] * vH2GenShut[k,t]
            )
        end
    end
end

function prep_ramp_limits(dfH2Gen::DataFrame, ramp_percent::AbstractArray{Float64}, pH2_Max::AbstractArray{Float64}, H2_GEN_COMMIT::Vector{Int64}, START_SUBPERIODS::OrdinalRange{Int64, Int64}, INTERIOR_SUBPERIODS::Vector{Int64})
    cap_size = dfH2Gen[!,:Cap_Size_tonne_p_hr]::Array{Float64,1}
    h2Gen_min_output = dfH2Gen[!,:H2Gen_min_output]::Array{Float64,1}

    ramp_cap = Dict{Int64,Float64}()
    max_ramp_or_min_output = Dict{Int64,Float64}()
    min_output = Dict{Int64,Float64}()
    max_min = Dict{Tuple{Int64,Int64},Float64}()

    @inbounds for k in H2_GEN_COMMIT
        ramp_cap[k] = ramp_percent[k] * cap_size[k]
        max_ramp_or_min_output[k] = max(h2Gen_min_output[k], ramp_percent[k])
        min_output[k] = h2Gen_min_output[k] * cap_size[k]
    end

    max_min_start = prep_max_min_lim(max_ramp_or_min_output, cap_size, pH2_Max, ramp_cap, H2_GEN_COMMIT, START_SUBPERIODS)
    max_min = prep_max_min_lim(max_ramp_or_min_output, cap_size, pH2_Max, ramp_cap, H2_GEN_COMMIT, INTERIOR_SUBPERIODS)

    return ramp_cap, min_output, max_min, max_min_start
end

function prep_max_min_lim(max_ramp_or_min_output::Dict{Int64,Float64}, cap_size::AbstractArray{Float64},  pH2_Max::AbstractArray{Float64}, ramp_up_cap::Dict{Int64,Float64}, H2_GEN_COMMIT::Vector{Int64}, time_steps::OrdinalRange{Int64, Int64})
    max_min = Dict{Tuple{Int64,Int64},Float64}()
    @inbounds for t in time_steps
        @inbounds for k in H2_GEN_COMMIT
            max_min[(k,t)] = min(pH2_Max[k,t], max_ramp_or_min_output[k]) * cap_size[k] - ramp_up_cap[k]
        end
    end
    return max_min
end

function prep_max_min_lim(max_ramp_or_min_output::Dict{Int64,Float64}, cap_size::AbstractArray{Float64},  pH2_Max::AbstractArray{Float64}, ramp_up_cap::Dict{Int64,Float64}, H2_GEN_COMMIT::Vector{Int64}, time_steps::Vector{Int64})
    max_min = Dict{Tuple{Int64,Int64},Float64}()
    @inbounds for t in time_steps
        @inbounds for k in H2_GEN_COMMIT
            max_min[(k,t)] = min(pH2_Max[k,t], max_ramp_or_min_output[k]) * cap_size[k] - ramp_up_cap[k]
        end
    end
    return max_min
end
