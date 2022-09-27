# Genx Notation

## Genx Indices and Sets
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$t \in \mathcal{T}$ | $t$ denotes an time step and $\mathcal{T}$ is the set of time steps over which grid operations are modeled|
|$z \in \mathcal{Z}$ | $z$ denotes a zone and $\mathcal{Z}$ is the set of zones in the network|
|$z \rightarrow z^{\prime} \in \mathcal{B}$ | $z \rightarrow z^{\prime}$ denotes paths for different transport routes of electricity and $\mathcal{B}$ is the set of all possible routes |
|$k \in \mathcal{K}$ | $k$ denotes a thermal generator like nuclear plant or coal-fire plant and $\mathcal{K} is the set of all thermal generators $|
|$r \in \mathcal{R}$ | $r$ denotes a variable renewable energy resource and $\mathcal{R}$ is the set of all renewable energy resources|
|$s \in \mathcal{S}$ | $s$ denotes an energy storage system (ESS) and $\mathcal{S}$ is the set of all energy storage systems|
|$s \in \mathcal{SEG}$| $s$ denotes the segment of load shedding |
|$z \in \mathcal{Z}^{CRM}_{p}$| each subset stands for a locational deliverability area (LDA) or a reserve sharing group|
|$z \in \mathcal{Z}_{p,mass}^{CO_2}$|Set of zones with no possibility for energy trading|
|$t \in \mathcal{T}^{start}$|This set of time-coupling constraints wrap around to ensure the power output in the first time step of each year (or each representative period)|
|$y \in \mathcal{W}$|Set of hydroelectric generators with water storage reservoirs|
|$y \in \mathcal{MR}$|set of generator/technology that are must-run resources. For these resources their output $t$ in each time interval must be exactly equal to their available capacity factor times the installed capacity and not allow for curtailment. These resources are also not eligible for contributing to anciliary services.|
|$k \in \mathcal{UC}$|Set of decisions pertaining to Unit commitment|
---


## Decision Variables
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$x_{k,z,t}^{\textrm{E,THE}}$| this term represents energy injected into the grid by thermal resource $k$ in zone $z$ at time period $t$|
|$x_{r,z,t}^{\textrm{E,VRE}}$| this term represents energy injected into the grid by renewable resource $r$ in zone $z$ at time period $t$|
|$x_{s,z,t}^{\textrm{E,DIS}}$| this term represents energy injected into the grid by storage resource $s$ in zone $z$ at time period $t$|
|$y_{k}^{\textrm{E,THE}}$| total available thermal generation capacity |
|$y_{r}^{\textrm{E,VRE}}$| total available renewable generation capacity|
|$y_{s}^{\textrm{E,STO,DIS}}$| total available storage discharge capacity |
|$y_{g}^{\textrm{E,GEN}}$| the sum of the existing capacity plus the newly invested capacity minus any retired capacity|
|$\textrm{C}^{\textrm{E,GEN,c}}$| investment costs of generation (fixed OM plus investment costs) from all generation resources $g \in \mathcal{G}$ (thermal, renewable and storage)|
|$\textrm{C}^{\textrm{E,EMI}} $|cost of add the CO2 emissions by plants in each zone|
|$x_{s,z,t}^{\textrm{E,NSD}}$| the non-served energy/curtailed demand decision variable representing the total amount of demand curtailed in demand segment $s$ at time period $t$ in zone $z$|
|$\textrm{n}_{s}^{\textrm{E,NSD}}$| this term represents the marginal willingness to pay for electricity of this segment of demand|
|$\textrm{D}_{z, t}^{\textrm{E}}$ | hourly electricity load in zone $z$ at time $t$|
|$f_{s,z,t}$|$f_{s,z,t} \geq 0$ is the contribution of generation or storage resource $s \in \mathcal{S}$ in time $t \in \mathcal{T}$ and zone $z \in \mathcal{Z}$ to frequency regulation|
|$r_{s,z,t}$|$r_{s,z,t} \geq 0$ is the contribution of generation or storage resource $s \in \mathcal{S}$ in time $t \in \mathcal{T}$ and zone $z \in \mathcal{Z}$ to operating reserves up|
|$unmet\_rsv_{t}$|$unmet\_rsv_{t} \geq 0$ denotes any shortfall in provision of operating reserves during each time period $t \in \mathcal{T}$|
|$C^{rsv}$|There is a penalty added to the objective function to penalize reserve shortfalls|
|$\rho^{max}_{y,z,t}$ |is the forecasted capacity factor for variable renewable resource $y \in VRE$ and zone $z$ in time step $t$|
|$\Delta^{\text{total}}_{y,z}$| is the total installed capacity of variable renewable resources $y \in VRE$ and zone $z$|
|$\alpha^{Contingency,Aux}_{y,z}$|$\alpha^{Contingency,Aux}_{y,z} \in [0,1]$ is a binary auxiliary variable that is forced by the second and third equations above to be 1 if the total installed capacity $\Delta^{\text{total}}_{y,z} > 0$ for any generator $y \in \mathcal{UC}$ and zone $z$, and can be 0 otherwise|
|$x_{l,t}^{\textrm{E,NET}}$|Power flows on each line $l$ into or out of a zone (defined by the network map $f^{\textrm{E,map}}(\cdot): l \rightarrow z$), are considered in the demand balance equation for each zone|
|$f^{\textrm{E,loss}}(\cdot)$|The losses function $f^{\textrm{E,loss}}(\cdot)$ will depend on the configuration used to model losses (see below)|
|$TransON_{l,t}^{\textrm{E,NET+}}$|$TransON_{l,t}^{\textrm{E,NET+}}$ is a continuous variable, representing the product of the binary variable $ON_{l,t}^{\textrm{E,NET+}}$ and the expression, $(y_{l}^{\textrm{E,NET,existing}} + y_{l}^{\textrm{E,NET,new}})$|
|$\mathcal{S}_{m,l,t}^{\textrm{E,NET}}$|we represent the absolute value of the line flow variable by the sum of positive stepwise flow variables $(\mathcal{S}_{m,l,t}^{\textrm{E,NET+}}, \mathcal{S}_{m,l,t}^{\textrm{E,NET-}})$, associated with each partition of line losses computed using the corresponding linear expressions |
|$n_{k,z,t}^{\textrm{E,THE}}$|the commitment state variable of generator cluster $k$ in zone $z$ at time $t$ ,$\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$|
|$n_{k,z,t}^{\textrm{E,UP}}$|the number of startup decision variable of generator cluster $k$ in zone $z$ at time $t$ ,$\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$|
|$n_{k,z,t}^{\textrm{E,DN}}$|the number of shutdown decision variable  of generator cluster $k$ in zone $z$ at time $t$ ,$\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$|
|$\textrm{C}^{\textrm{E,start}}$|this is the total cost of start-ups across all generators subject to unit commitment ($k \in \mathcal{UC}, \mathcal{UC} \subseteq \mathcal{G}$) and all time periods $t$|
| $p \in \mathcal{P}_{mass}^{CO_2}$ |Input data for each constraint requires the $CO_2$ allowance budget for each model zone|
|$\epsilon_{z,p,mass}^{CO_2}$|to be provided in terms of million metric tonnes|
|$overline{\epsilon_{z,p,load}^{CO_2}}$| denotes the emission limit in terms on t$CO_2$/MWh|
|$\mathcal{Z}_{p}^{ESR}$|For each constraint $p \in \mathcal{P}^{ESR}$, we define a subset of zones $z \in \mathcal{Z}_{p}^{ESR} \subset \mathcal{Z}$ that are eligible for trading renewable/clean energy credits to meet the corresponding renewable/clean energy requirement.|
|$\epsilon_{g,z,p}^{MinCapReq}$| is the eligiblity of a generator of technology $g$ in zone $z$ of requirement $p$ and will be equal to $1$ for eligible generators and will be zero for ineligible resources|
|$y_{r,z}^{\textrm{E,VRE,total}}$|VRE resources are a function of each technology's time-dependent hourly capacity factor , in per unit terms, and the total available capacity ($y_{r,z}^{\textrm{E,VRE,total}}$).|
|$y_{r,z}^{\textrm{E,VRE,new}}$|variables related to installed capacity ($y_{r,z}^{\textrm{E,VRE,new}}$) for all resource bins for a particular VRE resource type $r$ and zone $z$|
|$y_{r,z}^{\textrm{E,VRE,retired}}$|retired capacity ($y_{r,z}^{\textrm{E,VRE,retired}}$) for all resource bins for a particular VRE resource type $r$ and zone $z$|
|$\textrm{R}_{f,z,t}^{\textrm{E,FLEX}}$|maximum deferrable demand as a fraction of available capacity in a particular time step $t$, $\textrm{R}_{f,z,t}^{\textrm{E,FLEX}}$|
|$\eta_{f,z}^{\textrm{E,FLEX}}$|the energy losses associated with shifting demand|
|$x_{f,z,t}^{\textrm{E,FLEX}}$|the amount of deferred demand remaining to be served depends on the amount in the previous time step minus the served demand during time step $t$ ($\Theta_{y,z,t}$) while accounting for energy losses associated with demand flexibility, plus the demand that has been deferred during the current time step ($\Pi_{y,z,t}$)|
|$Q_{s,z, n}$|models inventory of storage technology $s \in \mathcal{S}$ in zone $z$ in each input period $n \in \mathcal{N}$|
|$\kappa_{y,z}^{\textrm{UP/DN}}$|the maximum ramp rates ($\kappa_{y,z}^{\textrm{E,DN}}$ and $\kappa_{y,z}^{\textrm{E,UP}}$ ) in per unit terms|
|$\upsilon_{y,z}^{\textrm{reg/rsv}}$|The amount of frequency regulation and operating reserves procured in each time step is bounded by the user-specified fraction ($\upsilon_{y,z}^{\textrm{reg}}$,$\upsilon_{y,z}^{\textrm{rsv}}$) of nameplate capacity for each reserve type|
|$U_{s,z,t}^{\textrm{E,STO}}$|This module defines the initial storage energy inventory level variable $U_{s,z,t}^{\textrm{E,STO}} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T_{p}^{start}}$, representing initial energy stored in the storage device $s$ in zone $z$ at all starting time period $t$ of modeled periods|
|$\Delta U_{s,z,m}^{\textrm{E,STO}}$|This module defines the change of storage energy inventory level during each representative period $\Delta U_{s,z,m}^{\textrm{E,STO}} \forall s \in \mathcal{S}, z \in \mathcal{Z}, m \in \mathcal{M}$, representing the change of storage energy inventory level of the storage device $s$ in zone $z$ during each representative period $m$|
|$U_{s,z,n}$|this variable models inventory of storage technology $s \in \mathcal{S}$ in zone $z$ in each input period $n \in \mathcal{N}$. |
|$U_{s,z,t}^{\textrm{E,STO}}$|This module defines the storage energy inventory level variable $U_{s,z,t}^{\textrm{E,STO}} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing energy stored in the storage device $s$ in zone $z$ at time period $t$|
|$x_{s,z,t}^{\textrm{E,CHA}}$|This module defines the power charge decision variable $x_{s,z,t}^{\textrm{E,CHA}}$ \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing charged power into the storage device $s$ in zone $z$ at time period $t$|
|$f_{s,z,t}^{\textrm{E,CHA/DIS}}$|where is the contribution of storage resources to frequency regulation while charging or discharging|
|$r_{s,z,t}^{\textrm{E,CHA/DIS}}$|$r_{s,z,t}^{\textrm{E,CHA/DIS}}$ are created for storage resources, to denote the contribution of storage resources to  reserves while charging or discharging|
|$\Omega_{k,z}^{\textrm{E,THE,size}}$| Unit capacity for a thermal plant with unit commitment constraint|
|$n_{k,z,t}^{\textrm{E,THE}}$|designates the commitment state of generator cluster $k$ in zone $z$ at time $t$|
|$n_{k,z,t}^{\textrm{E,UP}}$|represents number of startup decisions|
|$n_{k,z,t}^{\textrm{E,DN}}$|represents number of shutdown decisions|
|$y_{k,z}^{\textrm{E,THE}}$| is the Thermal resources total installed capacity|
|$x_{k,z,t}^{\textrm{E,THE}}$|is the energy injected into the grid by technology $y$ in zone $z$ at time $t$|
|$\tau_{k,z}^{\textrm{E,UP/DN}}$|is the minimum up or down time for units in generating cluster $k$ in zone $z$|
|$r_{k,z,t}^{\textrm{E,THE}}$| is the reserves contribution limited by the maximum reserves contribution $\upsilon_{k,z}^{rsv}$|
|$y_{g}^{\textrm{E,GEN, total}}$|the total existing generator capacity|
|$\textrm{C}^{\textrm{E,NSD}}$|Cost of non-served energy/curtailed demand from all demand curtailment segments $s \in \mathcal{SEG}$ over all time periods $t \in \mathcal{T} and all zones $z \in \mathcal{Z}$|
|$\textrm{C}^{\textrm{E,NET,c}}$|Transmission reinforcement costs|
|$x_{r,z,t}^{\textrm{E, CUR}}$|The amount of variable energy resource $r$ in zone $z$ that needs to be curtailed at time $t$|
|$\pi^{\textrm{TCAP}}_{l}$| Transmission reinforcement or construction cots for a transmission line [$/MW-yr] |
|$y_l^{\textrm{E,NET,new}}$|The additional transmission capacity required|
|$y_{l}^{\textrm{E, NET, Existing}}$|The maximum power transfer capacity of a given line|
|$r_{k,z,t}^{\textrm{E,THE}}$| is the reserves contribution limited by the maximum reserves contribution $\upsilon^{rsv}_{k,z}$|
|$ON_{l,t}^{\textrm{E, NET+}} \in [0, 1]$|Binary variable to activate positive flows on line $l$ at time $t$|
|$TransON_{l,t}^{\textrm{E, NET+}} \forall l \in \mathcal{L}, t \in \mathcal{T}$|Variable defining maximum positive flow in line l in time t [MW]|
## Parameters
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$\textrm{c}_{g}^{\textrm{E,INV}}$|Investment cost (annual ammortization of total construction cost) for power capacity of generator/storage $g$ |
|$\textrm{c}_{g}^{\textrm{E,FOM}}$| Fixed O&M cost of generator/storage $g$ |
|$\epsilon_{reg}^{load}$ and $\epsilon_{reg}^{vre}$ |are parameters specifying the required frequency regulation as a fraction of forecasted demand and variable renewable generation|
|$\epsilon_{y,z,p}^{CRM}$|the available capacity is the net injection into the transmission network in time step $t$ derated by the derating factor, also stored in the parameter|
|$\epsilon_{g,z}^{CO_2}$|For every generator $g$, the parameter reflects the specific $CO_2$ emission intensity in t$CO_2$/MWh associated with its operation|
|$VREIndex_{r,z}$|Parameter $VREIndex_{r,z}$, is used to keep track of the first bin, where $VREIndex_{r,z}=1$ for the first bin and $VREIndex_{r,z}=0$ for the remaining bins|
|$\tau_{f,z}^{advance/delay}$|the maximum time this demand can be advanced and delayed, defined by parameters, $\tau_{f,z}^{advance}$ and $\tau_{f,z}^{delay}$, respectively|
|$\mu_{y,z}^{stor}$|referring to the ratio of energy capacity to discharge power capacity, is used to define the available reservoir storage capacity|
|$\overline{R}_{s,z}^{\textrm{E,ENE}}$|For storage resources where upper bound $\overline{R}_{s,z}^{\textrm{E,ENE}}$ is defined, then we impose constraints on maximum storage energy capacity|
|$\underline{R}_{s,z}^{\textrm{E,ENE}}$|For storage resources where lower bound $\underline{R}_{s,z}^{\textrm{E,ENE}}$ is defined, then we impose constraints on minimum storage energy capacity|
|$\Omega_{k,z}^{\textrm{E,THE,size}}$|is the thermal unit size|
|$\kappa_{k,z,t}^{\textrm{E,UP/DN}}$|is the maximum ramp-up or ramp-down rate as a percentage of installed capacity|
|$\underline{\rho}_{k,z}^{\textrm{E,THE}}$|is the minimum stable power output per unit of installed capacity|
|$\overline{\rho}_{k,z,t}^{\textrm{E,THE}}$|is the maximum available generation per unit of installed capacity|
|$\omega_t$|weight of each model time step $\omega_t = 1 \forall t \in \mathcal{T}$ when modeling each time step of the year at an hourly resolution [1/year]|
---
