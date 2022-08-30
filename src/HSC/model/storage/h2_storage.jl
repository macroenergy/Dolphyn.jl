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
    h2_storage(EP::Model, inputs::Dict, setup::Dict)
    
A wide range of energy storage devices (all $s \in \mathcal{S}$) can be modeled in DOLPHYN, using one of two generic storage formulations: 
(1) storage technologies with symmetric charge and discharge capacity (all $s \in \mathcal{S}^{sym}$), such as Lithium-ion batteries and most other electrochemical storage devices that use the same components for both charge and discharge; and 
(2) storage technologies that employ distinct and potentially asymmetric charge and discharge capacities (all $s \in \mathcal{S}^{asym}$), such as most thermal storage technologies or hydrogen electrolysis/storage/fuel cell or combustion turbine systems.
"""
function h2_storage(EP::Model, inputs::Dict, setup::Dict)

    println("Hydrogen Storage Module")

    if !isempty(inputs["H2_STOR_ALL"])
        # investment variables expressions and related constraints for H2 storage tehcnologies
        EP = h2_storage_investment_energy(EP, inputs, setup)

        # Operating variables, expressions and constraints related to H2 storage
        EP = h2_storage_all(EP, inputs, setup)

        # Include LongDurationStorage only when modeling representative periods and long-duration storage
        if setup["OperationWrapping"] == 1 && !isempty(inputs["H2_STOR_LONG_DURATION"])
            EP = h2_long_duration_storage(EP, inputs)
        end
    end

    if !isempty(inputs["H2_STOR_ASYMMETRIC"])
        EP = h2_storage_investment_charge(EP, inputs, setup)
        EP = h2_storage_asymmetric(EP, inputs)
    end

    if !isempty(inputs["H2_STOR_SYMMETRIC"])
        EP = h2_storage_symmetric(EP, inputs)
    end

    return EP
end
