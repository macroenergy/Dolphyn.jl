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
    H2_G2Peration(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

The h2_production module creates decision variables, expressions, and constraints related to various hydrogen generation technologies (electrolyzers, natural gas reforming etc.)

This module uses the following 'helper' functions in separate files: ```H2_G2Peration_commit()``` for resources subject to unit commitment decisions and constraints (if any) and ```H2_G2Peration_no_commit()``` for resources not subject to unit commitment (if any).
"""
function h2_g2p(EP::Model, inputs::Dict, setup::Dict)

	if !isempty(inputs["H2_G2P"])
		EP = h2_g2p_investment(EP::Model, inputs::Dict, setup::Dict)
		EP = h2_g2p_discharge(EP::Model, inputs::Dict, setup::Dict)
		# expressions, variables and constraints common to all types of hydrogen generation technologies
		EP = h2_g2p_all(EP::Model, inputs::Dict, setup::Dict)
	end

    H2_G2P_COMMIT = inputs["H2_G2P_COMMIT"]
	H2_G2P_NO_COMMIT = inputs["H2_G2P_NO_COMMIT"]
	dfH2G2P = inputs["dfH2G2P"]  # Input H2 generation and storage data
	Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity
	T = inputs["T"]	 # Model operating time steps

	if !isempty(H2_G2P_COMMIT)
		EP = h2_g2p_commit(EP::Model, inputs::Dict, setup::Dict)
	end

	if !isempty(H2_G2P_NO_COMMIT)
		EP = h2_g2p_no_commit(EP::Model, inputs::Dict,setup::Dict)
	end

	##For CO2 Polcy constraint right hand side development - H2 Generation by zone and each time step
		@expression(EP, eGenerationByZoneG2P[t=1:T, z=1:Z], # the unit is tonne/hour
		sum(EP[:vPG2P][y,t] for y in intersect(inputs["H2_G2P"], dfH2G2P[dfH2G2P[!,:Zone].==z,:R_ID]))
	)

	@expression(EP, eH2DemandByZoneG2P[z=1:Z, t=1:T], # the unit is tonne/hour
		sum(EP[:vH2G2P][y,t] for y in intersect(inputs["H2_G2P"], dfH2G2P[dfH2G2P[!,:Zone].==z,:R_ID]))
	)

	EP[:eGenerationByZone] += eGenerationByZoneG2P

	return EP
end
