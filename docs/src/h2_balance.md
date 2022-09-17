# Hydrogen Balance

The hydrogen balance constraint of the model ensures that hydrogen demand is met at every time step in each zone. As shown in the constraint, hydrogen demand, $\textrm{D}_{z,t}^{H}$, at each time step and for each zone must be strictly equal to the sum of generation, $x_{g,z,t}^{H,GEN}$, from thermal technologies ($\mathcal{THE}$), electrolysis resources ($\mathcal{ELE}$). At the same time, energy storage devices ($\mathcal{S}$) can discharge energy, $x_{s,z,t}^{H,DIS}$ to help satisfy hydrogen demand, while when these devices are charging, $x_{s,z,t}^{H,CHA}$, they increase demand. Price-responsive demand curtailment, $x_{s,z,t}^{H,NSD}$, also reduces demand. Finally, power flows, $x_{l,t}^{H,NET}$, on each line $l$ into or out of a zone (defined by the network map $f^{H,map}(\cdot)$), are considered in the demand balance equation for each zone. 

By definition, power flows leaving their reference zone are positive, thus the minus sign in the below constraint. At the same time losses due to power flows increase demand, and one-half of losses across a line linking two zones are attributed to each connected zone.

```math
\begin{equation*}
    Bal_{hydrogen} = \sum_{k \in \mathcal{K}} x_{g,z,t}^{\textrm{H,GEN}} + f^{H,map}(x_{l,t}^{H,TRA}) + \sum_{s \in \mathcal{S}} x_{s,z,t}^{\textrm{H,DIS}} + \sum_{s \in \mathcal{SEG}} x_{s,z,t}^{\textrm{H,NSD}}= \sum_{s \in \mathcal{S}} x_{s,z,t}^{\textrm{H,CHA}} + \textrm{D}_{z,t}^{H}
\end{equation*}
```
