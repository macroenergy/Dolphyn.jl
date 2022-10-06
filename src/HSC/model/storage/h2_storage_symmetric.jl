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
function h2_storage_symmetric(EP::Model, inputs::Dict)
    # Set up additional variables, constraints, and expressions associated with hydrogen storage resources with symmetric charge & discharge capacity
    # STOR = 1 corresponds to storage with distinct power and energy capacity decisions but symmetric charge/discharge power ratings

    println("H2 Storage Resources with Symmetric Charge/Discharge Capacity Module")

    T = inputs["T"]

    H2_STOR_SYMMETRIC = inputs["H2_STOR_SYMMETRIC"]

    ### Constraints ###

    # Hydrogen storage discharge and charge power (and reserve contribution) related constraints for symmetric storage resources:
    @constraints(
        EP,
        begin
            # Maximum charging rate must be less than symmetric power rating
            [y in H2_STOR_SYMMETRIC, t in 1:T], EP[:vH2_CHARGE_STOR][y,t] <= EP[:eH2GenTotalCap][y] * inputs["pH2_Max"][y,t]
        end
    )

    return EP
end
