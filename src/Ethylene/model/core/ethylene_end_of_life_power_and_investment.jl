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

"""
function ethylene_end_of_life_power_and_investment(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Power Recovery and Investment Module for Ethylene end of life")



    ###########################################################  VERSION 1 #############################################################
## Step 1: load the saved information
# Greenfield projects:
    dfEthylene = inputs["dfEthylene"]
    Ethylene_RES_ALL = inputs["Ethylene_RES_ALL"]
    Fractional_combustion = dfEthylene[!,:Fractional_combustion]
    mwhRecovery_p_tonne_ethylene = dfEthylene[!,:mwhRecovery_p_tonne_ethylene]
    mwhRecovery_p_tonne_CoProduct = dfEthylene[!,:mwhRecovery_p_tonne_CoProduct]

    
# Existing plants:
    dfEthylene_plants = inputs["dfEthylene_plants"]
    Ethylene_Plants_ALL = inputs["Ethylene_Plants_ALL"]
    Plants_Fractional_combustion = dfEthylene_plants[!,:Plants_Fractional_combustion]
    Plants_mwhRecovery_p_tonne_ethylene = dfEthylene_plants[!,:Plants_mwhRecovery_p_tonne_ethylene]
    Plants_mwhRecovery_p_tonne_CoProduct = dfEthylene_plants[!,:Plants_mwhRecovery_p_tonne_CoProduct]


# Other quantities:
    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones

    @variable(EP, vEthylene_PowerRecoveryEthylene_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
    @variable(EP, vEthylene_PowerRecoveryCoProducts_GF[k = 1:Ethylene_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vEthylene_PowerRecoveryEthylene_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )
    @variable(EP, vEthylene_PowerRecoveryCoProducts_EP[k = 1:Ethylene_Plants_ALL, t = 1:T] >= 0 )


    @constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_PowerRecoveryEthylene_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * Fractional_combustion[k] * dfEthylene[!,:mwhRecovery_p_tonne_ethylene][k] end)
	@expression(EP, eEthylene_PowerRecoveryEthylene_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_PowerRecoveryEthylene_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:ePowerBalance] += eEthylene_PowerRecoveryEthylene_RES

    @constraints(EP, begin [k in 1:Ethylene_RES_ALL, t = 1:T], EP[:vEthylene_PowerRecoveryCoProducts_GF][k,t] == EP[:vEthylene_Prod_GF][k,t] * dfEthylene[!,:tonne_LPG_p_tonne_ethylene][k] * Fractional_combustion[k] * dfEthylene[!,:mwhRecovery_p_tonne_CoProduct][k] end)
	@expression(EP, eEthylene_PowerRecoveryCoProducts_RES[t=1:T, z=1:Z], sum(EP[:vEthylene_PowerRecoveryCoProducts_GF][k,t] for k in intersect(1:Ethylene_RES_ALL, dfEthylene[dfEthylene[!,:Zone].==z,:][!,:R_ID])))
	EP[:ePowerBalance] += eEthylene_PowerRecoveryCoProducts_RES


    if setup["ModelEthylenePlants"] == 1

		@constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_PowerRecoveryEthylene_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * Plants_Fractional_combustion[k] * dfEthylene_plants[!,:Plants_mwhRecovery_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_RecoveryEthylene_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_PowerRecoveryEthylene_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
		EP[:ePowerBalance] += eEthylene_RecoveryEthylene_Plant

        @constraints(EP, begin [k in 1:Ethylene_Plants_ALL, t = 1:T], EP[:vEthylene_PowerRecoveryCoProducts_EP][k,t] == EP[:vEthylene_Prod_EP][k,t] * dfEthylene_plants[!,:Plants_tonne_LPG_p_tonne_ethylene][k] * Plants_Fractional_combustion[k] * dfEthylene_plants[!,:Plants_mwhRecovery_p_tonne_CoProduct][k] end)
		@expression(EP, eEthylene_RecoveryCoProducts_Plant[t=1:T, z=1:Z], sum(EP[:vEthylene_PowerRecoveryCoProducts_EP][k,t] for k in intersect(1:Ethylene_Plants_ALL, dfEthylene_plants[dfEthylene_plants[!,:Plant_Zone].==z,:][!,:R_ID])))
		EP[:ePowerBalance] += eEthylene_RecoveryCoProducts_Plant

    end

    
    if setup["ModelEthyleneRetrofitting"] == 1  

        dfEthylene_retrofit = inputs["dfEthylene_retrofit"]
        Ethylene_retrofit_ALL = inputs["Ethylene_retrofit_ALL"]
        Retrofit_Fractional_combustion = dfEthylene_retrofit[!,:Retrofit_Fractional_combustion]
        Retrofit_mwhRecovery_p_tonne_ethylene = dfEthylene_retrofit[!,:Retrofit_mwhRecovery_p_tonne_ethylene]
        Retrofit_mwhRecovery_p_tonne_CoProduct = dfEthylene_retrofit[!,:Retrofit_mwhRecovery_p_tonne_CoProduct]

        @variable(EP, vEthylene_PowerRecoveryEthylene_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )
        @variable(EP, vEthylene_PowerRecoveryCoProducts_Retrofit[k = 1:Ethylene_retrofit_ALL, t = 1:T] >= 0 )

        
		@constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t = 1:T], EP[:vEthylene_PowerRecoveryEthylene_Retrofit][k,t] == EP[:eEthylene_Prod_RetrofitRES][k,t] * Retrofit_Fractional_combustion[k] * dfEthylene_retrofit[!,:Retrofit_mwhRecovery_p_tonne_ethylene][k] end)
		@expression(EP, eEthylene_RecoveryEthylene_Retrofit[t=1:T, z=1:Z], sum(EP[:vEthylene_PowerRecoveryEthylene_Retrofit][k,t] for k in intersect(1:Ethylene_retrofit_ALL, dfEthylene_retrofit[dfEthylene_retrofit[!,:Retrofit_Zone].==z,:][!,:R_ID])))
		EP[:ePowerBalance] += eEthylene_RecoveryEthylene_Retrofit

        @constraints(EP, begin [k in 1:Ethylene_retrofit_ALL, t = 1:T], EP[:vEthylene_PowerRecoveryCoProducts_Retrofit][k,t] == EP[:eEthylene_Prod_RetrofitRES][k,t] * dfEthylene_retrofit[!,:Retrofit_tonne_LPG_p_tonne_ethylene][k] * Retrofit_Fractional_combustion[k] * dfEthylene_retrofit[!,:Retrofit_mwhRecovery_p_tonne_CoProduct][k] end)
		@expression(EP, eEthylene_RecoveryCoProducts_Retrofit[t=1:T, z=1:Z], sum(EP[:vEthylene_PowerRecoveryCoProducts_Retrofit][k,t] for k in intersect(1:Ethylene_retrofit_ALL, dfEthylene_retrofit[dfEthylene_retrofit[!,:Retrofit_Zone].==z,:][!,:R_ID])))
		EP[:ePowerBalance] += eEthylene_RecoveryCoProducts_Retrofit
    end




    return EP
end
