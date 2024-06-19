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
    h2_carrier_operations(EP::Model, inputs::Dict, setup::Dict)

This function includes the variables and constraints to model operation of hydrogen carriers


"""
function h2_carrier_transport(EP::Model, inputs::Dict, setup::Dict)

    T = inputs["T"] # Model operating time steps
    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity


    # Input data related to H2 carriers
    dfH2carrier = inputs["dfH2carrier"]

    dfH2carrier_routes = inputs["dfh2carrier_candidate_routes"]
  
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]


    carrier_type = inputs["carrier_names"]
    process_type = inputs["carrier_process_names"]


    # Matrix of allowed routes for carriers
    carrier_candidate_routes = inputs["carrier_candidate_routes"]
    # Convert each row to a tuple of source sink pairs eligible for carriers
    carrier_candidate_routes_tuple = inputs["carrier_candidate_routes_tuple"]

    # set of candidate source sinks for carriers
    carrier_zones = inputs["carrier_zones"]

    # Dictionary Mapping R_ID to carrier + process pairs
    R_ID =inputs["carrier_R_ID"]


    # Fixed cost for H2 Transportation across various zones
    # Accounts for time-delay associated with each route which implicitly increases the capex requirement
    # @expression(EP, eCarTransportFixCost[c in carrier_type, p in process_type],
    #     (dfH2carrier[!,:transport_capex_d_p_tonne_y][R_ID[(c,p)]]+dfH2carrier[!,:transport_fom_capex_d_p_tonne_y][R_ID[(c,p)]])*
    #         sum(EP[:vCarInterZoneFlowCap][c,p,(z,z1)]*dfH2carrier_routes[(dfH2carrier_routes.Zone1.==z) .& (dfH2carrier_routes.Zone2.==z1),:travel_time_hours] for (z,z1) in carrier_candidate_routes_tuple)
    # )

    @expression(EP, eCarTransportFixCost[c in carrier_type, p in process_type],
    (dfH2carrier[!,:transport_capex_d_p_tonne_y][R_ID[(c,p)]]+dfH2carrier[!,:transport_fom_capex_d_p_tonne_y][R_ID[(c,p)]])*
        sum(EP[:vCarInterZoneFlowCap][c,p,(z,z1)] for (z,z1) in carrier_candidate_routes_tuple)
    )

    ###### TO DO: Add Fuel energy needs for transportation ##### 

    ### Constraints ### 

    # carrier transport between two zones cannot exceed installed carrier transport capacity (i.e. ships between zones)
    @constraint(EP,cCarFlowFeasibility[c in carrier_type, p in process_type, (z,z1) in carrier_candidate_routes_tuple,  t=1:T],
        EP[:vCarInterZoneFlow][c,p,(z,z1),t] <= EP[:vCarInterZoneFlowCap][c,p,(z,z1)]   
    )
    # Sum of all carrier exports from a zone z must equal carrier transport from that zone to all other connected zones
    @constraint(EP,cExportBalance[c in carrier_type, p in process_type, z in carrier_zones, t=1:T],
        EP[:vCarProcFlowExport][c,p,z,t] ==sum(EP[:vCarInterZoneFlow][c,p,(z,z1),t] for z1 in [r[2] for r in carrier_candidate_routes_tuple if r[1] == z])
    )

    # Sum of all carrier imports to a zone z must equal carrier transport from all other connected zones having the OPPOSITE process
    @constraint(EP,cImportBalance[c in carrier_type, p in process_type, p1 in process_type, z in carrier_zones, t=1:T; p!=p1],
        EP[:vCarProcFlowImport][c,p,z,t] == sum(EP[:vCarInterZoneFlow][c,p1,(z1,z),t] for z1 in [r[1] for r in carrier_candidate_routes_tuple if r[2] == z])
    )


    if setup["H2CarrierStorageFunction"] == 0 # If we do not allow H2 carrier to provide storage function at the same site -- need binary variables
        # Flow of carrier on a route only allowed if the source and sink have the appropriate processes designated by binary variable vCarTransportON
        @constraint(EP,cCarFlowMaxCap[c in carrier_type, p in process_type, (z,z1) in carrier_candidate_routes_tuple,  t=1:T],
            EP[:vCarInterZoneFlowCap][c,p,(z,z1)] <=dfH2carrier[!,:max_cap_MW_H2][R_ID[(c,p)]]*dfH2carrier[!,:carrier_tonne_p_MWh_H2][R_ID[(c,p)]]*EP[:vCarTransportON][c,p,(z,z1)]
        )
    end


        


    return EP
end # end H2Pipeline module