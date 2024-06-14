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
function h2_carrier_storage_simple(EP::Model, inputs::Dict, setup::Dict)

    T = inputs["T"] # Model operating time steps
    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity

  
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]

    # Set of hydrogenation and dehydrogenation processes
    CARRIER_HYD = inputs["CARRIER_HYD"]
    CARRIER_DEHYD = inputs["CARRIER_DEHYD"]

    REP_PERIOD = inputs["REP_PERIOD"]     # Number of representative periods



    carrier_type = inputs["carrier_names"]
    process_type = inputs["carrier_process_names"]

    # set of candidate source sinks for carriers
    carrier_zones = inputs["carrier_zones"]


    #### variables ###

    #@variable(EP, vCarRichStorLevel[c in carrier_type, p in process_type, z in carrier_zones, t=1:T] >= 0) 

    # Carrier storage inventory (tonnes)
    #@variable(EP, vCarLeanStorLevel[c in carrier_type, p in process_type, z in carrier_zones, t=1:T] >= 0) 


    #### Storage balance ####
    ### TEMPORRY APPROACH - NO LDES option

    @expression(EP, eLeanCarStorChange[c in carrier_type, p in process_type, z in carrier_zones, w=1:REP_PERIOD],
    if p in CARRIER_HYD
        sum(-EP[:vCarLeanStorDischg][c,p,z, hours_per_subperiod*(w-1)+r] + EP[:vCarProcFlowImport][c,p,z,hours_per_subperiod*(w-1)+r] for r=1:hours_per_subperiod)
    else # CARRIER_DEHYD
        sum(-EP[:vCarLeanStorDischg][c,p,z, hours_per_subperiod*(w-1)+r]  + EP[:vCarProcOutput][c,p,z,r] for r=1:hours_per_subperiod)
    end 
        
    )

    # Constraint enforcing flow exports = storage discharge for dehydrogenation related storage
    @constraint(EP,cCarVariableEquality[c in carrier_type, p in CARRIER_DEHYD, z in carrier_zones, t=1:T],
    EP[:vCarLeanStorDischg][c,p,z,t] == EP[:vCarProcFlowExport][c,p,z,t]
    )     


    @constraint(EP, cLeanCarStorChangeEq0[c in carrier_type, p in process_type, z in carrier_zones, w=1:REP_PERIOD],
    eLeanCarStorChange[c,p,z,w]==0
)

    @expression(EP, eRichCarStorChange[c in carrier_type, p in process_type, z in carrier_zones, w=1:REP_PERIOD],
    if p in CARRIER_HYD
        sum(-EP[:vCarProcFlowExport][c,p,z, hours_per_subperiod*(w-1)+r] + EP[:vCarProcOutput][c,p,z,hours_per_subperiod*(w-1)+r] for r = 1:hours_per_subperiod)
    else # CARRIER_DEHYD
        sum(-EP[:vCarProcInput][c,p,z, hours_per_subperiod*(w-1)+r]  + EP[:vCarProcFlowImport][c,p,z,hours_per_subperiod*(w-1)+r] for r = 1:hours_per_subperiod)
    end 
        
    )


    @constraint(EP, cRichCarStorChangeEq0[c in carrier_type, p in process_type, z in carrier_zones, w=1:REP_PERIOD],
        eRichCarStorChange[c,p,z,w]==0
    )
   

    return EP
end # end H2Pipeline module