# HSC Model Notation

## Model Indices and Sets
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$t \in \mathcal{T}$ | where $t$ denotes an time step and $\mathcal{T}$ is the set of time steps over which grid operations are modeled|
|$\mathcal{T}^{interior} \subseteq \mathcal{T}^{}$ | where $\mathcal{T}^{interior}$ is the set of interior timesteps in the data series|
|$\mathcal{T}^{start} \subseteq \mathcal{T}$ |  where $\mathcal{T}^{start}$ is the set of initial timesteps in the data series. $\mathcal{T}^{start}={1}$ when representing entire year as a single contiguous period; $\mathcal{T}^{start}=\{\left(m-1\right) \times \tau^{period}+1 \| m \in \mathcal{M}\}$, which corresponds to the first time step of each representative period $m \in \mathcal{M}$|
|$n \in \mathcal{N}$ | where $n$ corresponds to a contiguous time period and $\mathcal{N}$ corresponds to the set of contiguous periods of length $\tau^{period}$ that make up the input time series (e.g. load, variable renewable energy availability) to the model|
|$\mathcal{N}^{rep} \subseteq \mathcal{N}$ | where $\mathcal{N}^{rep}$ corresponds to the set of representative time periods that are selected from the set of contiguous periods $\mathcal{M}$|
|$m \in \mathcal{M}$ | where $m$ corresponds to a representative time period and $\mathcal{M}$ corresponds to the set of representative time periods indexed as per their chronological ocurrence in the set of contiguous periods spanning the input time series data, i.e. $\mathcal{N}$|
$z \in \mathcal{Z}$ | where $z$ denotes a zone and $\mathcal{Z}$ is the set of zones in the network|
|$z \rightarrow z^{\prime} \in \mathcal{B}$ |where $z \rightarrow z^{\prime}$ denotes paths for different transport routes of hydrogen flow via pipelines and trucks|
|$l \in \mathcal{L}$ | where $l$ denotes a transmission line and $\mathcal{L}$ is the set of transmission lines in the network of hydrogen|
|$y \in \mathcal{G}$ | where $y$ denotes a technology and $\mathcal{G}$ is the set of available technologies in hydrogen system|
|$\mathcal{H} \subseteq \mathcal{G}$ | where $\mathcal{H}$ is the subset of thermal resources in hydrogen system|
|$\mathcal{UC} \subseteq \mathcal{H}$ | where $\mathcal{UC}$ is the subset of thermal resources subject to unit commitment constraints|
|$s \in \mathcal{S}$ | where $s$ denotes a segment and $\mathcal{S}$ is the set of consumers segments for price-responsive demand curtailment|
|$p \in \mathcal{P}$ | where $p$ denotes a instance in the policy set $\mathcal{P}$|
|$\mathcal{P}^{ESR} \subseteq \mathcal{P}$ | Energy Share Requirement type policies |
|$\mathcal{P}^{CO_2} \subseteq \mathcal{P}$ | CO$_2$ emission cap policies|
|$\mathcal{P}^{CO_2}_{mass} \subseteq \mathcal{P}^{CO_2}$ | CO$_2$ emissions limit policy constraints, mass-based |
|$\mathcal{P}^{CO_2}_{load} \subseteq \mathcal{P}^{CO_2}$ | CO$_2$ emissions limit policy constraints, load emission-rate based |   
|$\mathcal{P}^{CO_2}_{gen} \subseteq \mathcal{P}^{CO_2}$ | CO$_2$ emissions limit policy constraints, generation emission-rate based |
|$\mathcal{P}^{CRM} \subseteq \mathcal{P}$ | Capacity reserve margin (CRM) type policy constraints |
|$\mathcal{P}^{MinTech} \subseteq \mathcal{P}$ | Minimum Capacity Carve-out type policy constraint |
|$\mathcal{Z}^{ESR}_{p} \subseteq \mathcal{Z}$ | set of zones eligible for ESR policy constraint $p \in \mathcal{P}^{ESR}$ |
|$\mathcal{Z}^{CRM}_{p} \subseteq \mathcal{Z}$ | set of zones that form the locational deliverable area for capacity reserve margin policy constraint $p \in \mathcal{P}^{CRM}$ |
|$\mathcal{Z}^{CO_2}_{p,mass} \subseteq \mathcal{Z}$ | set of zones are under the emission cap mass-based cap-and-trade policy constraint $p \in \mathcal{P}^{CO_2}_{mass}$ |
|$\mathcal{Z}^{CO_2}_{p,load} \subseteq \mathcal{Z}$ | set of zones are under the emission cap load emission-rate based cap-and-trade policy constraint $p \in \mathcal{P}^{CO_2}_{load}$ |
|$\mathcal{Z}^{CO_2}_{p,gen} \subseteq \mathcal{Z}$ | set of zones are under the emission cap generation emission-rate based cap-and-trade policy constraint $p \in \mathcal{P}^{CO2,gen}$ |


## Decision Variables
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$h_{i, z \rightarrow z^{\prime}, t}^{\mathrm{PIP+}}$ | Positive transported hydrogen through pipeline $i$ throught route $z \rightarrow z^{\prime}$ at time step $t$ [tonne-$\ce{H2}$] |
|$h_{i, z \rightarrow z^{\prime}, t}^{\mathrm{PIP-}}$ | Negtive transported hydrogen through pipeline $i$ throught route $z \rightarrow z^{\prime}$ at time step $t$ [tonne-$\ce{H2}$] |
|$\overline{\mathrm{E}}_{i}^{\mathrm{PIP}}$ | The maximum amount of hydrogen that could be storaed in the pipeline $i$ [tonne-$\ce{H2}$] |
|$v_{j, t}^{\mathrm{F}}$ | Number of full hydrogen or carbon trucks of type $j$ at time $t$ |
|$v_{j, t}^{\mathrm{E}}$ | Number of empty hydrogen or carbon trucks of type $j$ at time $t$ |
|$v_{j}^{TRU}$ | Total number of hydrogen trucks of type $j$ |
|$u_{j, z \rightarrow z^{\prime}, t}^{\mathrm{F}}$ | Number of full or empty hydrogen or carbon trucks of type $j$ in transit from $z$ to $z^{\prime}$ at time $t |
|$q_{z, j, t}^{\mathrm{F}}$ | Number of full hydrogen or carbon trucks of type $j$ available at $z$ at time $t$ |
|$q_{z, j, t}^{\mathrm{E}}$ | Number of empty hydrogen or carbon trucks of type $j$ available at $z$ at time $t$ |
|$q_{z, j, t}^{\mathrm{CHA}}$ | Number of charged hydrogen or carbon trucks of type $j$ available at $z$ at time $t$ |
|$q_{z, j, t}^{\mathrm{DIS}}$ | Number of discharged hydrogen or carbon trucks of type $j$ available at $z$ at time $t$ |
|$h_{z, j, t}^{\mathrm{TRU}}$ | Amount of transprted hydrogen through truck rtype $j$ [tonne-$\ce{H2}$] |
|$u_{z \rightarrow z^{\prime} j, t}^{\mathrm{F}}$ | Number of full hydrogen or carbon trucks of type $j$ in transit from $z$ to $z^{\prime}$ at time $t$} |
|$u_{z \rightarrow z^{\prime} j, t}^{\mathrm{E}}$ | Number of empty hydrogen or carbon trucks of type $j$ in transit from $z$ to $z^{\prime}$ at time $t$} |
|$H_{z, j}^{\mathrm{TRU}}$ | Maximum compression/liquefaction capacity of hydrogen truck station type $j$ at zone $z$ [tonne-$\ce{H2}$] |
|$v_{CAP,j}^{TRU}$ | Capacity of truck type $j$ [tonne-$\ce{H2}$] |
|$v_{RETCAP,j}^{TRU}$ | Retired capacity of truck type $j$ [tonne-$\ce{H2}$] |
|$v_{NEWCAP,j}^{TRU}$ | New constructed capacity of truck type $j$ [tonne-$\ce{H2}$] |
|$v_{RETCAPNUM,j}^{TRU}$ | Retired number of hydrogen truck type $j$ |
|$v_{RETCAPEnergy,j}^{TRU}$ | Retired energy capacity of truck type $j$ [tonne-$\ce{H2}/hour$] |


## Parameters
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$\delta_{i}^{\mathrm{PIP}}$ | Annuity factor for pipeline resources |
|$\overline{\mathrm{F}}_{i}$ | The maximum injecting/withdrawing flow rate of the pipeline $i$ for hydrogen |
|$\sigma_{j}$| Loss efficiency through truck transmission [%]|
|$\overline{\mathrm{E}}_{j}^{\mathrm{TRU}}$ | Capacity of hydrogen truck type $j$ [tonne-$\ce{H2}$] |
|$v_{ExistEnergyCap,j}^{TRU}$ | Existing energy capacity of truck type $j$ [tonne-$\ce{H2}/hour$] |
|$C_{\mathrm{TRU}}^{\mathrm{o}}$ | Unit cost of operation truck type $j$ |
|$v_{ExistNum,j}^{TRU}$ | Existing number of hydrogen truck type $j$ |
---