"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Nexus
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
    write_h2_transmission_flow(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)
"""
function write_h2_transmission_flow(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)
    
    Z = inputs["Z"]     # Number of zones
    T = inputs["T"]     # Number of time steps (hours)
	
    dfH2TransmissionFlow = DataFrame(Time_Index=1:T)
    for z in 1:Z
        if setup["ModelH2Pipelines"] == 1
            dfH2TransmissionFlow[!, Symbol("H2PipeFlowToZone$z")] = value.(EP[:ePipeZoneDemand])[:, z]
        else
            dfH2TransmissionFlow[!, Symbol("H2PipeFlowToZone$z")] = 0
        end

        if setup["ModelH2Trucks"] == 1
            dfH2TransmissionFlow[!, Symbol("H2TruckFlowToZone$z")] = value.(EP[:eH2TruckFlow])[:, z]
        else
            dfH2TransmissionFlow[!, Symbol("H2TruckFlowToZone$z")] = 0
        end

        dfH2TransmissionFlow[!, Symbol("H2FlowToZone$z")] = dfH2TransmissionFlow[!, Symbol("H2PipeFlowToZone$z")] + dfH2TransmissionFlow[!, Symbol("H2TruckFlowToZone$z")]
    end

	CSV.write(string(path,sep, "HSC_h2_transmission_flow.csv"), dfH2TransmissionFlow, writeheader=true)
end