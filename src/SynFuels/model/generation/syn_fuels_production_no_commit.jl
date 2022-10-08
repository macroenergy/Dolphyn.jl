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

"""

function syn_fuels_production_no_commit(EP::Model, inputs::Dict, setup::Dict)

    # Rename SynGen dataframe
    dfSynGen = inputs["dfSynGen"]

    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones

    SYN_GEN_NO_COMMIT = inputs["SYN_GEN_NO_COMMIT"]

    ###Expressions###

    # Synthesis Fuel Balance Expression
    @expression(
        EP,
        eSynGenNoCommit[t = 1:T, z = 1:Z],
        sum(
            EP[:vSynGen][k, t] for
            k in intersect(SYN_GEN_NO_COMMIT, dfSynGen[dfSynGen[!, :Zone].==z, :][!, :R_ID])
        )
    )#intersect(SYN_GEN_NO_COMMIT, dfSynGen[dfSynGen[!,:Zone].==z,:][!,:R_ID])))

    EP[:eSynBalance] -= eSynGenNoCommit

    # Power Consumption for Syn Fuel Production
    if setup["ParameterScale"] == 1 # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW
        @expression(
            EP,
            ePowerBalanceSynGenNoCommit[t = 1:T, z = 1:Z],
            sum(
                EP[:vP2F][k, t] / ModelScalingFactor for k in
                intersect(SYN_GEN_NO_COMMIT, dfSynGen[dfSynGen[!, :Zone].==z, :][!, :R_ID])
            )
        )
    else # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling
        @expression(
            EP,
            ePowerBalanceSynGenNoCommit[t = 1:T, z = 1:Z],
            sum(
                EP[:vP2F][k, t] for k in
                intersect(SYN_GEN_NO_COMMIT, dfSynGen[dfSynGen[!, :Zone].==z, :][!, :R_ID])
            )
        )
    end

    EP[:ePowerBalance] += -ePowerBalanceSynGenNoCommit

    # H2 Balance expressions
    @expression(
        EP,
        eH2BalanceSynGenNoCommit[t = 1:T, z = 1:Z],
        sum(
            EP[:vH2F][k, t] for
            k in intersect(SYN_GEN_NO_COMMIT, dfSynGen[dfSynGen[!, :Zone].==z, :][!, :R_ID])
        )
    )

    EP[:eH2Balance] -= eH2BalanceSynGenNoCommit

    # CO2 Balance Expression
    @expression(
        EP,
        eCO2BalanceSynGenNoCommit[t = 1:T, z = 1:Z],
        sum(
            EP[:vC2F][k, t] for
            k in intersect(SYN_GEN_NO_COMMIT, dfSynGen[dfSynGen[!, :Zone].==z, :][!, :R_ID])
        )
    )

    EP[:eCO2Balance] += -eCO2BalanceSynGenNoCommit

    ###Constraints###
    # Power hydrogen and carbon consumption calculation
    @constraints(
        EP,
        begin
            [k in SYN_GEN_NO_COMMIT, t = 1:T],
            EP[:vP2F][k, t] == EP[:vSynGen][k, t] * dfSynGen[!, :etaP2F_MWh_p_tonne][k]
            [k in SYN_GEN_NO_COMMIT, t = 1:T],
            EP[:vH2F][k, t] == EP[:vSynGen][k, t] * dfSynGen[!, :etaH2F_tonne_p_tonne][k]
            [k in SYN_GEN_NO_COMMIT, t = 1:T],
            EP[:vC2F][k, t] == EP[:vSynGen][k, t] * dfSynGen[!, :etaC2F_tonne_p_tonne][k]
        end
    )

    @constraint(
        EP,
        [k in SYN_GEN_NO_COMMIT, t = 1:T],
        EP[:vSynGen][k, t] <= EP[:eSynGenTotalCap][k] * inputs["pSyn_Max"][k, t]
    )

    #Ramping cosntraints
    @constraints(
        EP,
        begin
            ## Maximum ramp up between consecutive hours
            # Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
            # NOTE: We should make wrap-around a configurable option
            [k in SYN_GEN_NO_COMMIT, t in START_SUBPERIODS],
            EP[:vSynGen][k, t] - EP[:vSynGen][k, (t+hours_per_subperiod-1)] <=
            dfSynGen[!, :Ramp_Up_Percentage][k] * EP[:eSynGenTotalCap][k]

            # Interior Hours
            [k in SYN_GEN_NO_COMMIIT, t in INTERIOR_SUBPERIODS],
            EP[:vSynGen][k, t] - EP[:vSynGen][k, t-1] <=
            dfH2Gen[!, :Ramp_Up_Percentage][k] * EP[:eSynGenTotalCap][k]

            ## Maximum ramp down between consecutive hours
            # Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
            [k in SYN_GEN_NO_COMMIIT, t in START_SUBPERIODS],
            EP[:vSynGen][k, (t+hours_per_subperiod-1)] - EP[:vSynGen][k, t] <=
            dfH2Gen[!, :Ramp_Down_Percentage][k] * EP[:eSynGenTotalCap][k]

            # Interior Hours
            [k in SYN_GEN_NO_COMMIIT, t in INTERIOR_SUBPERIODS],
            EP[:vSynGen][k, t-1] - EP[:vSynGen][k, t] <=
            dfH2Gen[!, :Ramp_Down_Percentage][k] * EP[:eSynGenTotalCap][k]

        end
    )

    return EP

end




