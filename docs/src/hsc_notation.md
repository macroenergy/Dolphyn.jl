# HSC Model Notation

## Model Indices and Sets
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$z \in \mathcal{Z}$ | where $z$ denotes a zone and $\mathcal{Z}$ is the set of zones in the network|
|$t \in \mathcal{T}$ | where $t$ denotes an time step and $\mathcal{T}$ is the set of time steps|
|$k \in \mathcal{K}$ |Index and set of generation resources.  in hydrogen energy system, it represents hydrogen production resource}|
|$g \in \mathcal{G}$||
|$s \in \mathcal{S}$|Index and set of storage resources. in hydrogen energy system, it represents hydrogen storage devices such as underground or above-ground storage|
|$T$|Set of time intervals}|
|c|Superscript for capital cost|
|||


## Decision Variables
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$\textrm{c}_{z}^{\textrm{H,EMI}}$|   Cost of per ton carbon dioxide emitted in the hydrogen supply chain |
|$x_{z,t}^{\textrm{H,EMI}}$|    The amount of carbon dioxide emitted by the hydrogen supply chain at time t in region Z   |
|$y_{g}^{\textrm{H,GEN,existing}}$|    existing capacity , energy storage resources in hydrogen sector    |
|$y_{g}^{\textrm{H,GEN,new}}$|    the newly invested capacity,    energy storage resources in hydrogen sector     |
|$y_{g}^{\textrm{H,GEN,retired}}$|   retired capacity,    energy storage resources in hydrogen sector    |
|$\textrm{c}_{g}^{\textrm{H,INV}}$|  equipment investment cost per ton of hydrogen production capacity|
|$\textrm{c}_{g}^{\textrm{H,FOM}}$|   I understand that this should be the depreciation cost factor   |
|$\textrm{c}^{\textrm{H,GEN,c}}$|    additional investment costs of hydrogen production |
|$x_{s,z,t}^{\textrm{H,NSD}}$  $\forall z \in \mathcal{Z}, \forall t \in \mathcal{T}$|representing the total amount of hydrogen demand curtailed in demand segment $s$ at time period $t$ in zone $z$.$ |
|$\textrm{n}_{s}^{\textrm{H,NSD}}$| representing the marginal willingness to pay for hydrogen demand of this segment of demand|
|$\textrm{D}_{z, t}^{\textrm{H}}$| note that the current implementation assumes demand segments are an equal share of hourly load in all zones|
|$x_{k,z,t}^{\textrm{H,GEN}} \forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$| representing hydrogen injected into the grid by hydrogen generation resource $k$ in zone $z$ at time period $t$|
|$x_{s,z,t}^{\textrm{\textrm{H,DIS}}} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$|representing hydrogen injected into the grid by hydrogen storage resource $s$ in zone $z$ at time period $t$|
|$\textrm{C}^{\textrm{H,GEN,o}}$|              |
|$\textrm{c}_{g}^{\textrm{H,FUEL}}$|               |
|$\textrm{c}_{g}^{\textrm{H,VOM}}$|                |
|$\rho^{max}_{y,z,t}$| maximum deferrable demand as a fraction of available capacity in a particular time step $t$| 
|$\tau^{advance/delay}_{y,z}$|the maximum time this demand can be advanced and delayed, defined by parameters, $\tau^{advance}_{y,z}$ and $\tau^{delay}_{y,z}$,respectively|
|$\eta_{y,z}^{dflex}$|the energy losses associated with shifting demand|
|$\Gamma_{y,z,t}$|the amount of deferred demand remaining to be served|
|$\Theta_{y,z,t}$|the served demand during time step $t$|
|$\Pi_{y,z,t}$|the demand that has been deferred during the current time step|
|$\Delta^{total}_{y,z}$|the available capacity for Bounds on available demand flexibility|
|$y_{g}^{\textrm{\textrm{H,G2P},retired}}$||
|$y_{g}^{\textrm{\textrm{H,G2P},existing}}$||
|$\overline{y_{g}^{\textrm{\textrm{H,G2P}}}}$|upper bound of capacity is defined,then we impose constraints on maximum power capacity|
|$\underline{y_{g}^{\textrm{\textrm{H,G2P}}}}$|lower bound of capacity is defined,then we impose constraints on minimum power capacity|
|$n_{k,z,t}^{\textrm{H,G2P}}$ $\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$|the commitment state variable of generator cluster $k$ in zone $z$ at time $t$|
|$n_{k,z,t}^{\textrm{H,G2P,UP}}$ $\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$|the number of startup decision variable  of generator cluster $k$ in zone $z$ at time $t$|
|$n_{k,z,t}^{\textrm{H,G2P,DN}}$ $\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$|the number of shutdown decision variable of generator cluster $k$ in zone $z$ at time $t$|
|$n_{k,z,t}^{\textrm{H,G2P}}$| designates the commitment state of generator cluster $k$ in zone $z$ at time $t$|
|$n_{k,z,t}^{\textrm{H,G2P,UP}}$| represents number of startup decisions|
|$n_{k,z,t}^{\textrm{H,G2P,DN}}$| represents number of shutdown decisions|
|$y_{k,z}^{\textrm{H,G2P}}$| is the total installed capacity|
|$x_{k,z,t}^{\textrm{H,G2P}} \forall k \in \mathcal{K}, z\in \mathcal{Z}, t \in \mathcal{T}$|representing energy injected into the grid by hydrogen to power resource $k$ in zone $z$ at time period $t$|
|$x_{z,t}^{\textrm{E,H-GEN}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$|representing power consumed by electrolyzers in zone $z$ at time period $t$|
|$\tau_{k,z}^{\textrm{H,UP}}$ and $\tau_{k,z}^{\textrm{H,DN}}$|is the minimum up or down time for units in generating cluster $k$ in zone $z$|
|$z \in \mathcal{Z}^{CO_2}_{p,mass}$ |we define a set of zones that can trade CO$_2$ allowance|
|$\epsilon_{z,p,load}^{maxCO_2}$| denotes the emission limit in terms on tCO$_2$/MWh|
|$U_{s,z,t}^{\textrm{H,STO}} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T_{p}^{start}}$|representing initial hydrogen stored in the storage device $s$ in zone $z$ at all starting time period $t$ of modeled periods|
|$\Delta U_{s,z,m}^{\textrm{H,STO}} \forall s \in \mathcal{S}, z \in \mathcal{Z}, m \in \mathcal{M}$|representing the change of storage hydrogen inventory level of the storage device $s$ in zone $z$ during each representative period $m$|
|$U_{s,z,t}^{\textrm{H,STO}} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$|representing hydrogen stored in the storage device $s$ in zone $z$ at time period $t$|
|$x_{s,z,t}^{\textrm{H,CHA}} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$|representing charged hydrogen into the storage device $s$ in zone $z$ at time period $t$|
|$\eta_{s,z}^{H,loss}$|the self discharge rate for the storage resource|
|$y_{s,z}^{\textrm{H,STO,ENE}}$|the installed energy storage capacity|
|$y_{s,z}^{\textrm{H,STO,POW}}$|the installed power capacity |
|$\overline{R_{s,z}^{\textrm{H,CHA}}}$|For storage resources where upper bound  is defined, then we impose constraints on minimum and maximum storage charge capacity|
|$\underline{R_{s,z}^{\textrm{H,CHA}}}$|For storage resources where lower bound  is defined, then we impose constraints on minimum and maximum storage charge capacity|
|$\overline{\Omega_{y,z}^{energy}}$|is defined to constraints on maximum power capacity|
|$\underline{\Omega_{y,z}^{energy}}$|is defined to constraints on minimum power capacity|
|$y_{i,z \rightarrow z^{\prime}}^{\textrm{H,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}$|the hydrogen pipeline construction decision variable  representing newly constructed hydrogen pipeline of type $i$ through path $z \rightarrow z^{\prime}$|
|$x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$|the hydrogen pipeline flow decision variable representing hydrogen flow via pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$|
|$U_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$|the hydrogen pipeline storage level decision variable representing hydrogen stored in pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$|
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