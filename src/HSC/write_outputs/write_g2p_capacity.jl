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
    write_g2p_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the diferent capacities for the different hydrogen to power technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_g2p_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    # Capacity decisions
    dfH2G2P = inputs["dfH2G2P"]
    capdischarge = zeros(size(inputs["H2_G2P_NAME"]))
    new_cap_and_commit = intersect(inputs["H2_G2P_NEW_CAP"], inputs["H2_G2P_COMMIT"])
    new_cap_not_commit = setdiff(inputs["H2_G2P_NEW_CAP"], inputs["H2_G2P_COMMIT"])
    if !isempty(new_cap_and_commit)
        capdischarge[new_cap_and_commit] = value.(EP[:vH2G2PNewCap][new_cap_and_commit]).data .* dfH2G2P[new_cap_and_commit,:Cap_Size_MW]
    end
    if !isempty(new_cap_not_commit)
        capdischarge[new_cap_not_commit] = value.(EP[:vH2G2PNewCap][new_cap_not_commit]).data
    end

    retcapdischarge = zeros(size(inputs["H2_G2P_NAME"]))
    ret_cap_and_commit = intersect(inputs["H2_G2P_RET_CAP"], inputs["H2_G2P_COMMIT"])
    ret_cap_not_commit = setdiff(inputs["H2_G2P_RET_CAP"], inputs["H2_G2P_COMMIT"])
    if !isempty(ret_cap_and_commit)
        retcapdischarge[ret_cap_and_commit] = value.(EP[:vH2G2PRetCap][ret_cap_and_commit]).data .* dfH2G2P[ret_cap_and_commit,:Cap_Size_MW]
    end
    if !isempty(ret_cap_not_commit)
        retcapdischarge[ret_cap_not_commit] = value.(EP[:vH2G2PRetCap][ret_cap_not_commit]).data
    end

    dfCap = DataFrame(
        Resource = inputs["H2_G2P_NAME"], Zone = dfH2G2P[!,:Zone],
        StartCap = dfH2G2P[!,:Existing_Cap_MW],
        RetCap = retcapdischarge[:],
        NewCap = capdischarge[:],
        EndCap = value.(EP[:eH2G2PTotalCap]),
    )

    total = DataFrame(
            Resource = "Total", Zone = "n/a",
            StartCap = sum(dfCap[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]),
            NewCap = sum(dfCap[!,:NewCap]), EndCap = sum(dfCap[!,:EndCap])
        )

    dfCap = vcat(dfCap, total)
    CSV.write(joinpath(path, "HSC_g2p_capacity.csv"), dfCap)
    return dfCap
end
