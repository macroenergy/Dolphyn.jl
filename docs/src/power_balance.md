# Power Balance

The power balance constraint of the model ensures that electricity demand is met at every time step in each zone. As shown in the constraint, electricity demand, $D_{z,t}^{E}$, at each time step and for each zone must be strictly equal to the sum of generation, $x_{g,z,t}^{E,GEN}$, from thermal technologies ($\mathcal{THE}$), curtailable variable renewable energy resources ($\mathcal{VRE}$). At the same time, energy storage devices ($\mathcal{S}$) can discharge energy, $x_{s,z,t}^{E,DIS}$ to help satisfy demand, while when these devices are charging, $x_{s,z,t}^{E,CHA}$, they increase demand. Price-responsive demand curtailment, $x_{s,z,t}^{E,NSD}$, also reduces demand. Finally, power flows, $x_{l,t}^{E,NET}$, on each line $l$ into or out of a zone (defined by the network map $f^{E,map}(\cdot)$), are considered in the demand balance equation for each zone. 

By definition, power flows leaving their reference zone are positive, thus the minus sign in the below constraint. At the same time losses due to power flows increase demand, and one-half of losses across a line linking two zones are attributed to each connected zone. The losses function $f^{\textrm{E,loss}}(\cdot)$ will depend on the configuration used to model losses.

```math
\begin{equation*}
    Bal_{power} = \sum_{g \in \mathcal{G}} x_{g,z,t}^{\textrm{E,GEN}} + f^{E,map}(x_{l,t}^{E,NET}) + \sum_{s \in \mathcal{S}} x_{s,z,t}^{\textrm{E,DIS}} + \sum_{s \in \mathcal{SEG}} x_{s,z,t}^{\textrm{E,NSD}}= \sum_{s \in \mathcal{S}} x_{s,z,t}^{\textrm{E,CHA}} + \textrm{D}_{z,t}^{\textrm{E}}
\end{equation*}
```

```math
\begin{equation*}
	x_{g,z,t}^{\textrm{E,GEN}} = 
	\begin{cases}
		x_{k,z,t}^{\textrm{E,THE}} \quad if \quad g \in \mathcal{K} \\
		x_{r,z,t}^{\textrm{E,VRE}} \quad if \quad g \in \mathcal{R} \\
		x_{s,z,t}^{\textrm{E,DIS}} \quad if \quad g \in \mathcal{S}
	\end{cases}
	\quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```