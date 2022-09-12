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
	write_h2_pipeline_expansion(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the expansion of hydrogen pipelines.    
"""
function write_h2_pipeline_expansion(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

    L = inputs["H2_P"]     # Number of H2 pipelines

    transcap = zeros(L) # Transmission network reinforcements in tonne/hour
    for i = 1:L
        transcap[i] =
            (value.(EP[:vH2NPipe][i]) - inputs["pH2_Pipe_No_Curr"][i]) .*
            inputs["pH2_Pipe_Max_Flow"][i]
    end
    dfTransCap = DataFrame(
        Line = 1:L,
        Existing_Trans_Capacity = inputs["pH2_Pipe_Max_Flow"] .* inputs["pH2_Pipe_No_Curr"],
        New_Trans_Capacity = convert(Array{Union{Missing,Float32}}, transcap),
    )
    CSV.write(string(path, sep, "HSC_pipeline_expansion.csv"), dfTransCap)
end
