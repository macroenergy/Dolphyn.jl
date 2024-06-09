"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
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
    h2_carrier(EP::Model, inputs::Dict, setup::Dict)

This function includes the variables, expressions and objective funtion to model hydrogen carriers that convert H2 to a easily transportable/storable medium and return it as H2 in other zone.

This function expresses hydrogen exchange through pipeline i between two zones and can be split into H2 delivering and flowing out.

This module defines the hydrogen pipeline construction decision variable $y_{i,z \rightarrow z^{\prime}}^{\textrm{H,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}$, representing newly constructed hydrogen pipeline of type $i$ through path $z \rightarrow z^{\prime}$.

This module defines the hydrogen pipeline flow decision variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$, representing hydrogen flow via pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$.

This module defines the hydrogen pipeline storage level decision variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$, representing hydrogen stored in pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$.

The variable defined in this file named after ```vH2NPipe``` covers variable $y_{i,z \rightarrow z^{\prime}}^{\textrm{H,PIP}}$.

The variable defined in this file named after ```vH2PipeFlow_pos``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP+}}$.

The variable defined in this file named after ```vH2PipeFlow_neg``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP-}}$.

The variable defined in this file named after ```vH2PipeLevel``` covers variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}}$.

**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of generation (fixed OM plus construction) from all pipeline resources $i \in \mathcal{I}$:

```math
\begin{equation*}
    \textrm{C}^{\textrm{H,PIP,c}}=\delta_{i}^{\textrm{H,PIP}} \sum_{i \in \mathbb{I}} \sum_{z \rightarrow z^{\prime} \in \mathbb{B}} \textrm{c}_{i}^{\textrm{H,PIP}} \textrm{L}_{z \rightarrow z^{\prime}} l_{i,z \rightarrow z^{\prime}}
    h_{i,z \rightarrow z^{\prime}, t}^{\textrm{H,PIP}}=h_{i, z \rightarrow z^{\prime}, t}^{\textrm{H,PIP+}}-h_{i, z \rightarrow z^{\prime}, t}^{\textrm{PIP-}} \quad \forall i \in \mathbb{I}, z \rightarrow z^{\prime} \in \mathbb{B}, t \in \mathbb{T}
\end{equation*}
 ```

The flow rate of H2 through pipeline type $i$ is capped by the operational limits of the pipeline, multiplied by the number of constructed pipeline $i$
```math
\begin{equation*}
    \overline{\textrm{F}}_{i} l_{i,z \rightarrow z^{\prime}} \geq x_{i,z \rightarrow z^{\prime}, t}^{\textrm{\textrm{H,PIP+}}}, x_{i,z \rightarrow z^{\prime}, t}^{\textrm{\textrm{H,PIP-}}} \geq 0 \quad \forall i \in \mathbb{I}, z \rightarrow z^{\prime} \in \mathbb{B}, t \in \mathbb{T}
\end{equation*}    
```

The pipeline has storage capacity via line packing:
```math
\begin{equation*}
    \overline{\textrm{U}}_{i}^{\textrm{\textrm{H,PIP}}} l_{i,z \rightarrow z^{\prime}} \geq -\sum_{\tau=t_{0}}^{t}\left(x_{i,z^{\prime} \rightarrow z, \tau}^{\textrm{\textrm{H,PIP}}}+x_{i,z \rightarrow z^{\prime}, \tau}^{\textrm{\textrm{H,PIP}}}\right) \Delta t \geq \underline{\textrm{R}}_{i}^{\textrm{\textrm{H,PIP}}} \overline{\textrm{E}}_{i}^{\textrm{\textrm{H,PIP}}} l_{i,z \rightarrow z^{\prime}} \\
    & \forall z^{\prime} \in \mathbb{Z}, z \in \mathbb{Z}, i \in \mathbb{I}, t \in \mathbb{T}
\end{equation*}   
```

The change of hydrogen pipeline storage inventory is modeled as follows:
```math
\begin{equation*}
    U_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP}} - U_{i,z \rightarrow z^{\prime},t-1} = x_{i,z \rightarrow z^{\prime},t}^{\textrm{H,PIP-}} + x_{i,z^{\prime} \rightarrow z,t}^{\textrm{H,PIP-}}
\end{equation*}
```
"""
function h2_carrier_investment(EP::Model, inputs::Dict, setup::Dict)

    carrier_type = inputs["carrier_names"]
    process_type = inputs["carrier_process_names"]

    # Input data related to H2 carriers
    dfH2carrier = inputs["dfH2carrier"]
    
    # Matrix of allowed routes for carriers
    carrier_candidate_routes =inputs["carrier_candidate_routes"]
    # Convert each row to a tuple of source sink pairs eligible for carriers
    carrier_candidate_routes_tuple =inputs["carrier_candidate_routes_tuple"]

    # set of candidate source sinks for carriers
    carrier_source_sink = inputs["carrier_source_sink"]

    CARRIER_HYD = inputs["CARRIER_HYD"]
    CARRIER_DEHYD = inputs["CARRIER_DEHYD"]

    # Dictionary Mapping R_ID to carrier + process pairs
    R_ID =inputs["carrier_R_ID"]
   
    ### Variables ###
    # Installed capacity of process p in terms of H2 throughput, for carrier c in zone z (MW_H2)
    @variable(EP, vCarProcH2Cap[c in carrier_type, p in process_type, z in carrier_source_sink] >= 0) 

    if setup["H2CarrierStorageFunction"] == 0 # If we do not allow H2 carrier to provide storage function at the same site
    #1. Binary variable indicating selection of zone as source sink for carrier c and process p
        @variable(EP, vCarProcBuild[c in carrier_type, p in process_type, z in carrier_source_sink], Bin) 


    #2. Binary variable tracking feasible transport routes for each carrier
        @variable(EP, vCarTransportON[c in carrier_type, p in process_type, (z,z1) in carrier_candidate_routes_tuple], Bin) 

    end

    #  Installed capacity of rich carrier storage associated with process in zone z (tonne) 
    @variable(EP, vCarRichStorageCap[c in carrier_type, p in process_type, z in carrier_source_sink] >= 0) 
    #  Installed capacity of lean carrier storage associated with process in zone z (tonne) 
    @variable(EP, vCarLeanStorageCap[c in carrier_type, p in process_type, z in carrier_source_sink] >= 0) 



    ## Objective Function Expressions ##

    # Fixed cost associated with hydrogenation/dehydrogenation = annuitized investment cost plus fixed O&M costs

    # THINGS TO DO TO GENERALIZE
    ###  ADD PARAMETER SCALE IF CONDITION
    ###  TREAT EXISTING AND NEW CAPACITY SEPARATELY (i.e. dont count investment cost for existing capacity)

    @expression(EP, eCFixH2perCarrierProcess[c in carrier_type, p in process_type],
        (dfH2carrier[!,:capex_d_p_MW_y][R_ID[(c,p)]] +  dfH2carrier[!,:fom_d_p_MW_y][R_ID[(c,p)]]) * sum(vCarProcH2Cap[c,p,z] for z in carrier_source_sink)
    )


    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eCFixH2perCarrierProcessSum, sum(EP[:eCFixH2perCarrierProcess][c,p] for c in carrier_type, p in process_type))

    # Add term to objective function expression
    EP[:eObj] += eCFixH2perCarrierProcessSum

    # Fixed cost of rich carrier storage -  annuitized investment cost plus fixed O&M costs
    @expression(EP, eCFixH2perCarrierStorage[c in carrier_type, p in process_type],
        dfH2carrier[!,:rich_storage_capex_tonne_y][R_ID[(c,p)]]*sum(vCarRichStorageCap[c,p,z] for z in carrier_source_sink) +
        dfH2carrier[!,:lean_storage_capex_tonne_y][R_ID[(c,p)]]*sum(vCarLeanStorageCap[c,p,z] for z in carrier_source_sink) 

    )

    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eCFixH2perCarrierStorageSum, sum(EP[:eCFixH2perCarrierStorage][c,p] for c in carrier_type, p in process_type))

    # Add term to objective function expression
    EP[:eObj] += eCFixH2perCarrierStorageSum


    ### Constraints ####\
    #1.  cannot simultaneously invest in hydrogenation and dehydrogenation in the same zone
    #2.  Define variables that determine set of feasible routes
    #####3 NOTE: There may be other constraints that one can add - NOT SURE IF THIS IS COMPREHENSIVE
    if setup["H2CarrierStorageFunction"] == 0 # If we do not allow H2 carrier to provide storage function at the same site
        # 1. cannot simultaneously invest in hydrogenation and dehydrogenation in the same zone
        @constraint(EP, cCarrierProcessExclusivity[c in carrier_type, z in carrier_source_sink], 
            sum(vCarProcBuild[c, p, z] for p in process_type) <= 1
        )

        # 2. cannot build carrier process at a given location if binary variable at that location is inactive
        @constraint(EP, cCarrierProcessInstallFeasibility[c in carrier_type, p in process_type, z in carrier_source_sink], 
            vCarProcH2Cap[c, p, z] <= dfH2carrier[!,:max_cap_MW_H2][R_ID[(c, p)]]*vCarProcBuild[c,p,z]
        )
        
        

        #3. Set of binary constraints linking binary variations for active transportation routes with binary variables for active processes
        # https://support.gurobi.com/hc/en-us/community/posts/14379942279057-Linearizing-product-of-two-integer-variables 

        @constraint(EP, cCarrierTransportActive1[c in carrier_type, p in process_type, (z,z1) in carrier_candidate_routes_tuple], 
            vCarTransportON[c,p,(z,z1)] <= vCarProcBuild[c,p,z]
        )


        @constraint(EP, cCarrierTransportActive2[c in carrier_type, p in process_type, p1 in process_type, (z,z1) in carrier_candidate_routes_tuple; p!=p1], 
            vCarTransportON[c,p,(z,z1)]<= vCarProcBuild[c,p1,z1]
        )



        @constraint(EP, cCarrierTransportActive3[c in carrier_type, p in process_type, p1 in process_type, (z,z1) in carrier_candidate_routes_tuple; p!=p1], 
            vCarTransportON[c,p,(z,z1)]>= vCarProcBuild[c,p,z]+vCarProcBuild[c,p1,z1] - 1
        )

    end

    # # Force investment in one location
    # @constraint(EP,cForceInvestmentH2Cap[c in ["LOHC"], p in CARRIER_HYD, z=1],
    #     EP[:vCarProcH2Cap][c,p,z]= 100.0
    # )
    # fix(vCarProcH2Cap["LOHC","hyd",1], 100.0; force = true)

    return EP
end # end H2Pipeline module