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
function write_syn_pipeline_flow(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

	T = inputs["T"]     # Number of time steps (hours)
	Syn_P = inputs["Syn_P"] # Number of Hydrogen Pipelines
    Syn_Pipe_Map = inputs["Syn_Pipe_Map"]

	## Hydrogen balance for each zone
	dfSynBalance = Array{Any}
	rowoffset=3
	for p in 1:Syn_P
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 3)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Source_Zone_Syn_Net",
	           "Sink_Zone_Syn_Net", "Pipe_Level"]

	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([p],size(dfTemp1,2))

        dfTemp1[3,1:size(dfTemp1,2)] = [[Syn_Pipe_Map[(Syn_Pipe_Map[!,:d] .== 1) .& (Syn_Pipe_Map[!,:pipe_no] .== p), :][!,:zone_str][1]],[Syn_Pipe_Map[(Syn_Pipe_Map[!,:d] .== -1) .& (Syn_Pipe_Map[!,:pipe_no] .== p), :][!,:zone_str][1]],"NA"]

	   	for t in 1:T
	     	dfTemp1[t+rowoffset,1]= value.(EP[:eH2PipeFlow_net][p,t,1])
	     	dfTemp1[t+rowoffset,2] = value.(EP[:eH2PipeFlow_net][p,t,-1])
            dfTemp1[t+rowoffset,3] = value.(EP[:vH2PipeLevel][p,t])
	   	end

		if p == 1
			dfSynBalance =  hcat(vcat(["", "Pipe", "Zone"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfSynBalance = hcat(dfSynBalance, dfTemp1)
		end
	end

	dfSynBalance = DataFrame(dfSynBalance, :auto)

	CSV.write(joinpath(path, "Syn_pipeline_flow.csv"), dfSynBalance, writeheader=false)
end
