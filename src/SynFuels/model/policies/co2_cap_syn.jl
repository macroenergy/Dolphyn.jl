"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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

"""
function co2_cap_syn(EP::Model, inputs::Dict, setup::Dict)

    T = inputs["T"]     # Number of time steps (hours)
    SYN_SEG = inputs["SYN_SEG"] # Number of demand response segments for Synthesis fuels demand

    # NOTE: If ParameterScale = 1 , then emisisons constraint written in units of ktonnes, else emissions constraint units is tonnes
    ## Mass-based: Emissions constraint in absolute emissions limit (tons)
    # eH2emissionsbyZones scaled in emissions_hsc.jl. RHS of constraint adjusted by modifying unit of CO2 intensity constraint
    if setup["SynCO2Cap"] == 1
        @constraint(
            EP,
            cSynCO2Emissions_systemwide[cap = 1:inputs["SynNCO2Cap"]],
            sum(
                inputs["omega"][t] * EP[:eSynEmissionsByZone][z, t] for
                z in findall(x -> x == 1, inputs["dfSynCO2CapZones"][:, cap]), t = 1:T
            ) <= sum(
                inputs["dfSynMaxCO2"][z, cap] for
                z in findall(x -> x == 1, inputs["dfSynCO2CapZones"][:, cap])
            )
        )

        ## Load + Rate-based: Emissions constraint in terms of rate (tons/tonnes)
        ## DEV NOTE: Add demand from H2 consumption by power sector after adding gas to power module
    elseif setup["SynCO2Cap"] == 2
        @constraint(
            EP,
            cSynCO2Emissions_systemwide[cap = 1:inputs["SynNCO2Cap"]],
            sum(
                inputs["omega"][t] * EP[:eSynEmissionsByZone][z, t] for
                z in findall(x -> x == 1, inputs["dfSynCO2CapZones"][:, cap]), t = 1:T
            ) <= sum(
                inputs["dfSynMaxCO2Rate"][z, cap] * sum(
                    inputs["omega"][t] * (
                        inputs["SynFuel_D"][t, z] -
                        sum(EP[:vSynNSE][s, t, z] for s = 1:SYN_SEG)
                    ) for t = 1:T
                ) for z in findall(x -> x == 1, inputs["dfSynCO2CapZones"][:, cap])
            )
        )

        ## Generation + Rate-based: Emissions constraint in terms of rate (tonne CO2/tonne H2)
    elseif (setup["SynCO2Cap"] == 3)
        @constraint(
            EP,
            cSynCO2Emissions_systemwide[cap = 1:inputs["SynNCO2Cap"]],
            sum(
                inputs["omega"][t] * EP[:eSynEmissionsByZone][z, t] for
                z in findall(x -> x == 1, inputs["dfSynCO2CapZones"][:, cap]), t = 1:T
            ) <= sum(
                inputs["dfSynMaxCO2Rate"][z, cap] *
                inputs["omega"][t] *
                EP[:eSynGenerationByZone][z, t] for t = 1:T,
                z in findall(x -> x == 1, inputs["dfSynCO2CapZones"][:, cap])
            )
        )
    end


    return EP
end
