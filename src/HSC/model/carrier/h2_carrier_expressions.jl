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
    h2_carrier_expressions(EP::Model, inputs::Dict, setup::Dict)

This function includes the expressions and objective function terms to model operation of hydrogen carriers


"""
function h2_carrier_expressions(EP::Model, inputs::Dict, setup::Dict)

    T = inputs["T"] # Model operating time steps
    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity

  

    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]


    CARRIER_HYD = inputs["CARRIER_HYD"]
    CARRIER_DEHYD = inputs["CARRIER_DEHYD"]


    carrier_type = inputs["carrier_names"]
    process_type = inputs["carrier_process_names"]

    # Input data related to H2 carriers
    dfH2carrier = inputs["dfH2carrier"]
 
   
    # set of candidate source sinks for carriers
    carrier_source_sink = inputs["carrier_source_sink"]

    # Dictionary Mapping R_ID to carrier + process pairs
    R_ID =inputs["carrier_R_ID"]


    ### Expressions ####
    # cost of make up lean carrier
    @expression(EP, eCMakeupCarrierCost[c in carrier_type, p in CARRIER_HYD, z in carrier_source_sink],
    sum(inputs["omega"][t]*dfH2carrier[!,:make_up_carrier_cost_d_p_tonne][R_ID[(c,p)]]*EP[:vMakeupCarrier][c,p,z,t] for t=1:T)
    )

    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eCMakeupCarrierCostSum, sum(EP[:eCMakeupCarrierCost][c,p,z] for c in carrier_type, p in CARRIER_HYD, z in carrier_source_sink))

    # # Add term to objective function expression
    EP[:eObj] += eCMakeupCarrierCostSum

    # Carrier H2 Supply: Generation via dehydrogenation - consumption via hydrogenation
    @expression(EP,eCarProcH2Supply[t=1:T,z=1:Z], # MWh
        if z in carrier_source_sink
            # Positive term implies production of H2 and negative term implies consumption of H2
            sum((1+dfH2carrier[!,:h2_consumption_fraction][R_ID[(c,p)]] )*EP[:vCarProcH2output][c,p,z,t] for c in carrier_type, p in CARRIER_DEHYD) -
            sum((1+dfH2carrier[!,:h2_consumption_fraction][R_ID[(c,p)]] )*EP[:vCarProcH2output][c,p,z,t] for c in carrier_type, p in CARRIER_HYD)
        else 
            EP[:vZERO]
        end
    )

    EP[:eH2Balance] +=eCarProcH2Supply/H2_LHV # To conver MWh to tonnes/hr of H2

    # Carrier Electricity balance: scaled as a function of H2 produced in each process
    @expression(EP,eCarProcPowerDemand[t=1:T,z=1:Z], # MWh
        if z in carrier_source_sink
            sum((1+dfH2carrier[!,:elec_input_fraction_MWh_MWh][R_ID[(c,p)]] )*EP[:vCarProcH2output][c,p,z,t] for c in carrier_type, p in process_type)
        else 
            EP[:vZERO]
        end
    )

    EP[:ePowerBalance] -=eCarProcPowerDemand  # in MW

    # Carrier NG balance: scaled as a function of H2 produced in each process
    @expression(EP,eCarProcNGDemand[t=1:T,z=1:Z], # MMBTu
        if z in carrier_source_sink
            sum((1+dfH2carrier[!,:ng_input_MMBtu_p_MWh_H2][R_ID[(c,p)]] )*EP[:vCarProcH2output][c,p,z,t] for c in carrier_type, p in process_type)
        else 
            EP[:vZERO]
        end
    )


    # NG related costs
    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eCarProcNGCost, sum(EP[:eCarProcNGDemand][t,z]*inputs["omega"][t]*inputs["fuel_costs"][inputs["fuels"][z]][t]  for t=1:T, z=1:Z))

     # Add term to objective function expression
    EP[:eObj] += eCarProcNGCost

    # NG related emissions
    @expression(EP, eCarProcNGEmissions[z=1:Z,t=1:T,], 
    sum(EP[:eCarProcNGDemand][t,z]*inputs["fuel_CO2"][inputs["fuels"][z]]))

    ## TO DO: Need to export NG related emissions to emissions_hsc.jl where it can be added to the H2emissions by plant

    return EP
end # end H2Pipeline module