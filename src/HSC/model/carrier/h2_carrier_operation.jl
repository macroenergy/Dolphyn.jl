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
function h2_carrier_operation(EP::Model, inputs::Dict, setup::Dict)

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

    # Input data related to H2 carriers
    dfH2carrier = inputs["dfH2carrier"]
    
    # Matrix of allowed routes for carriers
    carrier_candidate_routes = inputs["carrier_candidate_routes"]
    # Convert each row to a tuple of source sink pairs eligible for carriers
    carrier_candidate_routes_tuple = inputs["carrier_candidate_routes_tuple"]

    # set of candidate source sinks for carriers
    carrier_source_sink = inputs["carrier_source_sink"]

    # Dictionary Mapping R_ID to carrier + process pairs
    R_ID =inputs["carrier_R_ID"]

   
    ### Variables ###
    # H2 output from process p for carrier c from zone z (GW_H2) - used to size the processes
    # p = hyd - refer to output in liquid form, p = dehyd = output in gaseous form
    @variable(EP, vCarProcH2output[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T] >= 0) 

    # Carrier input to process p;  p = hyd - refer to lean carrier , p = dehyd - refer to rich carrier input (tonnes/hr)
    @variable(EP, vCarProcCarInput[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T] >= 0) 

    # Carrier output from process p;  p = hyd - refer to rich carrier , p = dehyd - refer to lean carrier input (tonnes/hr)
    @variable(EP, vCarProcCarOutput[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T] >= 0) 


    # Carrier imports from process p via storage for carrier c from zone z (tonnes/hr)
    # p = hyd - lean carrier, p = dehyd = rich carrier
    @variable(EP, vCarProcFlowImport[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T] >= 0) 

    # Carrier exports from process p via storage for carrier c from zone z (tonnes/hr)
    # p = hyd - lean carrier, p = dehyd = rich carrier
    @variable(EP, vCarProcFlowExport[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T] >= 0) 

    # Make-up carrier consumption - associated with hydrogenation Process only
    @variable(EP, vMakeupCarrier[c in carrier_type, p in CARRIER_HYD, z in carrier_source_sink, t=1:T]>=0)

    # Discharge of lean carrier from storage for process p for carrier c in zone z (tonnes/hr)
    @variable(EP, vCarLeanStorDischg[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T] >= 0) 

    # Carrier storage inventory (tonnes)
    @variable(EP, vCarLeanStorLevel[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T] >= 0) 

    @variable(EP, vCarRichStorLevel[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T] >= 0) 

    # Flow of carrier c from process p in zone z to zone z1
    @variable(EP, vCarInterZoneFlow[c in carrier_type, p in process_type, (z,z1) in carrier_candidate_routes_tuple, t=1:T] >= 0) 

        
    ### Constraints ###
    # Process capacity limit
    @constraint(EP,cProcessCapLimit[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T],
        vCarProcH2output[c,p,z,t] <= EP[:vCarProcH2Cap][c,p,z]
    )

    # Carrier material balance at the process level: Input = Output + losses
    @constraint(EP,cCarProcessBalance[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T],
    vCarProcCarInput[c,p,z,t] *(1- dfH2carrier[!,:carrier_loss_fraction][R_ID[(c, p)]] ) == vCarProcCarOutput[c,p,z,t]
    )

    
    # Carrier process stoichiometry - relating relative amounts of H2 and carrier in rich carrier for each process
    @expression(EP,eCarProcessStoichiometry[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T],
        if p in CARRIER_HYD
            vCarProcCarOutput[c,p,z, t] - dfH2carrier[!,:carrier_tonne_p_MWh_H2][R_ID[(c,p)]]*vCarProcH2output[c,p,z,t]
        else # CARRIER_DEHYD
            vCarProcCarInput[c,p,z, t]  - dfH2carrier[!,:carrier_tonne_p_MWh_H2][R_ID[(c,p)]]*vCarProcH2output[c,p,z,t]
        end 
    )

    @constraint(EP,cCarProcessStoichiometry[c in carrier_type, p in process_type, z in carrier_source_sink, t=1:T],
        eCarProcessStoichiometry[c,p,z,t] ==0
    )

    #### Hydrogenation #### 

    # Carrier make up supply - only for hydrogenation step: Input = discharge from lean storage + make up
    @constraint(EP,cCarProcessMakeup[c in carrier_type, p in CARRIER_HYD, z in carrier_source_sink, t=1:T],
    vCarProcCarInput[c,p,z,t] == vCarLeanStorDischg[c,p,z,t] + vMakeupCarrier[c,p,z,t]
    )











    return EP
end # end H2Pipeline module