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
    write_h2_carrier_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the carrier process operation variables 
"""
function write_h2_carrier_operation_outputs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

    T = inputs["T"]
    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity

    carrier_type = inputs["carrier_names"]
    process_type = inputs["carrier_process_names"]

    # Input data related to H2 carriers
    dfH2carrier = inputs["dfH2carrier"]
 
   
    # set of candidate source sinks for carriers
    carrier_zones = inputs["carrier_zones"]

    variables_to_export = [:vCarProcInput, :vCarProcH2output, :vCarProcOutput,:vMakeupCarrier,
    :vCarLeanStorDischg, :vCarProcFlowImport, :vCarProcFlowExport, :eLeanCarStorChange, :eRichCarStorChange]
   
    for variable_name in variables_to_export

        dfCarrierOps = DataFrame(Carrier_type = repeat(carrier_type, inner = size(carrier_zones,1)*size(process_type,1) ), 
        Process = repeat(process_type, inner =size(carrier_zones,1), outer=size(carrier_type,1)),
        Zone = repeat(carrier_zones, outer = size(carrier_type,1)*size(process_type,1))
        )
        carrierops = zeros(size(carrier_zones,1) *size(carrier_type,1)*size(process_type,1), T) # following the same style of power/charge/storage/nse

        for z in 1:size(carrier_zones,1)
        for p in 1:size(process_type,1)
            for c in 1:size(carrier_type,1)
                carrierops[z+(p-1)*size(carrier_zones,1)+(c-1)*size(carrier_zones,1)*size(process_type,1),:] = 
                value.(EP[variable_name][carrier_type[c],process_type[p],carrier_zones[z],:]).data
            end
        end
        end

        dfCarrierOps = hcat(dfCarrierOps, DataFrame(carrierops, :auto))
        auxNew_Names = [Symbol("Carrier_type"); Symbol("Process type"); Symbol("Zone"); [Symbol("t$t") for t in 1:T]]
        rename!(dfCarrierOps,auxNew_Names)
        CSV.write(joinpath(path, string("HSC_carrier_ops_", variable_name,".csv")), dftranspose(dfCarrierOps, false), writeheader=false)

    end



end
