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
	
"""
function syn_fuel_resource_all(EP::Model, inputs::Dict, setup::Dict)
	#Define sets

	SYN_FUELS_RES_ALL = inputs["SYN_FUELS_RES_ALL"]

	T = inputs["T"]     # Number of time steps (hours)

	####Variables####
	#Define variables needed across both commit and no commit sets
    
    #Amount of Syn Fuel Produced in MMBTU
	@variable(EP, vSFProd[k in SYN_FUELS_RES_ALL, t = 1:T] >= 0 )
    #Hydrogen Required by SynFuel Resource
    @variable(EP, vSFH2in[k in SYN_FUELS_RES_ALL, t = 1:T] >= 0 )
    #Power Required by SynFuel Resource
    @variable(EP, vSFPin[k in SYN_FUELS_RES_ALL, t = 1:T] >= 0 )

	return EP

end