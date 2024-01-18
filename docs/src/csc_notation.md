# CSC Model Notation

## Model Indices and Sets
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$z \in \mathcal{Z}$ | $z$ denotes a zone and $\mathcal{Z}$ is the set of zones in the network|
|$t \in \mathcal{T}$ | $t$ denotes an time step and $\mathcal{T}$ is the set of time steps|
|$t \in \mathcal{T}^{start}$|This set of time-coupling constraints wrap around to ensure the output in the first time step of each year (or each representative period)|
|$t \in \mathcal{T}^{interior}$|This set of time-coupling constraints wrap around to ensure the output in the inner time step of each year (or each representative period)|
|$d \in \mathcal{D}$ | Index and set of all DAC  resources|
|$k \in \mathcal{K}$ | Index and set of all CO2 compression resources|
|$s \in \mathcal{S}$ | Index and set of storage resources in CO2 supply chain representing geological sequestration|

## Decision Variables
---
|**Notation** | **Description**|
| :------------ | :-----------|
|$x_{d,z,t}^{\textrm{C,DAC}}$| this term represents CO2 captured by DAC resource $d$ in zone $z$ at time period $t$|
|$x_{k,z,t}^{\textrm{C,COMP}}$| this term represents DAC-captured CO2 compressed by CO2 compression generation resource $k$ in zone $z$ at time period $t$|
|$x_{s,z,t}^{\textrm{C,INJ}}$| this term represents CO2 injected into the CO2 storage resource $s$ in zone $z$ at time period $t$|
|$x_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP}}$|the CO2 pipeline flow decision variable representing CO2 flow via pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$|
|$y_{d,z}^{\textrm{C,DAC}}$| capacity of DAC resources in the CO2 supply chain|
|$y_{k,z}^{\textrm{C,COMP}}$| capacity of CO2 compression resources in the CO2 supply chain|
|$y_{s,z}^{\textrm{C,STO}}$|  capacity of CO2 storage in the CO2 supply chain|
|$y_{i,z \rightarrow z^{\prime}}^{\textrm{C,PIP}}$|the CO2 pipeline construction decision variable representing newly constructed CO2 pipeline of type $i$ through path $z \rightarrow z^{\prime}$|
|$U_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP}}$|the CO2 pipeline storage level decision variable representing CO2 stored in pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$|

## Parameters
---

|**Notation** | **Description**|
| :------------ | :-----------|
|$\textrm{c}_{d}^{\textrm{DAC,INV}}$| investment cost per tonne of DAC capture capacity|
|$\textrm{c}_{d}^{\textrm{DAC,FOM}}$| fixed operation cost per tonne of DAC capture capacity|
|$\textrm{c}_{d}^{\textrm{DAC,VOM}}$| variable operation cost per tonne of CO2 captured by DAC|
|$\textrm{c}_{g}^{\textrm{DAC,FUEL}}$| fuel cost per tonne of CO2 captured by DAC|
|$\textrm{c}_{k}^{\textrm{COMP,INV}}$| investment cost per tonne of CO2 compression capacity|
|$\textrm{c}_{k}^{\textrm{COMP,FOM}}$| fixed operation cost per tonne of CO2 compression capacity|
|$\textrm{c}_{s}^{\textrm{STO,INV}}$| investment cost per tonne of CO2 storage capacity|
|$\textrm{c}_{s}^{\textrm{STO,FOM}}$| fixed operation cost per tonne of CO2 storage capacity|
|$\textrm{c}_{s}^{\textrm{INJ,VOM}}$| variable operation cost per tonne of CO2 injected into CO2 storage by DAC|
|$\overline{y}_{d}^{\textrm{\textrm{C,DAC}}}$|upper bound of capacity is defined,then we impose constraints on maximum DAC capacity|
|$\underline{y}_{d}^{\textrm{\textrm{C,DAC}}}$|lower bound of capacity is defined,then we impose constraints on minimum DAC capacity|
|$\overline{y}_{k}^{\textrm{\textrm{C,COMP}}}$|upper bound of capacity is defined,then we impose constraints on maximum CO2 compression capacity|
|$\underline{y}_{k}^{\textrm{\textrm{C,COMP}}}$|lower bound of capacity is defined,then we impose constraints on minimum CO2 compression capacity|
|$\overline{y}_{s}^{\textrm{\textrm{C,STO}}}$|upper bound of capacity is defined,then we impose constraints on maximum CO2 storage capacity|
|$\underline{y}_{s}^{\textrm{\textrm{C,STO}}}$|lower bound of capacity is defined,then we impose constraints on minimum CO2 storage capacity|
|$\overline{x}_{s}^{\textrm{\textrm{C,INJ}}}$|upper bound of rate is defined,then we impose constraints on maximum CO2 injection rate|
|$\overline{\textrm{R}}_{d,z,t}^{\textrm{C,DAC}}$|For DAC where upper bound operation is defined, then we impose constraints on maximum operating capacity rate|
|$\underline{\textrm{R}}_{d,z}^{\textrm{C,DAC}}$|For DAC where lower bound operation is defined, then we impose constraints on minimum operating capacity rate|
|$\overline{\textrm{R}}_{k,z}^{\textrm{C,COMP}}$|For CO2 compression where upper bound operation is defined, then we impose constraints on maximum operating capacity rate|
|$\underline{\textrm{R}}_{k,z}^{\textrm{C,COMP}}$|For CO2 compression where lower bound operation is defined, then we impose constraints on minimum operating capacity rate|
|$\overline{\textrm{R}}_{k,z}^{\textrm{C,INJ}}$|For CO2 injection where upper bound operation is defined, then we impose constraints on maximum injection rate|
|$\underline{\textrm{R}}_{k,z}^{\textrm{C,INJ}}$|For CO2 injection where lower bound operation is defined, then we impose constraints on minimum injection rate|
---
