"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021, Massachusetts Institute of Technology and Peking University
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt. Users uncompressing this from an archive may not have
received this license file. If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""

"""
function co2_cap_hsc(EP::Model, inputs::Dict, setup::Dict)

	T = inputs["T"]     # Number of time steps (hours)
	H2_SEG= inputs["H2_SEG"] # Number of demand response segments for H2 demand

    # NOTE: If ParameterScale = 1 , then emisisons constraint written in units of ktonnes, else emissions constraint units is tonnes
    ## Mass-based: Emissions constraint in absolute emissions limit (tons)
    # eH2emissionsbyZones scaled in emissions_hsc.jl. RHS of constraint adjusted by modifying unit of CO2 intensity constraint
	if setup["H2CO2Cap"] == 1
		@constraint(EP, cH2CO2Emissions_systemwide[cap=1:inputs["H2NCO2Cap"]],
			sum(inputs["omega"][t] * EP[:eH2EmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfH2CO2CapZones"][:,cap]), t=1:T) <=
			sum(inputs["dfH2MaxCO2"][z,cap] for z=findall(x->x==1, inputs["dfH2CO2CapZones"][:,cap]))
		)

	## Load + Rate-based: Emissions constraint in terms of rate (tons/tonnes)
    ## DEV NOTE: Add demand from H2 consumption by power sector after adding gas to power module
	elseif setup["H2CO2Cap"] == 2
		@constraint(EP, cH2CO2Emissions_systemwide[cap=1:inputs["H2NCO2Cap"]],
			sum(inputs["omega"][t] * EP[:eH2EmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfH2CO2CapZones"][:,cap]), t=1:T) <=
			sum(inputs["dfH2MaxCO2Rate"][z,cap] * sum(inputs["omega"][t] *
			(inputs["H2_D"][z,t] + EP[:eH2DemandByZoneG2P][z,t] -
			 sum(EP[:vH2NSE][s,z,t] for s in 1:H2_SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfH2CO2CapZones"][:,cap]))
		)

	## Generation + Rate-based: Emissions constraint in terms of rate (tonne CO2/tonne H2)
	elseif (setup["H2CO2Cap"]==3)
		@constraint(EP, cH2CO2Emissions_systemwide[cap=1:inputs["H2NCO2Cap"]],
			sum(inputs["omega"][t] * EP[:eH2EmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfH2CO2CapZones"][:,cap]), t=1:T) <=
			sum(inputs["dfH2MaxCO2Rate"][z,cap] * inputs["omega"][t] * EP[:eH2GenerationByZone][z,t] for t=1:T, z=findall(x->x==1, inputs["dfH2CO2CapZones"][:,cap]))
		)
	end

    return EP

end
