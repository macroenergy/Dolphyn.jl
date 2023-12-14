# LFSC Model Notation

## Model Indices and Sets
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$z \in \mathcal{Z}$ | $z$ denotes a zone and $\mathcal{Z}$ is the set of zones in the network|
|$t \in \mathcal{T}$ | $t$ denotes an time step and $\mathcal{T}$ is the set of time steps|
|$t \in \mathcal{T}^{start}$|This set of time-coupling constraints wrap around to ensure the output in the first time step of each year (or each representative period)|
|$t \in \mathcal{T}^{interior}$|This set of time-coupling constraints wrap around to ensure the output in the inner time step of each year (or each representative period)|
|$f \in \mathcal{F}$ | Index and set of all synthetic fuels resources|
|$b \in \mathcal{B}$ | Index and set of all synthetic fuels process byproducts|

## Decision Variables
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$x_{f,t}^{\textrm{C,Syn}}$| this term represents CO2 input by synthetic fuels resource $f$ at time period $t$|
|$x_{f,b,t}^{\textrm{By,Syn}}$| this term represents the byproducts $b$ produced by synthetic fuels resource $f$ at time period $t$|
|$y_{f,t}^{\textrm{C,Syn}}$| capacity of synthetic fuels resources in the liquid fuels supply chain|
|$x_{z,t}^{\textrm{Gasoline,Conv}}$| this term represents conventional gasoline purchased by zone $z$ at time period $t$|
|$x_{z,t}^{\textrm{Jetfuel,Conv}}$| this term represents conventional jetfuel purchased by zone $z$ at time period $t$|
|$x_{z,t}^{\textrm{Diesel,Conv}}$| this term represents conventional diesel purchased by zone $z$ at time period $t$|

## Parameters
---  
|**Notation** | **Description**|
| :------------ | :-----------|
|$\textrm{c}_{f}^{\textrm{Syn,INV}}$| investment cost per tonne CO2 input of synthetic fuels resource|
|$\textrm{c}_{f}^{\textrm{Syn,FOM}}$| fixed operation cost per tonne CO2 input of synthetic fuels resource|
|$\textrm{c}_{f}^{\textrm{Syn,VOM}}$| variable operation cost per tonne of CO2 input by synthetic fuels resource|
|$\textrm{c}_{g}^{\textrm{Syn,FUEL}}$| fuel cost per tonne of CO2 input by synthetic fuels resource|
|$\textrm{c}_{b}^{\textrm{By,Syn}}$| selling price per mmbtu of byproduct by synthetic fuels resource (if any)|
|$\textrm{c}_{z}^{\textrm{Gasoline,Conv}}$| purchase cost per mmbtu of conventional gasoline|
|$\textrm{c}_{z}^{\textrm{Jetfuel,Conv}}$| purchase cost per mmbtu of conventional jetfuel|
|$\textrm{c}_{z}^{\textrm{Diesel,Conv}}$| purchase cost per mmbtu of conventional diesel|
|$\overline{y}_{f}^{\textrm{\textrm{C,Syn}}}$|upper bound of capacity is defined,then we impose constraints on maximum CO2 input capacity of synthetic fuels resource|
|$\underline{y}_{f}^{\textrm{\textrm{C,Syn}}}$|lower bound of capacity is defined,then we impose constraints on minimum CO2 input capacity of synthetic fuels resource|

---