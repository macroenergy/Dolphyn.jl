# Objective Function

The objective function 'Obj' of DOLPHYN minimizes total annual investment and operation costs from the power and hydrogen energy sectors denoted by superscripts 'c' and 'o' respectively.

## Power Sector

In the power sector, cost terms include annual investment and operation costs:

```math
\begin{equation*}
	Obj_{power}	= \textrm{C}^{E,c} + \textrm{C}^{E,o}
\end{equation*}
```

where,

```math
\begin{equation*}
	\textrm{C}^{E,c} = \textrm{C}^{\textrm{E,GEN,c}} + \textrm{C}^{\textrm{E,ENE,c}} + \textrm{C}^{\textrm{E,CHA,c}} + \textrm{C}^{\textrm{E,NET,c}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{E,o} = \textrm{C}^{\textrm{E,GEN,o}} + \textrm{C}^{\textrm{E,start}} + \textrm{C}^{\textrm{E,NSD}}
\end{equation*}
```
These are derived from the components as shown in the following equations:

```math
\begin{equation*}
	\textrm{C}^{\textrm{E,GEN,c}} = \sum_{g \in G} y_{g}^{\textrm{E,GEN,new}}\times \textrm{c}_{g}^{\textrm{E,INV}} + \sum_{g \in G} y_{g}^{\textrm{E,GEN,total}}\times \textrm{c}_{g}^{\textrm{E,FOM}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{E,ENE,c}} = \sum_{s \in \mathcal{S}} \sum_{z \in \mathcal{Z}} (\textrm{c}_{s,z}^{\textrm{E,ENE,INV}} \times y_{s,z}^{\textrm{E,ENE,new}} + \textrm{c}_{s,z}^{\textrm{E,ENE,FOM}} \times y_{s,z}^{\textrm{E,ENE,total}})
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{E,CHA,c}} = \sum_{s \in \mathcal{S}^{asym}} \sum_{z \in \mathcal{Z}} (\textrm{c}_{s,z}^{\textrm{E,CHA,INV}} \times y_{s,z}^{\textrm{E,CHA,new}} + \textrm{c}_{s,z}^{\textrm{E,CHA,FOM}} \times y_{s,z}^{\textrm{E,CHA,total}})
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{E,NET,c}} = \sum_{l \in \mathcal{L}}\left(\textrm{c}_{l}^{\textrm{E,NET}} \times y_{l}^{\textrm{E,NET,new}}\right)
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{E,GEN,o}} = \sum_{g \in \mathcal{G}} \sum_{t \in \mathcal{T}} \omega_t \times \left(\textrm{c}_{g}^{\textrm{E,VOM}} + \textrm{c}_{g}^{\textrm{E,FUEL}}\right) \times x_{g,z,t}^{\textrm{E,GEN}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{E,start}} = \sum_{k \in \mathcal{UC}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{k}^{\textrm{E,start}} \times n_{k,z,t}^{\textrm{E,UP}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{E,NSD}} = \sum_{s \in \mathcal{SEG}} \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{n}_{s}^{\textrm{E,NSD}} \times x_{s,z,t}^{\textrm{E,NSD}}
\end{equation*}
```

The first term $C^{E,GEN,c}$ represents the fixed costs of generation/discharge over all zones and technologies, which reflects the sum of the annualized capital cost, $c_{g,z}^{E,INV}$, times the total new capacity added $y_{g}^{E,GEN,new}$ (if any), plus the Fixed O&M cost, $c_{g,z}^{E,FOM}$, times the total installed generation capacity $y_{g}^{E,GEN,Total}$.

The second term $C^{E,ENE,c}$ corresponds to the fixed cost of installed energy storage capacity and is summed over only the storage resources (e.g. $s \in \mathcal{S}$). This term includes the sum of the annualized energy capital cost, $c_{s,z}^{E,ENE,INV}$, times the total new energy capacity added $y_{s,z}^{E,ENE,new}$ (if any), plus the Fixed O&M cost, $c_{s,z}^{E,ENE,FOM}$, times the total installed energy storage capacity $y_{s,z}^{E,ENE,Total}$.

The third term $C^{E,CHA,c}$ corresponds to the fixed cost of installed charging power capacity and is summed over only over storage resources with independent/asymmetric charge and discharge power components (e.g. $s \in \mathcal{S}^{asym}$). This term includes the sum of the annualized charging power capital cost, $c_{s,z}^{E,CHA,INV}$, times the total new charging power capacity added $y_{s,z}^{E,CHA,new}$ (if any), plus the Fixed O&M cost, $c_{s,z}^{E,CHA,FOM}$, times the total installed charging power capacity $y_{s,z}^{E,CHA,Total}$.

The fourth term $C^{E,NET,c}$ corresponds to the transmission network reinforcement or construction costs, for each transmission line (if modeled). Transmission reinforcement costs are equal to the sum across all lines of the product between the transmission reinforcement/construction cost, $c_{l}^{E,NET}$, times the additional transmission capacity variable, $y_{l}^{E,NET,new}$. Note that fixed O&M and replacement capital costs (depreciation) for existing transmission capacity is treated as a sunk cost and not included explicitly in the power sector objective function.

The fifth term $C^{E,GEN,o}$ correspond to the operational cost across all zones, technologies, and time steps. It represents the sum of fuel cost, $c_{g}^{E,FUEL}$ (if any), plus variable O&M cost, $c_{g}^{E,VOM}$ times the energy generation/discharge by generation or storage resources in time step $t$, $x_{g,z,t}$, and the weight of each time step $t$, $\omega_t$. 

The sixth term $C^{E,start}$ corresponds to the startup costs incurred by technologies to which unit commitment decisions apply (e.g. $g \in \mathcal{UC}$), equal to the cost of start-up, $c_{k}^{E,start}$, times the number of startup events, $n_{k,z,t}^{E,UP}$, for the cluster of units in each zone and time step (weighted by $\omega_t$).

The seventh term $C^{E,NSD}$ represents the total cost of unserved demand across all segments $s$ of a segment-wise price-elastic demand curve, equal to the marginal value of consumption (or cost of non-served energy), $n_{s}^{E,NSD}$, times the amount of non-served energy, $x_{s,z,t}^{E,NSD}$, for each segment on each zone during each time step (weighted by $\omega_t$).

## Hydrogen Sector

In the hydrogen sector, cost terms include annual hydrogen generation, transmission and storage system investment and operation costs:

```math
\begin{equation*}
	Obj_{hydrogen} = \textrm{C}^{H,c} + \textrm{C}^{H,o}
\end{equation*}
```

where,

```math
\begin{equation*}
	\textrm{C}^{H,c} = \textrm{C}^{\textrm{H,GEN,c}} + \textrm{C}^{\textrm{H,ENE,c}} + \textrm{C}^{\textrm{H,CHA,c}} + \textrm{C}^{\textrm{H,TRA,c}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{H,o} = \textrm{C}^{\textrm{H,GEN,o}} + \textrm{C}^{\textrm{H,start}} + \textrm{C}^{\textrm{H,NSD}}
\end{equation*}
```

These are derived from the components as shown in the following equations:

```math
\begin{equation*}
	\textrm{C}^{\textrm{H,GEN,c}} = \sum_{k in K} y_{k}^{\textrm{H,GEN,new}}\times \textrm{c}_{k}^{\textrm{H,INV}} + \sum_{k in K} y_{k}^{\textrm{H,GEN,total}}\times \textrm{c}_{k}^{\textrm{H,FOM}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{H,ENE,c}} = \sum_{s \in \mathcal{S}} \sum_{z \in \mathcal{Z}} (\textrm{c}_{s,z}^{\textrm{H,ENE,INV}} \times y_{s,z}^{\textrm{H,ENE,new}} + \textrm{c}_{s,z}^{\textrm{H,ENE,FOM}} \times y_{s,z}^{\textrm{H,ENE,total}})
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{H,CHA,c}} = \sum_{s \in \mathcal{S}^{asym}} \sum_{z \in \mathcal{Z}} (\textrm{c}_{s,z}^{\textrm{H,CHA,INV}} \times y_{s,z}^{\textrm{H,CHA,new}} + \textrm{c}_{s,z}^{\textrm{H,CHA,FOM}} \times y_{s,z}^{\textrm{H,CHA,total}})
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{H,TRA,c}} = \sum_{l \in \mathcal{L}}\left(\textrm{c}_{l}^{\textrm{H,TRA}} \times y_{l}^{\textrm{H,TRA,new}}\right)
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{H,GEN,o}} = \sum_{k \in \mathcal{K}} \sum_{t \in \mathcal{T}} \omega_t \times \left(\textrm{c}_{k}^{\textrm{H,VOM}} + \textrm{c}_{k}^{\textrm{H,FUEL}}\right) \times x_{k,z,t}^{\textrm{H,GEN}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{H,start}} = \sum_{k \in \mathcal{UC}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{k}^{\textrm{H,start}} \times n_{k,z,t}^{\textrm{H,UP}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{H,NSD}} = \sum_{s \in \mathcal{SEG}} \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{n}_{s}^{\textrm{H,NSD}} \times x_{s,z,t}^{\textrm{H,NSD}}
\end{equation*}
```

The first term $C^{H,GEN,c}$ represents the fixed costs of hydrogen generation/discharge over all zones and technologies, which reflects the sum of the annualized capital cost, $c_{k,z}^{H,INV}$, times the total new capacity added $y_{k}^{H,GEN,new}$ (if any), plus the Fixed O&M cost, $c_{k,z}^{H,FOM}$, times the total installed generation capacity $y_{k}^{H,GEN,Total}$.

The second term $C^{H,ENE,c}$ corresponds to the fixed cost of installed hydrogen storage energy capacity and is summed over only the hydrogen storage resources (e.g. $s \in \mathcal{S}$). This term includes the sum of the annualized energy capital cost, $c_{s,z}^{H,ENE,INV}$, times the total new energy capacity added $y_{s,z}^{H,ENE,new}$ (if any), plus the Fixed O&M cost, $c_{s,z}^{H,ENE,FOM}$, times the total installed energy storage capacity $y_{s,z}^{H,ENE,Total}$.

The third term $C^{H,CHA,c}$ corresponds to the fixed cost of installed hydrogen charging power capacity and is summed over only over storage resources with independent/asymmetric charge and discharge power components (e.g. $s \in \mathcal{S}^{asym}$). This term includes the sum of the annualized charging power capital cost, $c_{s,z}^{H,CHA,INV}$, times the total new charging power capacity added $y_{s,z}^{H,CHA,new}$ (if any), plus the Fixed O&M cost, $c_{s,z}^{H,CHA,FOM}$, times the total installed charging power capacity $y_{s,z}^{H,CHA,Total}$.

The fourth term $C^{H,TRA,c}$ corresponds to the transmission reinforcement or construction costs, for each pipeline (if modeled). Transmission reinforcement costs are equal to the sum across all pipelines of the product between the transmission reinforcement/construction cost, $c_{l}^{H,NET}$, times the additional transmission capacity variable, $y_{l}^{H,NET,new}$. Note that fixed O&M and replacement capital costs (depreciation) for existing transmission capacity is treated as a sunk cost and not included explicitly in the GenX objective function.

The fifth term $C^{H,GEN,o}$ correspond to the operational cost across all zones, technologies, and time steps. It represents the sum of fuel cost, $c_{k}^{H,FUEL}$ (if any), plus variable O&M cost, $c_{k}^{H,VOM}$ times the energy generation/discharge by generation or storage resources in time step $t$, $x_{k,z,t}$, and the weight of each time step $t$, $\omega_t$. 

The sixth term $C^{H,start}$corresponds to the startup costs incurred by technologies to which unit commitment decisions apply (e.g. $g \in \mathcal{UC}$), equal to the cost of start-up, $c_{k}^{H,start}$, times the number of startup events, $n_{k,z,t}^{H,UP}$, for the cluster of units in each zone and time step (weighted by $\omega_t$).

The seventh term $C^{H,NSD}$ represents the total cost of unserved demand across all segments $s$ of a segment-wise price-elastic demand curve, equal to the marginal value of consumption (or cost of non-served hydrogen), $n_{s}^{H,NSD}$, times the amount of non-served energy, $x_{s,z,t}^{H,NSD}$, for each segment on each zone during each time step (weighted by $\omega_t$).

In summary, the objective function can be understood as the minimization of costs associated with five sets of different decisions:
1. Where and how to invest on capacity,
2. How to dispatch or operate that capacity,
3. Which consumer demand segments to serve or curtail including power and hydrogen,
4. How to cycle and commit thermal units subject to unit commitment decisions,
5. Where and how to invest in additional transmission network capacity to increase power transfer and hydrogen transfer capacity between zones.

Note however each of these components are considered jointly and the optimization is performed over the whole problem at once as a monolithic co-optimization problem.
