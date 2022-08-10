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
    write_co2_pipeline_level(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

Function for writing carbon storage level for each pipeline.
"""
function write_co2_pipeline_level(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)

    P = inputs["CO2_P"]  # Number of H2 pipelines
    T = inputs["T"]  # Model operating time steps

    p = zeros(P, T)
    dfCO2PipelineLevel = DataFrame(Pipelines = 1:P)

    for i in 1:P
        p[i, :] = value.(EP[:vCO2PipeLevel])[i, :]
    end

    dfCO2PipelineLevel = hcat(dfCO2PipelineLevel, DataFrame(p, :auto))
    auxNew_Names=[Symbol("Pipelines");[Symbol("t$t") for t in 1:T]]
    rename!(dfCO2PipelineLevel, auxNew_Names)

    CSV.write(joinpath(path, "CSC_pipeline_level.csv"), dftranspose(dfCO2PipelineLevel, false), writeheader=false)
end
