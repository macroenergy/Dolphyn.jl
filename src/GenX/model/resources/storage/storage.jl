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
	storage(EP::Model, inputs::Dict, Reserves::Int, OperationWrapping::Int, LongDurationStorage::Int)

A wide range of energy storage devices (all $s \in \mathcal{S}$) can be modeled in DOLPHYN, using one of two generic storage formulations: 
(1) storage technologies with symmetric charge and discharge capacity (all $s \in \mathcal{S}^{sym}$), such as Lithium-ion batteries and most other electrochemical storage devices that use the same components for both charge and discharge; and 
(2) storage technologies that employ distinct and potentially asymmetric charge and discharge capacities (all $s \in \mathcal{S}^{asym}$), such as most thermal storage technologies or hydrogen electrolysis/storage/fuel cell or combustion turbine systems.
"""
function storage(EP::Model, inputs::Dict, Reserves::Int, OperationWrapping::Int)

	println("Storage Resources Module")

	if !isempty(inputs["STOR_ALL"]) #&& OperationWrapping == 1
		EP = investment_energy(EP, inputs)
		EP = storage_all(EP, inputs, Reserves, OperationWrapping)

		# Include LongDurationStorage only when modeling representative periods and long-duration storage
		if OperationWrapping == 1 && !isempty(inputs["STOR_LONG_DURATION"])
			EP = long_duration_storage(EP, inputs)
		end
	end

	if !isempty(inputs["STOR_ASYMMETRIC"])
		EP = investment_charge(EP, inputs)
		EP = storage_asymmetric(EP, inputs, Reserves)
	end

	if !isempty(inputs["STOR_SYMMETRIC"])
		EP = storage_symmetric(EP, inputs, Reserves)
	end

	return EP
end
