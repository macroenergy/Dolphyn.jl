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
    write_h2_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the capacities for the different hydrogen resources (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_h2_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    # Capacity decisions
    dfH2Gen = inputs["dfH2Gen"]
    if setup["ModelH2Liquid"] ==1
        H2_GEN_COMMIT = union(inputs["H2_GEN_COMMIT"], inputs["H2_LIQ_COMMIT"], inputs["H2_EVAP_COMMIT"])
    else
        H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
    end
    capdischarge = zeros(size(inputs["H2_RESOURCES_NAME"]))
    new_cap_and_commit = intersect(inputs["H2_GEN_NEW_CAP"], H2_GEN_COMMIT)
    new_cap_not_commit = setdiff(inputs["H2_GEN_NEW_CAP"], H2_GEN_COMMIT)
    if !isempty(new_cap_and_commit)
        capdischarge[new_cap_and_commit] .= value.(EP[:vH2GenNewCap][new_cap_and_commit]).data .* dfH2Gen[new_cap_and_commit,:Cap_Size_tonne_p_hr]
    end
    if !isempty(new_cap_not_commit)
        capdischarge[new_cap_not_commit] .= value.(EP[:vH2GenNewCap][new_cap_not_commit]).data
    end

    retcapdischarge = zeros(size(inputs["H2_RESOURCES_NAME"]))
    ret_cap_and_commit = intersect(inputs["H2_GEN_RET_CAP"], H2_GEN_COMMIT)
    ret_cap_not_commit = setdiff(inputs["H2_GEN_RET_CAP"], H2_GEN_COMMIT)
    if !isempty(ret_cap_and_commit)
        retcapdischarge[ret_cap_and_commit] .= value.(EP[:vH2GenRetCap][ret_cap_and_commit]).data .* dfH2Gen[ret_cap_and_commit,:Cap_Size_tonne_p_hr]
    end
    if !isempty(ret_cap_not_commit)
        retcapdischarge[ret_cap_not_commit] .= value.(EP[:vH2GenRetCap][ret_cap_not_commit]).data
    end

    capcharge = zeros(size(inputs["H2_RESOURCES_NAME"]))
    retcapcharge = zeros(size(inputs["H2_RESOURCES_NAME"]))
    stor_new_cap_charge = intersect(inputs["H2_STOR_ALL"], inputs["NEW_CAP_H2_STOR_CHARGE"])
    stor_ret_cap = intersect(inputs["H2_STOR_ALL"], inputs["RET_CAP_H2_STOR_CHARGE"])
    if !isempty(stor_new_cap_charge)
        capcharge[stor_new_cap_charge] .= value.(EP[:vH2CAPCHARGE][stor_new_cap_charge]).data
    end
    if !isempty(stor_ret_cap)
        retcapcharge[stor_ret_cap] .= value.(EP[:vH2RETCAPCHARGE][stor_ret_cap]).data
    end

    capenergy = zeros(size(inputs["H2_RESOURCES_NAME"]))
    retcapenergy = zeros(size(inputs["H2_RESOURCES_NAME"]))
    stor_new_cap_energy = intersect(inputs["H2_STOR_ALL"], inputs["NEW_CAP_H2_ENERGY"])
    stor_ret_cap_energy = intersect(inputs["H2_STOR_ALL"], inputs["RET_CAP_H2_ENERGY"])
    if !isempty(stor_new_cap_energy)
        capenergy[stor_new_cap_energy] = value.(EP[:vH2CAPENERGY][stor_new_cap_energy]).data
    end
    if !isempty(stor_ret_cap_energy)
        retcapenergy[stor_ret_cap_energy] = value.(EP[:vH2RETCAPENERGY][stor_ret_cap_energy]).data
    end

    dfCap = DataFrame(
        Resource = inputs["H2_RESOURCES_NAME"], Zone = dfH2Gen[!,:Zone],
        StartCap = dfH2Gen[!,:Existing_Cap_tonne_p_hr],
        RetCap = retcapdischarge[:],
        NewCap = capdischarge[:],
        EndCap = value.(EP[:eH2GenTotalCap]),
        StartEnergyCap = dfH2Gen[!,:Existing_Energy_Cap_tonne],
        RetEnergyCap = retcapenergy[:],
        NewEnergyCap = capenergy[:],
        EndEnergyCap = dfH2Gen[!,:Existing_Energy_Cap_tonne]+capenergy[:]-retcapenergy[:],
        StartChargeCap = dfH2Gen[!,:Existing_Charge_Cap_tonne_p_hr],
        RetChargeCap = retcapcharge[:],
        NewChargeCap = capcharge[:],
        EndChargeCap = dfH2Gen[!,:Existing_Charge_Cap_tonne_p_hr]+capcharge[:]-retcapcharge[:]
    )


    total = DataFrame(
        Resource = "Total", Zone = "n/a",
        StartCap = sum(dfCap[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]),
        NewCap = sum(dfCap[!,:NewCap]), EndCap = sum(dfCap[!,:EndCap]),
        StartEnergyCap = sum(dfCap[!,:StartEnergyCap]), RetEnergyCap = sum(dfCap[!,:RetEnergyCap]),
        NewEnergyCap = sum(dfCap[!,:NewEnergyCap]), EndEnergyCap = sum(dfCap[!,:EndEnergyCap]),
        StartChargeCap = sum(dfCap[!,:StartChargeCap]), RetChargeCap = sum(dfCap[!,:RetChargeCap]),
        NewChargeCap = sum(dfCap[!,:NewChargeCap]), EndChargeCap = sum(dfCap[!,:EndChargeCap])
    )

    dfCap = vcat(dfCap, total)
    CSV.write(joinpath(path, "HSC_generation_storage_capacity.csv"), dftranspose(dfCap, false), writeheader=false)
    return dfCap
end
