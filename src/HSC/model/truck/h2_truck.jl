"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
    h2_truck(EP::Model, inputs::Dict, setup::Dict)

This function includes three parts of the Truck Model.The details can be found seperately in"h2_truck_investment.jl" "h2_long_duration_truck.jl"and "h2_truck_all.jl".
    **Variables**

The sum of full and empty trucks should equal the total number of invested trucks.
```math
\begin{aligned}
    v_{j, t}^{\mathrm{F}}+v_{j, t}^{\mathrm{E}}=V_{j} \quad \forall j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}    
```
        
The full (empty) trucks include full (empty) trucks in transit and staying at each zones.
```math
\begin{aligned}
    v_{j, t}^{\mathrm{F}}=\sum_{z \rightarrow z^{\prime} \in \mathbb{B}} u_{z \rightarrow z, \prime^{\prime}, t}^{\mathrm{F}}+\sum_{z \in \mathbb{Z}} q_{z, j, t}^{\mathrm{F}} \\
    v_{j, t}^{\mathrm{E}}=\sum_{z \rightarrow z^{\prime} \in \mathbb{B}} u_{z \rightarrow z,,^{\prime}, t}^{\mathrm{E}}+\sum_{z \in \mathbb{Z}} q_{z, j, t}^{\mathrm{E}} \quad \forall j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}    
```
        
**Expressions**
        
The change of the total number of full (empty) available trucks at zone z should equal the number of charged (discharged) trucks minus the number of discharged (charged) trucks at zone z plus the number of full (empty) trucks that just arrived minus the number of full (empty) trucks that just departed:
```math
{\begin{aligned}
    q_{z, j, t}^{\mathrm{F}}-q_{z, j, t-1}^{\mathrm{F}}=& q_{z, j, t}^{\mathrm{CHA}}-q_{z, j, t}^{\mathrm{DIS}} \\
    &+\sum_{z^{\prime} \in \mathbb{Z}}\left(-x_{z \rightarrow z,{ }^{\prime} j, t-1}^{\mathrm{F}}+y_{z \rightarrow z, j, t-1}^{\mathrm{F}}\right) \\
    q_{z, j, t}^{\mathrm{E}}-q_{z, j, t-1}^{\mathrm{E}}=&-q_{z, j, t}^{\mathrm{CHA}}+q_{z, j, t}^{\mathrm{DIS}} \\
    &+\sum_{z^{\prime} \in \mathbb{Z}}\left(-x_{z \rightarrow z,,^{\prime} j, t-1}^{\mathrm{E}}+y_{z \rightarrow z,,^{\prime} j, t-1}^{\mathrm{E}}\right) \\
    \forall z \in \mathbb{Z}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}
```
        
The change of the total number of full (empty) trucks in transit from zone z to zone zz should equal the number of full (empty) trucks that just departed from zone z minus the number of full (empty) trucks that just arrived at zone zz:
```math
\begin{aligned}
    u_{z \rightarrow z,{ }^{\prime} j, t}^{\mathrm{F}}-u_{z \rightarrow z,{ }^{\prime} j, t-1}^{\mathrm{F}} & =x_{z \rightarrow z,{ }^{\prime} j, t-1}^{\mathrm{F}}-y_{z \rightarrow z,{ }^{\prime} j, t-1}^{\mathrm{F}} \\
    u_{z \rightarrow z,{ }^{\prime} j, t}^{\mathrm{E}}-u_{z \rightarrow z,{ }^{\prime} j, t-1}^{\mathrm{E}} & =x_{z \rightarrow z,^{\prime} j, t-1}^{\mathrm{E}}-y_{z \rightarrow z,{ }^{\prime} j, t-1}^{\mathrm{E}} \\
    & \forall z \rightarrow z^{\prime} \in \mathbb{B}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}    
```
        
The amount of H2 delivered to zone z should equal the truck capacity times the number of discharged trucks minus the number of charged trucks, adjusted by theH2 boil-off loss during truck transportation and compression.
```math
\begin{aligned}
    h_{z, j, t}^{\mathrm{TRU}}=\left[\left(1-\sigma_{j}\right) q_{z, j, t}^{\mathrm{DIS}}-q_{z, j, t}^{\mathrm{CHA}}\right] \overline{\mathrm{E}}_{j}^{\mathrm{TRU}} \\
    \forall z \rightarrow z^{\prime} \in \mathbb{B}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}    
```
        
The minimum travelling time delay is modelled as follows.
```math
\begin{aligned}
    u_{z \rightarrow z,{ }^{\prime} j, t}^{\mathrm{F}} \geq \sum_{e=t-\Delta_{z \rightarrow z^{\prime}+1}}^{e=t} x_{z \rightarrow z,^{\prime} j, e}^{\mathrm{F}} \\
    u_{z \rightarrow z,^{\prime} j, t}^{\mathrm{E}} \geq \sum_{e=t-\Delta_{z \rightarrow z^{\prime}+1}}^{e=t} x_{z \rightarrow z, j, e}^{\mathrm{E}} \quad \forall z \rightarrow z^{\prime} \in \mathbb{B}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}
```
        
```math
\begin{aligned}
    u_{z \rightarrow z,^{\prime}j, t}^{\mathrm{F}} \geq \sum_{e=t+1}^{e=t+\Delta_{z \rightarrow z^{\prime}}} y_{z \rightarrow z,^{\prime} j, e}^{\mathrm{F}} \\
    u_{z \rightarrow z, j, t}^{\mathrm{E}} \geq \sum_{e=t+1}^{e=t+\Delta_{z \rightarrow z^{\prime}}} y_{z \rightarrow z,^{\prime} j, e}^{\mathrm{E}} \\
    \forall z \rightarrow z^{\prime} \in \mathbb{B}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}   
```
        
**Constraints**
        
The charging capability of truck stations is limited by their compression or liquefaction capacity.
```math
\begin{aligned}
    q_{z, j, t}^{\mathrm{CHA}} \overline{\mathrm{E}}_{j}^{\mathrm{TRU}} \leq H_{z, j}^{\mathrm{TRU}} \quad \forall z \in \mathbb{Z}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}    
``` 
"""
function h2_truck(EP::Model, inputs::Dict, setup::Dict)

    println("Hydrogen Truck Module")

    # investment variables expressions and related constraints for H2 trucks
    EP = h2_truck_investment(EP::Model, inputs::Dict, setup::Dict)

     # Operating variables, expressions and constraints related to H2 trucks
    EP = h2_truck_all(EP, inputs, setup)

    # Include LongDurationtruck only when modeling representative periods
    if setup["OperationWrapping"] == 1
        EP = h2_long_duration_truck(EP, inputs)
    end
    
    return EP
end
