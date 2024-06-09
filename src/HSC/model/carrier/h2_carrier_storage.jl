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
    h2_carrier_storage(EP::Model, inputs::Dict, setup::Dict)

This function includes the constraints to model operation of carrier storage related to hydrogen carriers


"""
function h2_carrier_storage(EP::Model, inputs::Dict, setup::Dict)

    T = inputs["T"] # Model operating time steps
    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity

  
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]

    # Set of hydrogenation and dehydrogenation processes
    CARRIER_HYD = inputs["CARRIER_HYD"]
    CARRIER_DEHYD = inputs["CARRIER_DEHYD"]


    carrier_type = inputs["carrier_names"]
    process_type = inputs["carrier_process_names"]

    # set of candidate source sinks for carriers
    carrier_source_sink = inputs["carrier_source_sink"]

    #### Storage balance ####
    ### TEMPORRY APPROACH - NO LDES option

    @expression(EP, eLeanCarStorChange[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T],
    if p in CARRIER_HYD
        -EP[:vCarLeanStorDischg][c,p,z, t] + EP[:vCarProcFlowImport][c,p,z,t]
    else # CARRIER_DEHYD
        -EP[:vCarLeanStorDischg][c,p,z, t]  + EP[:vCarProcCarOutput][c,p,z,t]
    end 
        
    )

    # Constraint enforcing flow exports = storage discharge for dehydrogenation related storage
    @constraint(EP,cCarVariableEquality[c in carrier_type, p in CARRIER_DEHYD, z in carrier_source_sink, t=1:T],
    EP[:vCarLeanStorDischg][c,p,z,t] == EP[:vCarProcFlowExport][c,p,z,t]
    )     

    @expression(EP, eRichCarStorChange[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T],
    if p in CARRIER_HYD
        -EP[:vCarProcFlowExport][c,p,z, t] + EP[:vCarProcCarOutput][c,p,z,t]
    else # CARRIER_DEHYD
        -EP[:vCarProcCarInput][c,p,z, t]  + EP[:vCarProcFlowImport][c,p,z,t]
    end 
        
    )

    # Storage inventory balance constraints for rich and lean storage across hydrogen carriers 
    @constraints(EP, begin

        # capacity constraints
        [c in carrier_type, p in process_type, z in carrier_source_sink, t in 1:T], EP[:vCarRichStorageCap][c,p,z] >= EP[:vCarRichStorLevel][c,p,z,t]
        [c in carrier_type, p in process_type, z in carrier_source_sink, t in 1:T], EP[:vCarLeanStorageCap][c,p,z] >= EP[:vCarLeanStorLevel][c,p,z,t]
      
        # energy stored for the next hour = Energy in storage from previous hour + net change in storage
        cLeanCarSoCBalInterior[t in INTERIOR_SUBPERIODS, c in carrier_type, p in process_type, z in carrier_source_sink,], EP[:vCarLeanStorLevel][c,p,z,t] ==
        EP[:vCarLeanStorLevel][c,p,z,t-1] +eLeanCarStorChange[c,p,z,t]

        # energy stored for the next hour = Energy in storage from previous hour (last hour of rep. period) + net change in storage
        cLeanCarSoCBalStart[t in START_SUBPERIODS, c in carrier_type, p in process_type, z in carrier_source_sink,], EP[:vCarLeanStorLevel][c,p,z,t] ==
        EP[:vCarLeanStorLevel][c,p,z,t+hours_per_subperiod-1] + eLeanCarStorChange[c,p,z,t]

        # energy stored for the next hour = Energy in storage from previous hour + net change in storage
        cRichCarSoCBalInterior[t in INTERIOR_SUBPERIODS, c in carrier_type, p in process_type, z in carrier_source_sink,], EP[:vCarRichStorLevel][c,p,z,t] ==
        EP[:vCarRichStorLevel][c,p,z,t-1] +eRichCarStorChange[c,p,z,t]

        # energy stored for the next hour = Energy in storage from previous hour(last hour of rep. period) + net change in storage
        cRichCarSoCBalStart[t in START_SUBPERIODS, c in carrier_type, p in process_type, z in carrier_source_sink,], EP[:vCarRichStorLevel][c,p,z,t] ==
        EP[:vCarLeanStorLevel][c,p,z,t+hours_per_subperiod-1] +eRichCarStorChange[c,p,z,t]
    end)

    return EP
end # end H2Pipeline module