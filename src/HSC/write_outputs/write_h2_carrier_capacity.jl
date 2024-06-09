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

Function for reporting the installed hydrogen carrier capacity.    
"""
function write_h2_carrier_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity


    CARRIER_HYD = inputs["CARRIER_HYD"]
    CARRIER_DEHYD = inputs["CARRIER_DEHYD"]


    carrier_type = inputs["carrier_names"]
    process_type = inputs["carrier_process_names"]

    # Input data related to H2 carriers
    dfH2carrier = inputs["dfH2carrier"]
 
   
    # set of candidate source sinks for carriers
    carrier_source_sink = inputs["carrier_source_sink"]

    
     # Non-served energy/demand curtailment by segment in each time step
     dfNse = DataFrame()
     dfTemp = Dict()
     for z in carrier_source_sink
         dfTemp = DataFrame(Carrier=zeros(size(carrier_type,1)), Zone=zeros(size(carrier_type,1)))
         dfTemp[!,:Carrier] = carrier_type
         dfTemp[!,:Zone] = fill(z,size(carrier_type,1))
 
         h2nse = value.(EP[:vCarProcH2Cap][:, :, z])
         
         tempmatrix = zeros(size(carrier_type,1), size(process_type,1))

        
        for i=1:size(carrier_type,1), j=1:size(process_type,1)
            tempmatrix[i,j] =h2nse[carrier_type[i],process_type[j]]
        end
           
         dfTemp = hcat(dfTemp, DataFrame(tempmatrix, :auto))


         if z == 1
            dfNse = dfTemp
        else
            dfNse = vcat(dfNse,dfTemp)
        end
     end
 
     auxNew_Names=[Symbol("Segment");Symbol("Zone");[Symbol("$t") for t in process_type]]
     rename!(dfNse,auxNew_Names)


    # dfTransCap = DataFrame(
    # Carrier = dfH2carrier[:, :carrier],
    # Process = dfH2carrier[:, :process],
    # Zone = 1:Z,
    # CarProcH2Cap = convert(Array{Union{Missing,Float64}}, CarProcessCap)
    # )
    
    CSV.write(joinpath(path, "HSC_carrier_capacity.csv"), dfNse)
end
