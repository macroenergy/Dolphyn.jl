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
    h2_carrier(EP::Model, inputs::Dict, setup::Dict)

This function includes the variables, expressions and objective funtion to model hydrogen carriers that convert H2 to a easily transportable/storable medium and return it as H2 in other zone.

"""
function h2_carrier(EP::Model, inputs::Dict, setup::Dict)

    print_and_log(" -- H2 Carrier Module")

    # investment variables expressions and related constraints for H2 carriers
    EP = h2_carrier_investment(EP::Model, inputs::Dict, setup::Dict)

    # # Operating variables, expressions and constraints related to H2 carriers
    EP = h2_carrier_operation(EP::Model, inputs::Dict, setup::Dict)

    # Storage related constraints for H2 carriers
    EP = h2_carrier_storage(EP::Model, inputs::Dict, setup::Dict)
    # EP = h2_carrier_storage_simple(EP::Model, inputs::Dict, setup::Dict)

    # Transport related constraints for H2 carriers
    EP = h2_carrier_transport(EP::Model, inputs::Dict, setup::Dict)

    # # Expressions related to H2 carriers passed to other parts of the code
    EP = h2_carrier_expressions(EP::Model, inputs::Dict, setup::Dict)
   
    return EP
end # end H2 carrier module