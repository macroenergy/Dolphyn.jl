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
	syn_fuels_generation(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

The h2 generation module creates decision variables, expressions, and constraints related to hydrogen generation infrastructure
- Investment and FOM cost expression, VOM cost expression, minimum and maximum capacity limits
"""
function syn_fuels_production_all(EP::Model, inputs::Dict, setup::Dict)

    println("Synthesis Fuels Production Core Module")

    dfSynGen = inputs["dfSynGen"]

    #Define sets
    SYN_GEN_NO_COMMIT = inputs["SYN_GEN_NO_COMMIT"]
    SYN_GEN_COMMIT = inputs["SYN_GEN_COMMIT"]
    SYN_GEN = inputs["SYN_GEN"]
    SYN_GEN_RET_CAP = inputs["SYN_GEN_RET_CAP"]
    H = inputs["SYN_RES_ALL"]

    T = inputs["T"]     # Number of time steps (hours)

    ####Variables####
    #Define variables needed across both commit and no commit sets

    #Power required by Synthesis fuels generation resource k to make Synthesis fuels (MW)
    @variable(EP, vP2F[k in SYN_GEN, t = 1:T] >= 0)

    #Hydrogen required by Synthesis fuels generation resource k to make Synthesis fuels (Tonne-H2)
    @variable(EP, vH2F[k in SYN_GEN, t in 1:T] >= 0)

    #Carbon required by Synthesis fuels generation resource k to make Synthesis fuels (Tonne-CO2)
    @variable(EP, vC2F[k in SYN_GEN, t in 1:T] >= 0)

    ### Constratints ###

    ## Constraints on retirements and capacity additions
    # Cannot retire more capacity than existing capacity
    @constraint(
        EP,
        cSynGenMaxRetNoCommit[k in setdiff(SYN_GEN_RET_CAP, SYN_GEN_NO_COMMIT)],
        EP[:vSynGenRetCap][k] <= dfSynGen[!, :Existing_Cap_tonne_p_hr][k]
    )
    @constraint(
        EP,
        cSynGenMaxRetCommit[k in intersect(SYN_GEN_RET_CAP, SYN_GEN_COMMIT)],
        dfSynGen[!, :Cap_Size_tonne_p_hr][k] * EP[:vSynGenRetCap][k] <=
        dfSynGen[!, :Existing_Cap_tonne_p_hr][k]
    )

    ## Constraints on new built capacity
    # Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
    @constraint(
        EP,
        cSynGenMaxCap[k in intersect(dfSynGen[dfSynGen.Max_Cap_tonne_p_hr.>0, :R_ID], 1:H)],
        EP[:eSynGenTotalCap][k] <= dfSynGen[!, :Max_Cap_tonne_p_hr][k]
    )

    # Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is <= Min_Cap_MW and lead to infeasabilty
    @constraint(
        EP,
        cSynGenMinCap[k in intersect(dfSynGen[dfSynGen.Min_Cap_tonne_p_hr.>0, :R_ID], 1:H)],
        EP[:eSynGenTotalCap][k] >= dfSynGen[!, :Min_Cap_tonne_p_hr][k]
    )

    return EP

end
