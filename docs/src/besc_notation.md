# BESC Model Notation

## Model Indices and Sets
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$z \in \mathcal{Z}$ | $z$ denotes a zone and $\mathcal{Z}$ is the set of zones in the network|
|$t \in \mathcal{T}$ | $t$ denotes an time step and $\mathcal{T}$ is the set of time steps|
|$t \in \mathcal{T}^{start}$|This set of time-coupling constraints wrap around to ensure the output in the first time step of each year (or each representative period)|
|$t \in \mathcal{T}^{interior}$|This set of time-coupling constraints wrap around to ensure the output in the inner time step of each year (or each representative period)|
|$r \in \mathcal{R}$ | Index and set of all bioenergy resources|
|$r \in \herb$ | Index and set of all bioenergy resources taking in herbaceous biomass as inputs|
|$r \in \wood$ | Index and set of all bioenergy resources taking in woody biomass as inputs|

## Decision Variables
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$x_{r,t}^{\textrm{B,Bio}}$| this term represents biomass input by biorefinery resource $r$ at time period $t$|
|$x_{z,t}^{\textrm{B,Herb}}$| this term represents herbaceous biomass supply utilized in zone $z$ at time period $t$|
|$x_{z,t}^{\textrm{B,Wood}}$| this term represents woody biomass supply utilized in zone $z$ at time period $t$|
|$y_{r,t}^{\textrm{B,Bio}}$| capacity of biorefinery resources in the bioenergy supply chain|

## Parameters
---  
|**Notation** | **Description**|
| :------------ | :-----------|
|$\textrm{c}_{r}^{\textrm{Bio,INV}}$| investment cost per tonne biomass input of biorefinery resource|
|$\textrm{c}_{r}^{\textrm{Bio,FOM}}$| fixed operation cost per tonne biomass input of biorefinery resource|
|$\textrm{c}_{r}^{\textrm{Bio,VOM}}$| variable operation cost per tonne of biomass input of biorefinery resource|
|$\textrm{c}_{r}^{\textrm{Bio,FUEL}}$| fuel cost per tonne of CO2 input by synthetic fuels resource|
|$\textrm{c}_{z}^{\textrm{Herb,VOM}}$| purchase cost per tonne of herbaceous biomass|
|$\textrm{c}_{z}^{\textrm{Wood,VOM}}$| purchase cost per tonne of woody biomass|
|$\overline{x}_{z}^{\textrm{\textrm{B,Herb}}}$|upper bound of hourly availablility of herbaceous biomass|
|$\overline{x}_{z}^{\textrm{\textrm{B,Wood}}}$|upper bound of hourly availablility of woody biomass|
|$\overline{\textrm{R}}_{r}^{\textrm{B,Bio}}$|For biorefinery where upper bound operation is defined, then we impose constraints on maximum operating capacity rate|
|$\underline{\textrm{R}}_{r}^{\textrm{B,Bio}}$|For biorefinery where lower bound operation is defined, then we impose constraints on minimum operating capacity rate|

---