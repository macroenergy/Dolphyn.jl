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
  
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]

    # Set of hydrogenation and dehydrogenation processes
    CARRIER_HYD = inputs["CARRIER_HYD"]
    CARRIER_DEHYD = inputs["CARRIER_DEHYD"]


    carrier_type = inputs["carrier_names"]
    process_type = inputs["carrier_process_names"]


    # Matrix of allowed routes for carriers
    carrier_candidate_routes = inputs["carrier_candidate_routes"]
    # Convert each row to a tuple of source sink pairs eligible for carriers
    carrier_candidate_routes_tuple = inputs["carrier_candidate_routes_tuple"]

    # set of candidate source sinks for carriers
    carrier_source_sink = inputs["carrier_source_sink"]

    # Dictionary Mapping R_ID to carrier + process pairs
    R_ID =inputs["carrier_R_ID"]


### Constraints ### 
# Sum of all carrier exports from a zone z must equal carrier transport from that zone to all other connected zones
# @constraint(EP,cExportBalance[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T],
#     vCarProcFlowExport[c,p,z,t] =sum(vCarInterZoneFlow[c,p,z,z1,t] for z1 in [r for r in carrier_candidate_routes_tuple if r[1] == z])
# )

# # Sum of all carrier imports to a zone z must equal carrier transport from all other connected zones to that zone
# @constraint(EP,cImportBalance[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T],
#     vCarProcFlowImport[c,p,z,t] =sum(vCarInterZoneFlow[c,p,z1,z,t] for z1 in [r for r in carrier_candidate_routes_tuple if r[2] == z])
# )

# Sum of injections and withdrawals of each carrier type must be cCarVariableEquality
## NOTE: This assumes no time delay in carrier transport
@constraint(EP,cZonalRichCarrierBalance[c in carrier_type,  t=1:T],
    sum(EP[:vCarProcFlowExport][c,p,z,t] for z in carrier_source_sink, p in CARRIER_HYD)== sum(EP[:vCarProcFlowImport][c,p,z,t] for z in carrier_source_sink, p in CARRIER_DEHYD) 
)

@constraint(EP,cZonalLeanCarrierBalance[c in carrier_type,  t=1:T],
    sum(EP[:vCarProcFlowExport][c,p,z,t] for z in carrier_source_sink, p in CARRIER_DEHYD)== sum(EP[:vCarProcFlowImport][c,p,z,t] for z in carrier_source_sink, p in CARRIER_HYD) 
)

if setup["H2CarrierStorageFunction"] == 0 # If we do not allow H2 carrier to provide storage function at the same site
    # Flow of carrier on a route only allowed if the source and sink have the appropriate processes designated by binary variable vCarTransportON
    @constraint(EP,cCarFlowFeasibility[c in carrier_type, p in process_type, (z,z1) in carrier_candidate_routes_tuple,  t=1:T],
        EP[:vCarInterZoneFlow][c,p,(z,z1),t] <=dfH2carrier[!,:max_cap_MW_H2][R_ID[(c,p)]] *EP[:vCarTransportON][c,p,(z,z1)]
    )
end

    return EP
end # end H2Pipeline module