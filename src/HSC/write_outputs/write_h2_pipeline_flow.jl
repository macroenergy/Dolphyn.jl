"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
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
	write_h2_pipeline_flow(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

"""
function write_h2_pipeline_flow(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	H2_P = inputs["H2_P"] # Number of Hydrogen Pipelines
    H2_Pipe_Map = inputs["H2_Pipe_Map"]

	## Hydrogen balance for each zone
	dfH2Balance = Array{Any}
	rowoffset=3
	for p in 1:H2_P
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 3)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Source_Zone_H2_Net", 
	           "Sink_Zone_H2_Net", "Pipe_Level"]

	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([p],size(dfTemp1,2))
        
        dfTemp1[3,1:size(dfTemp1,2)] = [[H2_Pipe_Map[(H2_Pipe_Map[!,:d] .== 1) .& (H2_Pipe_Map[!,:pipe_no] .== p), :][!,:zone_str][1]],[H2_Pipe_Map[(H2_Pipe_Map[!,:d] .== -1) .& (H2_Pipe_Map[!,:pipe_no] .== p), :][!,:zone_str][1]],"NA"]

	   	for t in 1:T
	     	dfTemp1[t+rowoffset,1]= value.(EP[:eH2PipeFlow_net][p,t,1])
	     	dfTemp1[t+rowoffset,2] = value.(EP[:eH2PipeFlow_net][p,t,-1])
            dfTemp1[t+rowoffset,3] = value.(EP[:vH2PipeLevel][p,t])
	   	end

		if p == 1
			dfH2Balance =  hcat(vcat(["", "Pipe", "Zone"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfH2Balance = hcat(dfH2Balance, dfTemp1)
		end
	end

	dfH2Balance = DataFrame(dfH2Balance, :auto)

	CSV.write(joinpath(path, "HSC_pipeline_flow.csv"), dfH2Balance, writeheader=false)
end
