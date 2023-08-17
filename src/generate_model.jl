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
    generate_model(setup::Dict,inputs::Dict,OPTIMIZER::MOI.OptimizerWithAttributes,modeloutput = nothing)

This function sets up and solves a constrained optimization model of electricity system capacity expansion and operation problem and extracts solution variables for later processing.

In addition to calling a number of other modules to create constraints for specific resources, policies, and transmission assets, this function initializes two key expressions that are successively expanded in each of the resource-specific modules: (1) the objective function; and (2) the zonal power balance expression. These two expressions are the only expressions which link together individual modules (e.g. resources, transmission assets, policies), which otherwise are self-contained in defining relevant variables, expressions, and constraints.

**Objective Function**

The objective function of GenX minimizes total annual electricity system costs over the following six components shown in the equation below:

```math
\begin{aligned}
    &\sum_{y \in \mathcal{G} } \sum_{z \in \mathcal{Z}}
    \left( (\pi^{INVEST}_{y,z} \times \overline{\Omega}^{size}_{y,z} \times  \Omega_{y,z})
    + (\pi^{FOM}_{y,z} \times \overline{\Omega}^{size}_{y,z} \times  \Delta^{total}_{y,z})\right) + \notag \\
    &\sum_{y \in \mathcal{O} } \sum_{z \in \mathcal{Z}}
    \left( (\pi^{INVEST,energy}_{y,z} \times    \Omega^{energy}_{y,z})
    + (\pi^{FOM,energy}_{y,z} \times  \Delta^{total,energy}_{y,z})\right) + \notag \\
    &\sum_{y \in \mathcal{O}^{asym} } \sum_{z \in \mathcal{Z}}
    \left( (\pi^{INVEST,charge}_{y,z} \times    \Omega^{charge}_{y,z})
    + (\pi^{FOM,charge}_{y,z} \times  \Delta^{total,charge}_{y,z})\right) + \notag \\
    & \sum_{y \in \mathcal{G} } \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \left( \omega_t\times(\pi^{VOM}_{y,z} + \pi^{FUEL}_{y,z})\times \Theta_{y,z,t}\right) + \sum_{y \in \mathcal{O \cup DF} } \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \left( \omega_t\times\pi^{VOM,charge}_{y,z} \times \Pi_{y,z,t}\right) +\notag \\
    &\sum_{s \in \mathcal{S} } \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}}\left(\omega_t \times n_{s}^{slope} \times \Lambda_{s,z,t}\right) + \sum_{t \in \mathcal{T} } \left(\omega_t \times \pi^{unmet}_{rsv} \times r^{unmet}_{t}\right) \notag \\
    &\sum_{y \in \mathcal{H} } \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}}\left(\omega_t \times \pi^{START}_{y,z} \times \chi_{s,z,t}\right) + \notag \\
    & \sum_{l \in \mathcal{L}}\left(\pi^{TCAP}_{l} \times \bigtriangleup\varphi^{max}_{l}\right)
\end{aligned}
```

The first summation represents the fixed costs of generation/discharge over all zones and technologies, which refects the sum of the annualized capital cost, $\pi^{INVEST}_{y,z}$, times the total new capacity added (if any),  plus the Fixed O&M cost, $\pi^{FOM}_{y,z}$, times the net installed generation capacity, $\overline{\Omega}^{size}_{y,z} \times \Delta^{total}_{y,z}$ (e.g., existing capacity less retirements plus additions).

The second summation corresponds to the fixed cost of installed energy storage capacity and is summed over only the storage resources. This term includes the sum of the annualized energy capital cost, $\pi^{INVEST,energy}_{y,z}$, times the total new energy capacity added (if any), plus the Fixed O&M cost, $\pi^{FOM, energy}_{y,z}$, times the net installed energy storage capacity, $\Delta^{total}_{y,z}$ (e.g., existing capacity less retirements plus additions).

The third summation corresponds to the fixed cost of installed charging power capacity and is summed over only over storage resources with independent/asymmetric charge and discharge power components ($\mathcal{O}^{asym}$). This term includes the sum of the annualized charging power capital cost, $\pi^{INVEST,charge}_{y,z}$, times the total new charging power capacity added (if any), plus the Fixed O&M cost, $\pi^{FOM, energy}_{y,z}$, times the net installed charging power capacity, $\Delta^{total}_{y,z}$ (e.g., existing capacity less retirements plus additions).

The fourth and fifth summations corresponds to the operational cost across all zones, technologies, and time steps. The fourth summation represents the sum of fuel cost, $\pi^{FUEL}_{y,z}$ (if any), plus variable O&M cost, $\pi^{VOM}_{y,z}$ times the energy generation/discharge by generation or storage resources (or demand satisfied via flexible demand resources, $y\in\mathcal{DF}$) in time step $t$, $\Theta_{y,z,t}$, and the weight of each time step $t$, $\omega_t$, where $\omega_t$ is equal to 1 when modeling grid operations over the entire year (8760 hours), but otherwise is equal to the number of hours in the year represented by the representative time step, $t$ such that the sum of $\omega_t \forall t \in T = 8760$, approximating annual operating costs. The fifth summation represents the variable charging O&M cost, $\pi^{VOM,charge}_{y,z}$ times the energy withdrawn for charging by storage resources (or demand deferred by flexible demand resources) in time step $t$ , $\Pi_{y,z,t}$ and the annual weight of time step $t$,$\omega_t$.

The sixth summation represents the total cost of unserved demand across all segments $s$ of a segment-wise price-elastic demand curve, equal to the marginal value of consumption (or cost of non-served energy), $n_{s}^{slope}$, times the
amount of non-served energy, $\Lambda_{y,z,t}$, for each segment on each zone during each time step (weighted by $\omega_t$).

The seventh summation represents the total cost of not meeting hourly operating reserve requirements, where $\pi^{unmet}_{rsv}$ is the cost penalty per unit of non-served reserve requirement, and $r^{unmet}_t$ is the amount of non-served reserve requirement in each time step (weighted by $\omega_t$).

The eighth summation corresponds to the startup costs incurred by technologies to which unit commitment decisions apply (e.g. $y \in \mathcal{UC}$), equal to the cost of start-up, $\pi^{START}_{y,z}$, times the number of startup events, $\chi_{y,z,t}$, for the cluster of units in each zone and time step (weighted by $\omega_t$).

The last term corresponds to the transmission reinforcement or construction costs, for each transmission line in the model. Transmission reinforcement costs are equal to the sum across all lines of the product between the transmission reinforcement/construction cost, $pi^{TCAP}_{l}$, times the additional transmission capacity variable, $\bigtriangleup\varphi^{max}_{l}$. Note that fixed OM and replacement capital costs (depreciation) for existing transmission capacity is treated as a sunk cost and not included explicitly in the GenX objective function.

In summary, the objective function can be understood as the minimization of costs associated with five sets of different decisions: (1) where and how to invest on capacity, (2) how to dispatch or operate that capacity, (3) which consumer demand segments to serve or curtail, (4) how to cycle and commit thermal units subject to unit commitment decisions, (5) and where and how to invest in additional transmission network capacity to increase power transfer capacity between zones. Note however that each of these components are considered jointly and the optimization is performed over the whole problem at once as a monolithic co-optimization problem.

**Power Balance**

The power balance constraint of the model ensures that electricity demand is met at every time step in each zone. As shown in the constraint, electricity demand, $D_{z,t}$, at each time step and for each zone must be strictly equal to the sum of generation, $\Theta_{y,z,t}$, from thermal technologies ($\mathcal{H}$), curtailable VRE ($\mathcal{VRE}$), must-run resources ($\mathcal{MR}$), and hydro resources ($\mathcal{W}$). At the same time, energy storage devices ($\mathcal{O}$) can discharge energy, $\Theta_{y,z,t}$ to help satisfy demand, while when these devices are charging, $\Pi_{y,z,t}$, they increase demand. For the case of flexible demand resources ($\mathcal{DF}$), delaying demand (equivalent to charging virtual storage), $\Pi_{y,z,t}$, decreases demand while satisfying delayed demand (equivalent to discharging virtual demand), $\Theta_{y,z,t}$, increases demand. Price-responsive demand curtailment, $\Lambda_{s,z,t}$, also reduces demand. Finally, power flows, $\Phi_{l,t}$, on each line $l$ into or out of a zone (defined by the network map $\varphi^{map}_{l,z}$), are considered in the demand balance equation for each zone. By definition, power flows leaving their reference zone are positive, thus the minus sign in the below constraint. At the same time losses due to power flows increase demand, and one-half of losses across a line linking two zones are attributed to each connected zone. The losses function $\beta_{l,t}(\cdot)$ will depend on the configuration used to model losses (see Transmission section).

```math
\begin{aligned}
    & \sum_{y\in \mathcal{H}}{\Theta_{y,z,t}} +\sum_{y\in \mathcal{VRE}}{\Theta_{y,z,t}} +\sum_{y\in \mathcal{MR}}{\Theta_{y,z,t}} + \sum_{y\in \mathcal{O}}{(\Theta_{y,z,t}-\Pi_{y,z,t})} + \notag\\
    & \sum_{y\in \mathcal{DF}}{(-\Theta_{y,z,t}+\Pi_{y,z,t})} +\sum_{y\in \mathcal{W}}{\Theta_{y,z,t}}+ \notag\\
    &+ \sum_{s\in \mathcal{S}}{\Lambda_{s,z,t}}  - \sum_{l\in \mathcal{L}}{(\varphi^{map}_{l,z} \times \Phi_{l,t})} -\frac{1}{2} \sum_{l\in \mathcal{L}}{(\varphi^{map}_{l,z} \times \beta_{l,t}(\cdot))} = D_{z,t}
    \forall z\in \mathcal{Z},  t \in \mathcal{T}
\end{aligned}
```

"""

## generate_model(setup::Dict,inputs::Dict,OPTIMIZER::MOI.OptimizerWithAttributes,modeloutput = nothing)
################################################################################
##
## description: Sets up and solves constrained optimization model of electricity
## system capacity expansion and operation problem and extracts solution variables
## for later processing
##
## returns: Model EP object containing the entire optimization problem model to be solved by SolveModel.jl
##
################################################################################
function generate_model(setup::Dict,inputs::Dict,OPTIMIZER::MOI.OptimizerWithAttributes,modeloutput = nothing)

    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones - assumed to be same for power and hydrogen system

    ## Start pre-solve timer
    presolver_start_time = time()

    # Generate Energy Portfolio (EP) Model
    EP = Model(OPTIMIZER)

    # Introduce dummy variable fixed to zero to ensure that expressions like eTotalCap,
    # eTotalCapCharge, eTotalCapEnergy and eAvail_Trans_Cap all have a JuMP variable
    @variable(EP, vZERO == 0);

    # Initialize Objective Function Expression
    @expression(EP, eObj, 0)

    if setup["ModelElec"] == true 
        generate_genx!(EP, setup, inputs)
    end

    if setup["ModelH2"]==1 
        generate_hsc!(EP, setup, inputs)
    end

    if setup["ModelH2"] ==0
        co2_cap!(EP, inputs, setup)
    elseif setup["ModelH2"]==1
        EP = co2_cap_power_hsc(EP, inputs, setup)
    end

    @constraint(EP, cElecExportsePHBH2Equate[t=1:T, z=1:Z], EP[:ePowerBalance_HSC][t,z] == EP[:vElecExports_HSC][t,z])

    ## Define the objective function
    @objective(EP,Min,EP[:eObj])

    ## Record pre-solver time
    presolver_time = time() - presolver_start_time
        #### Question - What do we do with this time now that we've split this function into 2?
    if setup["PrintModel"] == 1
        if modeloutput === nothing
            filepath = joinpath(pwd(), "YourModel.lp")
            JuMP.write_to_file(EP, filepath)
        else
            filepath = joinpath(modeloutput, "YourModel.lp")
            JuMP.write_to_file(EP, filepath)
        end
        print_and_log("Model Printed")
    end

    return EP
end
