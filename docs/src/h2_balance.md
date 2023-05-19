# Hydrogen Balance

The hydrogen balance constraint of the model ensures that hydrogen demand is met at every time step in each zone. As shown in the constraint, hydrogen demand, $\textrm{D}_{z,t}^{\textrm{H}}$, at each time step and for each zone must be strictly equal to the sum of generation, $x_{g,z,t}^{\textrm{H,GEN}}$, from thermal technologies ($\mathcal{THE}$), electrolysis resources ($\mathcal{ELE}$). At the same time, energy storage devices ($\mathcal{S}$) can discharge energy, $x_{s,z,t}^{\textrm{H,DIS}}$ to help satisfy hydrogen demand, while when these devices are charging, $x_{s,z,t}^{\textrm{H,CHA}}$, they increase demand. Price-responsive demand curtailment, $x_{s,z,t}^{\textrm{H,NSD}}$, also reduces demand. Finally, hydrogen pipeline flows, $x_{l,t}^{\textrm{H,PIP}}$, on each pipeline $l$ into or out of a zone (defined by the pipeline map $f^{\textrm{H,map}}(\cdot)$), are considered in the demand balance equation for each zone. 

If gas-to-power is modeled, the hydrogen consumed $x_{k,z,t}^{\textrm{H,G2P}}$ is subtracted from the hydrogen balance. If liquid hydrogen is modeled, hydrogen liquified $x_{g,z,t}^{\textrm{H,LIQ}}$ is subtracted from the gas balance and evaporated hydrogen $x_{g,z,t}^{\textrm{H,EVAP}}$ is added. A liquid hydrogen balance expression is also defined. If trucks are modeled, their flows are added to the hydrogen balance (not shown here). 

```math
\begin{equation*}
    BalGas_{hydrogen} = \sum_{g \in \mathcal{G}} x_{g,z,t}^{\textrm{H,GEN}} + f^{\textrm{H,map}}(x_{l,t}^{\textrm{H,PIP}}) + \sum_{s \in \mathcal{S}} x_{s,z,t}^{\textrm{H,DIS}} + \sum_{s \in \mathcal{SEG}} x_{s,z,t}^{\textrm{H,NSD}} + \sum_{g \in \mathcal{G}} x_{g,z,t}^{\textrm{H,EVAP}} = \sum_{s \in \mathcal{S}} x_{s,z,t}^{\textrm{H,CHA}} + \textrm{D}_{z,t}^{\textrm{Hg}} + \sum_{g \in \mathcal{G}} x_{g,z,t}^{\textrm{H,LIQ}} + \sum_{k \in \mathcal{K}} $x_{k,z,t}^{\textrm{H,G2P}}$
\end{equation*}
```

```math
\begin{equation*}
    BalLiq_{hydrogen} = \sum_{g \in \mathcal{G}} x_{g,z,t}^{\textrm{H,LIQ}} + \sum_{s \in \mathcal{S}} x_{s,z,t}^{\textrm{H,DIS}} + \sum_{s \in \mathcal{SEG}} x_{s,z,t}^{\textrm{H,NSD}}= \sum_{s \in \mathcal{S}} x_{s,z,t}^{\textrm{H,CHA}} + \sum_{g \in \mathcal{G}} x_{g,z,t}^{\textrm{H,EVAP}} + \textrm{D}_{z,t}^{\textrm{Hl}}
\end{equation*}
```
