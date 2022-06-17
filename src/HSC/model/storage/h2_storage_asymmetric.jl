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
    h2_storage_asymmetric(EP::Model, inputs::Dict)

This module separates the hydrogen storage type into asymmetric and symmetric charge and models the action when charging and discharging is asymmetric.
"""

function h2_storage_asymmetric(EP::Model, inputs::Dict)
    # Set up additional variables, constraints, and expressions associated with storage resources with asymmetric charge & discharge capacity
    # STOR = 2 corresponds to storage with distinct power and energy capacity decisions and distinct charge and discharge power capacity decisions/ratings

    println("H2 Storage Resources with Asmymetric Charge/Discharge Capacity Module")

    T = inputs["T"]     # Number of time steps (hours)

    H2_STOR_ASYMMETRIC = inputs["H2_STOR_ASYMMETRIC"]

    ### Constraints ###

    # Hydrogen storage discharge and charge power (and reserve contribution) related constraints for symmetric storage resources:
    # Maximum charging rate must be less than charge power rating
    @constraint(
        EP,
        [y in H2_STOR_ASYMMETRIC, t in 1:T],
        EP[:vH2_CHARGE_STOR][y, t] <= EP[:eTotalH2CapCharge][y]
    )

    return EP
end
