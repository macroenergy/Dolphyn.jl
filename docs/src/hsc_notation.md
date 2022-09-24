# HSC Model Notation

## Model Indices and Sets
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$z \in \mathcal{Z}$ | $z$ denotes a zone and $\mathcal{Z}$ is the set of zones in the network|
|$t \in \mathcal{T}$ | $t$ denotes an time step and $\mathcal{T}$ is the set of time steps|
|$k \in \mathcal{K}$ | Index and set of thermal generation resources in hydrogen energy system representing hydrogen production resource|
|$g \in \mathcal{G}$ | Index and set of all hydrogen generation resources (electrolysis, SMR plants and hydrogen storage devices)|
|$s \in \mathcal{S}$ | Index and set of storage resources in hydrogen energy system representing hydrogen storage devices such as underground or above-ground storage|

## Decision Variables
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$\textrm{c}_{z}^{\textrm{H,EMI}}$| Cost of per ton carbon dioxide emitted in the hydrogen supply chain |
|$x_{z,t}^{\textrm{H,EMI}}$| The amount of carbon dioxide emitted by the hydrogen supply chain at time $t$ in region $z$ |
|$y_{g,z}^{\textrm{H,GEN,existing}}$| existing capacity, energy storage resources in hydrogen sector |
|$y_{g,z}^{\textrm{H,GEN,new}}$| the newly invested capacity, energy storage resources in hydrogen sector |
|$y_{g,z}^{\textrm{H,GEN,retired}}$| retired capacity, energy storage resources in hydrogen sector |
|$\textrm{c}_{g}^{\textrm{H,INV}}$| equipment investment cost per ton of hydrogen production capacity|
|$\textrm{c}_{g}^{\textrm{H,FOM}}$| |
|$\textrm{c}^{\textrm{H,GEN,c}}$| additional investment costs of hydrogen production |
|$x_{s,z,t}^{\textrm{H,NSD}}$| this term represents the total amount of hydrogen demand curtailed in demand segment $s$ at time period $t$ in zone $z$ |
|$\textrm{n}_{s}^{\textrm{H,NSD}}$| this term represents the marginal willingness to pay for hydrogen demand of this segment of demand|
|$\textrm{D}_{z, t}^{\textrm{H}}$| hydrogen demand in zone $z$ at time $t$|
|$x_{k,z,t}^{\textrm{H,GEN}}$| this term represents hydrogen injected into the grid by hydrogen generation resource $k$ in zone $z$ at time period $t$|
|$x_{s,z,t}^{\textrm{\textrm{H,DIS}}}$| this term represents hydrogen injected into the grid by hydrogen storage resource $s$ in zone $z$ at time period $t$|
|$\textrm{C}^{\textrm{H,GEN,o}}$| total generation cost for per tonne of hydrogen from hydrogen generation plants |
|$\textrm{c}_{g}^{\textrm{H,FUEL}}$| fuel cost for hydrogen generation plants |
|$\textrm{c}_{g}^{\textrm{H,VOM}}$| variable cost for hydrogen generation plants |
|$\rho_{y,z,t}^{max}$| maximum deferrable demand as a fraction of available capacity in a particular time step $t$| 
|$\tau_{y,z}^{advance/delay}$|the maximum time this demand can be advanced and delayed, defined by parameters, $\tau_{y,z}^{advance}$ and $\tau_{y,z}^{delay}$,respectively|
|$\eta_{y,z}^{dflex}$|the energy losses associated with shifting demand|
|$\Gamma_{y,z,t}$|the amount of deferred demand remaining to be served|
|$\Theta_{y,z,t}$|the served demand during time step $t$|
|$\Delta_{y,z}^{total}$|the available capacity for Bounds on available demand flexibility|
|$y_{g}^{\textrm{\textrm{H,G2P,retired}}}$||
|$y_{g}^{\textrm{\textrm{H,G2P,existing}}}$||
|$\overline{y}_{g}^{\textrm{\textrm{H,G2P}}}$|upper bound of capacity is defined,then we impose constraints on maximum power capacity|
|$\underline{y}_{g}^{\textrm{\textrm{H,G2P}}}$|lower bound of capacity is defined,then we impose constraints on minimum power capacity|
|$n_{k,z,t}^{\textrm{H,G2P}}$|the commitment state variable of generator cluster $k$ in zone $z$ at time $t$|
|$n_{k,z,t}^{\textrm{H,G2P,UP}}$|the number of startup decision variable  of generator cluster $k$ in zone $z$ at time $t$|
|$n_{k,z,t}^{\textrm{H,G2P,DN}}$|the number of shutdown decision variable of generator cluster $k$ in zone $z$ at time $t$|
|$n_{k,z,t}^{\textrm{H,G2P}}$| designates the commitment state of generator cluster $k$ in zone $z$ at time $t$|
|$n_{k,z,t}^{\textrm{H,G2P,UP}}$| this term represents number of startup decisions|
|$n_{k,z,t}^{\textrm{H,G2P,DN}}$| this term represents number of shutdown decisions|
|$y_{k,z}^{\textrm{H,G2P}}$| this term is the total installed capacity of hydrogen to power plants|
|$x_{k,z,t}^{\textrm{H,G2P}}$|representing energy injected into the grid by hydrogen to power resource $k$ in zone $z$ at time period $t$|
|$x_{z,t}^{\textrm{E,H-GEN}}$|representing power consumed by electrolyzers in zone $z$ at time period $t$|
|$\tau_{k,z}^{\textrm{H,UP}}$ and $\tau_{k,z}^{\textrm{H,DN}}$|is the minimum up or down time for units in generating cluster $k$ in zone $z$|
|$z \in \mathcal{Z}^{CO_2}_{p,mass}$ |we define a set of zones that can trade CO$_2$ allowance|
|$\epsilon_{z,p,load}^{maxCO_2}$| denotes the emission limit in terms on tCO$_2$/MWh|
|$U_{s,z,t}^{\textrm{H,STO}}$| this term represents initial hydrogen stored in the storage device $s$ in zone $z$ at all starting time period $t$ of modeled periods|
|$\Delta U_{s,z,m}^{\textrm{H,STO}}$| this term represents the change of storage hydrogen inventory level of the storage device $s$ in zone $z$ during each representative period $m$|
|$U_{s,z,t}^{\textrm{H,STO}}$| this term represents hydrogen stored in the storage device $s$ in zone $z$ at time period $t$|
|$x_{s,z,t}^{\textrm{H,CHA}}$| this term represents charged hydrogen into the storage device $s$ in zone $z$ at time period $t$|
|$\eta_{s,z}^{\textrm{H,loss}}$| the self discharge rate for the storage resource|
|$y_{s,z}^{\textrm{H,STO,ENE}}$| the installed energy storage capacity|
|$y_{s,z}^{\textrm{H,STO,POW}}$| the installed power capacity |
|$\overline{R}_{s,z}^{\textrm{H,CHA}}$|For storage resources where upper bound is defined, then we impose constraints on minimum and maximum storage charge capacity|
|$\underline{R}_{s,z}^{\textrm{H,CHA}}$|For storage resources where lower bound is defined, then we impose constraints on minimum and maximum storage charge capacity|
|$\overline{\Omega}_{y,z}^{energy}$|is defined to constraints on maximum power capacity|
|$\underline{\Omega_{y,z}^{energy}}$|is defined to constraints on minimum power capacity|
|$y_{i,z \rightarrow z^{\prime}}^{\textrm{H,PIP}}$|the hydrogen pipeline construction decision variable  representing newly constructed hydrogen pipeline of type $i$ through path $z \rightarrow z^{\prime}$|
|$x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}}$|the hydrogen pipeline flow decision variable representing hydrogen flow via pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$|
|$U_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}}$|the hydrogen pipeline storage level decision variable representing hydrogen stored in pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$|
|$v_{CAP,j}^{\textrm{H,TRU}}$|the total number of  carbon capture of existing truck ??this may be is a error ,should let H truck replace CAP truck.|
|$v_{RETCAP,j}^{\textrm{H,TRU}}$|the total number of carbon capture of Truck retirements  |
|$v_{NEWCAP,j}^{\textrm{H,TRU}}$|the total number of carbon capture of newly add Truck    |



## Parameters
---


|**Notation** | **Description**|
| :------------ | :-----------|
|$\rho^{max}_{y,z,t}$| the availability factor for Bounds on available demand flexibility |
|$\Omega_{k,z}^{\textrm{H,G2P,size}}$|is the unit size|
|$\epsilon_{y,z}^{CO_2}$|the parameter  reflects the specific $CO_2$ emission intensity in tCO$_2$/MWh associated with its operation|

---